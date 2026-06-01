import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/itinerary.dart';
import '../../services/itinerary_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/places_view_model.dart';
import '../../viewmodels/theme_controller.dart';
import '../../widgets/primary_button.dart';
import '../map/map_shared.dart';
import '../map/map_style.dart';
import '../places/place_card_widget.dart';

/// Resultat "Adresse parfaite" : carte du trajet + etapes.
class PerfectResultScreen extends StatefulWidget {
  const PerfectResultScreen({super.key, required this.request});
  final ItineraryRequest request;

  @override
  State<PerfectResultScreen> createState() => _PerfectResultScreenState();
}

class _PerfectResultScreenState extends State<PerfectResultScreen> {
  final ItineraryService _service = ItineraryService();
  late final Itinerary _itinerary;

  @override
  void initState() {
    super.initState();
    final places = context.read<PlacesViewModel>().allPlaces;
    _itinerary = _service.build(widget.request, places);
  }

  String _fmt(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final it = _itinerary;
    final retina = RetinaMode.isHighDensity(context);
    final mapDark = context.watch<ThemeController>().mapIsDark;

    final routePoints = <LatLng>[
      LatLng(it.startLat, it.startLng),
      for (final s in it.stops) LatLng(s.place.latitude, s.place.longitude),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Itineraire ${it.moment.label.toLowerCase()}')),
      body: it.stops.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Pas assez de lieux pour composer un itineraire. '
                  'Augmentez le budget.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---- Carte du trajet ----
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 240,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: routePoints.first,
                        initialZoom: 13,
                        initialCameraFit: CameraFit.coordinates(
                          coordinates: routePoints,
                          padding: const EdgeInsets.all(40),
                          maxZoom: 15.5,
                        ),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        ...mapBaseLayers(MapStyle.plan,
                            retina: retina, dark: mapDark),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: 4,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: routePoints.first,
                              width: 34,
                              height: 34,
                              child: const _StartMarker(),
                            ),
                            for (var i = 0; i < it.stops.length; i++)
                              Marker(
                                point: LatLng(it.stops[i].place.latitude,
                                    it.stops[i].place.longitude),
                                width: 32,
                                height: 32,
                                child: _NumberMarker(i + 1),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.place, size: 18, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Depart : ${it.startLabel}',
                          style: AppTypography.caption),
                    ),
                    Text('Total ${_fmt(it.totalDistance)} a pied',
                        style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: 12),

                PrimaryButton(
                  label: 'Lancer l\'itineraire (Google Maps)',
                  icon: Icons.directions_walk,
                  onPressed: () => launchExternal(_service.routeUrl(it)),
                ),
                const SizedBox(height: 16),

                // ---- Etapes ----
                for (var i = 0; i < it.stops.length; i++)
                  _StopTile(
                    index: i + 1,
                    stop: it.stops[i],
                    distanceLabel: _fmt(it.stops[i].distanceFromPrev),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Modifier mes choix'),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.index,
    required this.stop,
    required this.distanceLabel,
  });
  final int index;
  final ItineraryStop stop;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4, bottom: 2),
          child: Row(
            children: [
              _NumberMarker(index),
              const SizedBox(width: 8),
              Text(stop.role, style: AppTypography.subtitle),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.directions_walk,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 2),
                  Text(distanceLabel, style: AppTypography.caption),
                ],
              ),
            ],
          ),
        ),
        PlaceCardWidget(
          place: stop.place,
          onTap: () => showPlaceQuickSheet(context, stop.place),
        ),
      ],
    );
  }
}

class _NumberMarker extends StatelessWidget {
  const _NumberMarker(this.number);
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
      ),
      child: Text('$number',
          style: AppTypography.tag.copyWith(color: Colors.white)),
    );
  }
}

class _StartMarker extends StatelessWidget {
  const _StartMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
      ),
      child: const Icon(Icons.home, color: Colors.white, size: 18),
    );
  }
}
