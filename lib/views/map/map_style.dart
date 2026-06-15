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
String mapAttribution(MapStyle style, {bool dark = false}) => switch (style) {
      MapStyle.plan =>
        dark ? '© Esri, © OpenStreetMap' : '© OpenStreetMap, © CARTO',
      MapStyle.satellite => 'Imagery © Esri',
      MapStyle.hybride => 'Imagery © Esri, © OpenStreetMap',
    };

/// Construit les couches de tuiles (fond) pour un style donne.
///
/// - Plan HD clair : CartoDB Voyager, retina.
/// - Plan HD sombre : Esri World Dark Gray Canvas (Base + Reference).
///   Deux couches separees : la base montre la hierarchie des rues avec un
///   fort contraste (grands axes bien visibles, ruelles quasi invisibles) ;
///   la reference ajoute les labels/noms de rues et arrondissements par-dessus.
/// - Satellite : imagerie aerienne Esri World Imagery (gratuite, sans cle).
/// - Hybride : satellite + couche de labels/rues Esri par-dessus.
///
/// [dark] : utilise le fond de carte sombre (uniquement pour le style Plan).
List<Widget> mapBaseLayers(MapStyle style,
    {required bool retina, bool dark = false}) {
  switch (style) {
    case MapStyle.plan:
      if (dark) {
        return [
          // Fond sombre avec hierarchie de rues : grands axes clairs, ruelles sombres.
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: _ua,
            maxNativeZoom: 17,
          ),
          // Labels transparents par-dessus : noms de rues, arrondissements, POI.
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: _ua,
            maxNativeZoom: 17,
          ),
        ];
      }
      return [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: retina,
          userAgentPackageName: _ua,
          maxNativeZoom: 20,
        ),
      ];
    case MapStyle.satellite:
      return [
        // maxNativeZoom: 17 → flutter_map zoome la tuile z17 au lieu de charger
        // des tuiles Esri inexistantes qui affichent "Map data not yet available".
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: _ua,
          maxNativeZoom: 17,
        ),
      ];
    case MapStyle.hybride:
      return [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: _ua,
          maxNativeZoom: 17,
        ),
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
