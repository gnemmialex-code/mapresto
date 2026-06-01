import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Styles de fond de carte disponibles.
enum MapStyle {
  plan('Plan HD', Icons.map_outlined),
  satellite('Satellite', Icons.satellite_alt),
  hybride('Hybride', Icons.layers_outlined);

  const MapStyle(this.label, this.icon);
  final String label;
  final IconData icon;
}

const String _ua = 'com.parismap.parismap_video_guide';

/// Attribution a afficher selon le style (obligatoire).
String mapAttribution(MapStyle style) => switch (style) {
      MapStyle.plan => '© OpenStreetMap, © CARTO',
      MapStyle.satellite => 'Imagery © Esri',
      MapStyle.hybride => 'Imagery © Esri, © OpenStreetMap',
    };

/// Construit les couches de tuiles (fond) pour un style donne.
///
/// - Plan HD : CartoDB Voyager (clair) ou Dark Matter (sombre la nuit), retina.
/// - Satellite : imagerie aerienne Esri World Imagery (gratuite, sans cle).
/// - Hybride : satellite + couche de labels/rues Esri par-dessus.
///
/// [dark] : utilise le fond de carte sombre (uniquement pour le style Plan).
List<Widget> mapBaseLayers(MapStyle style,
    {required bool retina, bool dark = false}) {
  switch (style) {
    case MapStyle.plan:
      return [
        TileLayer(
          urlTemplate: dark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: retina,
          userAgentPackageName: _ua,
          maxNativeZoom: 20,
        ),
      ];
    case MapStyle.satellite:
      return [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: _ua,
          maxNativeZoom: 19,
        ),
      ];
    case MapStyle.hybride:
      return [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: _ua,
          maxNativeZoom: 19,
        ),
        // Labels de rues / lieux (PNG transparents) par-dessus le satellite.
        // Labels de rues / lieux (PNG transparents) par-dessus le satellite.
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: _ua,
          maxNativeZoom: 19,
        ),
      ];
  }
}
