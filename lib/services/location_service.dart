import 'package:geolocator/geolocator.dart';

/// Position de l'utilisateur (reelle ou repli).
class UserLocation {
  final double latitude;
  final double longitude;
  final bool isReal; // false = repli (geoloc refusee / indisponible)

  const UserLocation(this.latitude, this.longitude, {this.isReal = true});
}

/// Recupere la position de l'utilisateur (web + mobile).
/// En cas de refus / indisponibilite : repli sur le centre de Paris pour que
/// la fonctionnalite reste utilisable en demo.
class LocationService {
  static const UserLocation _parisFallback =
      UserLocation(48.8566, 2.3522, isReal: false);

  Future<UserLocation> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return _parisFallback;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return _parisFallback;
      }
      final pos = await Geolocator.getCurrentPosition();
      return UserLocation(pos.latitude, pos.longitude);
    } catch (_) {
      return _parisFallback;
    }
  }

  /// Distance en metres entre deux points.
  double distanceMeters(
          double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}
