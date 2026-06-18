import 'dart:async';

import 'package:flutter/foundation.dart';

/// Mode de theme choisi par l'utilisateur.
enum AppThemeMode { auto, light, dark }

extension AppThemeModeX on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.auto:
        return 'Auto (selon l\'heure)';
      case AppThemeMode.light:
        return 'Clair';
      case AppThemeMode.dark:
        return 'Sombre';
    }
  }
}

/// Gere le theme clair/sombre.
/// - Auto : sombre entre 20h et 6h, clair sinon (re-evalue chaque minute).
/// - Clair / Sombre : force, quelle que soit l'heure.
class ThemeController extends ChangeNotifier {
  ThemeController() {
    // Re-evalue periodiquement pour basculer a 20h / 6h si l'app reste ouverte.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_mode == AppThemeMode.auto) {
        final dark = _autoIsDark();
        if (dark != _lastAutoDark) {
          _lastAutoDark = dark;
          notifyListeners();
        }
      }
    });
  }

  AppThemeMode _mode = AppThemeMode.light;
  bool _lastAutoDark = _autoIsDark();
  Timer? _timer;

  // La carte suit-elle le mode sombre (true) ou reste-t-elle claire (false) ?
  bool _mapFollowsDark = true;

  AppThemeMode get mode => _mode;

  void setMode(AppThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _lastAutoDark = _autoIsDark();
    notifyListeners();
  }

  bool get mapFollowsDark => _mapFollowsDark;
  void setMapFollowsDark(bool value) {
    if (_mapFollowsDark == value) return;
    _mapFollowsDark = value;
    notifyListeners();
  }

  /// La carte doit-elle s'afficher en sombre ?
  bool get mapIsDark => isDark && _mapFollowsDark;

  /// Le theme effectif est-il sombre ?
  bool get isDark {
    switch (_mode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.auto:
        return _autoIsDark();
    }
  }

  /// Nuit = de 20h (inclus) a 6h (exclus).
  static bool _autoIsDark() {
    final h = DateTime.now().hour;
    return h >= 20 || h < 6;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
