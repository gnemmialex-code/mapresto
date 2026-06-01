import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import '../../config/app_config.dart';
import 'map_screen.dart';
// Import conditionnel : sur Web on prend le stub (pas de google_maps_flutter),
// sur mobile (dart:io disponible) on prend la vraie carte native.
import 'native_map_stub.dart'
    if (dart.library.io) 'native_map_io.dart' as native;

/// Choisit le bon moteur de carte selon la plateforme et la config :
/// - Mobile + AppConfig.useNativeGoogleMaps => Google Maps natif (vraie 3D).
/// - Sinon (Web, ou flag desactive) => flutter_map (Plan HD / Satellite).
class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && AppConfig.useNativeGoogleMaps) {
      return native.nativeMapScreen();
    }
    return const MapScreen();
  }
}
