import 'package:geolocator/geolocator.dart';

/// Raison pour laquelle la position reelle n'a pas pu etre obtenue.
enum LocationStatus {
  ok,              // position reelle obtenue
  serviceDisabled, // GPS / service de localisation desactive sur l'appareil
  denied,          // permission refusee (re-demandable)
  deniedForever,   // permission refusee definitivement (passer par les reglages)
  timeout,         // GPS trop lent et aucun dernier point connu
  error,           // erreur inattendue (plugin, plateforme...)
}

/// Position de l'utilisateur (reelle ou repli).
class UserLocation {
  final double latitude;
  final double longitude;
  final bool isReal; // false = repli (geoloc refusee / indisponible)
  final LocationStatus status;

  const UserLocation(
    this.latitude,
    this.longitude, {
    this.isReal = true,
    this.status = LocationStatus.ok,
  });
}

/// Recupere la position de l'utilisateur (web + mobile).
/// En cas de refus / indisponibilite : repli sur le centre de Paris (avec le
/// [LocationStatus] expliquant pourquoi) pour que l'UI puisse proposer a
/// l'utilisateur d'activer sa position.
class LocationService {
  static UserLocation _parisFallback(LocationStatus status) =>
      UserLocation(48.8566, 2.3522, isReal: false, status: status);

  Future<UserLocation> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _parisFallback(LocationStatus.serviceDisabled);
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        return _parisFallback(LocationStatus.deniedForever);
      }
      if (perm == LocationPermission.denied) {
        return _parisFallback(LocationStatus.denied);
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
        return UserLocation(pos.latitude, pos.longitude);
      } catch (_) {
        // GPS trop lent : on tente le dernier point connu (non supporte sur
        // web, d'ou le try/catch dedie).
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) return UserLocation(last.latitude, last.longitude);
        } catch (_) {}
        return _parisFallback(LocationStatus.timeout);
      }
    } catch (_) {
      return _parisFallback(LocationStatus.error);
    }
  }

  /// Ouvre les reglages de localisation de l'appareil (GPS desactive).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Ouvre les reglages de l'application (permission refusee definitivement).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Distance en metres entre deux points.
  double distanceMeters(
          double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}
