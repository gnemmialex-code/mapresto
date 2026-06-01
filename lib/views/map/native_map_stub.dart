import 'package:flutter/material.dart';

/// Implementation utilisee quand la carte native n'est pas disponible
/// (ex: Web). Ne reference jamais google_maps_flutter.
Widget nativeMapScreen() => const Center(
      child: Text('Carte native Google Maps indisponible sur cette plateforme.'),
    );
