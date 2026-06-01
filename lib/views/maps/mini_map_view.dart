import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';
import '../../theme/place_visuals.dart';
import '../../viewmodels/theme_controller.dart';

/// Mini-carte reutilisable affichant un ensemble de lieux, cadree
/// automatiquement. Utilisee dans les plans prives et la carte perso.
class MiniMapView extends StatelessWidget {
  const MiniMapView({
    super.key,
    required this.places,
    this.color,
    this.height = 220,
  });

  final List<Place> places;
  final Color? color; // teinte des markers (style de la collection)
  final double height;

  @override
  Widget build(BuildContext context) {
    final points = [
      for (final p in places) LatLng(p.latitude, p.longitude),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(48.8566, 2.3522),
                initialZoom: 12,
                initialCameraFit: points.isEmpty
                    ? null
                    : CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(36),
                        maxZoom: 15,
                      ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                // Tuiles HD CartoDB (Voyager clair / Dark Matter sombre).
                TileLayer(
                  urlTemplate: context.watch<ThemeController>().mapIsDark
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                      : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  retinaMode: RetinaMode.isHighDensity(context),
                  userAgentPackageName: 'com.parismap.parismap_video_guide',
                  maxNativeZoom: 20,
                ),
                MarkerLayer(
                  markers: [
                    for (final p in places)
                      Marker(
                        point: LatLng(p.latitude, p.longitude),
                        width: 30,
                        height: 30,
                        child: _Dot(
                          color: color ?? PlaceVisuals.color(p.type),
                          icon: PlaceVisuals.icon(p.type),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Positioned(
              bottom: 2,
              right: 4,
              child: Text('© OpenStreetMap',
                  style: TextStyle(fontSize: 8, color: Colors.black54)),
            ),
            if (places.isEmpty)
              Center(
                child: Text('Aucun lieu sur la carte',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
      ),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}
