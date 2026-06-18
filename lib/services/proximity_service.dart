import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';
import 'notification_service.dart';

/// Alertes de proximite : quand l'utilisateur (dans Paris) passe pres d'un
/// lieu qu'il a enregistre, on lui envoie une notification qui ouvre la fiche.
///
/// Fonctionnement :
/// - desactive par defaut ; l'utilisateur l'active dans les reglages
///   (necessite l'autorisation de localisation "en continu") ;
/// - quand actif, on ecoute le flux de position (geolocator) et, a chaque
///   point dans Paris, on cherche le lieu enregistre le plus proche ;
/// - si un lieu est a moins de [_radiusMeters], on notifie — au plus une fois
///   par lieu toutes les [_cooldown] (anti-spam).
///
/// NB : une vraie alerte "appli fermee" (geofencing en tache de fond)
/// demande une configuration native dediee par plateforme. Ici l'ecoute
/// fonctionne tant que l'app tourne (premier plan / recente), ce qui couvre
/// l'usage principal "je me balade dans Paris avec l'app ouverte".
class ProximityService extends ChangeNotifier {
  ProximityService({NotificationService? notifications})
      : _notifications = notifications ?? NotificationService.instance;

  final NotificationService _notifications;

  static const String _prefsKey = 'proximity_alerts_enabled';

  /// Rayon de declenchement (metres).
  static const double _radiusMeters = 180;

  /// Delai minimal avant de re-notifier le meme lieu.
  static const Duration _cooldown = Duration(hours: 3);

  /// Bounding box approximative de Paris intra-muros (+ proche couronne).
  static const double _parisMinLat = 48.78;
  static const double _parisMaxLat = 48.92;
  static const double _parisMinLng = 2.22;
  static const double _parisMaxLng = 2.48;

  bool _enabled = false;
  bool get enabled => _enabled;

  bool _busy = false;
  bool get busy => _busy;

  /// Source des lieux enregistres (carte perso). Branchee par l'app.
  List<Place> Function()? _savedPlacesSource;

  StreamSubscription<Position>? _sub;
  final Map<String, DateTime> _lastNotified = {};

  void attachSavedPlacesSource(List<Place> Function() source) {
    _savedPlacesSource = source;
  }

  /// Restaure l'etat sauvegarde au demarrage (et redemarre l'ecoute si actif).
  Future<void> restore() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();
    if (_enabled) await _startListening();
  }

  /// Active/desactive les alertes. Renvoie l'etat effectif (false si la
  /// permission a ete refusee).
  Future<bool> setEnabled(bool value) async {
    if (kIsWeb) return false;
    _busy = true;
    notifyListeners();
    try {
      if (value) {
        final ok = await _ensurePermissions();
        if (!ok) {
          _enabled = false;
          return false;
        }
        _enabled = true;
        await _startListening();
      } else {
        _enabled = false;
        await _stopListening();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _enabled);
      return _enabled;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Demande les autorisations localisation + notifications.
  Future<bool> _ensurePermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }
    // On tente la localisation "en continu" (always) pour couvrir l'arriere-plan
    // quand la plateforme le permet ; whileInUse reste suffisant sinon.
    final notifGranted = await _notifications.requestPermission();
    return notifGranted || perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  Future<void> _startListening() async {
    await _stopListening();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 40, // ne reagit qu'apres ~40 m de deplacement
      ),
    ).listen(_onPosition, onError: (_) {});
  }

  Future<void> _stopListening() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onPosition(Position pos) {
    if (!_enabled) return;
    if (!_isInParis(pos.latitude, pos.longitude)) return;
    final saved = _savedPlacesSource?.call() ?? const [];
    if (saved.isEmpty) return;

    Place? nearest;
    double nearestDist = double.infinity;
    for (final p in saved) {
      final d = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, p.latitude, p.longitude);
      if (d < nearestDist) {
        nearestDist = d;
        nearest = p;
      }
    }

    if (nearest == null || nearestDist > _radiusMeters) return;

    // Anti-spam : un meme lieu n'alerte qu'une fois par cooldown.
    final last = _lastNotified[nearest.id];
    final now = DateTime.now();
    if (last != null && now.difference(last) < _cooldown) return;
    _lastNotified[nearest.id] = now;

    final meters = nearestDist.round();
    _notifications.showProximityAlert(
      placeId: nearest.id,
      title: '${nearest.name} est à $meters m 👀',
      body: 'Un de vos lieux enregistrés est juste à côté. Toucher pour voir.',
    );
  }

  bool _isInParis(double lat, double lng) =>
      lat >= _parisMinLat &&
      lat <= _parisMaxLat &&
      lng >= _parisMinLng &&
      lng <= _parisMaxLng;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
