import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/map_view_model.dart';
import '../../viewmodels/places_view_model.dart';
import '../../viewmodels/theme_controller.dart';
import '../../widgets/filter_bar.dart';
import '../around/around_me_screen.dart';
import '../suggest/suggest_place_screen.dart';
import 'map_shared.dart';
import 'map_style.dart';
import 'place_marker_widget.dart';

/// Carte web/fallback basee sur flutter_map (Plan HD / Satellite / Hybride).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  MapStyle _style = MapStyle.plan;

  @override
  Widget build(BuildContext context) {
    final placesVm = context.watch<PlacesViewModel>();
    final visible = placesVm.visiblePlaces;
    final locked = placesVm.lockedPlaces;
    final retina = RetinaMode.isHighDensity(context);
    final mapDark = context.watch<ThemeController>().mapIsDark;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: MapViewModel.parisCenter,
              initialZoom: MapViewModel.defaultZoom,
              minZoom: 4,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              ...mapBaseLayers(_style, retina: retina, dark: mapDark),
              MarkerLayer(
                markers: [
                  for (final p in locked)
                    Marker(
                      point: LatLng(p.latitude, p.longitude),
                      width: 40,
                      height: 46,
                      child: PlaceMarkerWidget(
                        place: p,
                        locked: true,
                        onTap: () => _showPremiumSnack(),
                      ),
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final p in visible)
                    Marker(
                      point: LatLng(p.latitude, p.longitude),
                      width: 44,
                      height: 50,
                      child: PlaceMarkerWidget(
                        place: p,
                        onTap: () {
                          context.read<MapViewModel>().selectPlace(p);
                          showPlaceQuickSheet(context, p);
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: const FilterBar(),
          ),

          Positioned(
            right: 12,
            bottom: placesVm.hasLockedPlaces ? 92 : 28,
            child: Column(
              children: [
                MapControlButton(
                  icon: _style.icon,
                  tooltip: 'Style de carte',
                  onTap: _openStylePicker,
                ),
                const SizedBox(height: 10),
                MapControlButton(
                  icon: Icons.threed_rotation,
                  tooltip: 'Vue 3D',
                  onTap: _open3D,
                ),
                const SizedBox(height: 10),
                MapControlButton(
                  icon: Icons.my_location,
                  tooltip: 'Autour de moi',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AroundMeScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                MapControlButton(
                  icon: Icons.add_location_alt,
                  tooltip: 'Suggerer un lieu manquant',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SuggestPlaceScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (placesVm.hasLockedPlaces)
            Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: LockedBanner(count: locked.length),
            ),

          Positioned(
            bottom: 2,
            left: 6,
            child: Text(
              mapAttribution(_style, dark: mapDark),
              style: const TextStyle(fontSize: 9, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _openStylePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Style de carte', style: AppTypography.subtitle),
            const SizedBox(height: 8),
            for (final s in MapStyle.values)
              ListTile(
                leading: Icon(s.icon,
                    color: _style == s
                        ? AppColors.primary
                        : AppColors.textSecondary),
                title: Text(s.label),
                trailing: _style == s
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _style = s);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Ouvre la zone visible en vue 3D inclinee dans Google Maps.
  void _open3D() {
    final c = _mapController.camera.center;
    final url = 'https://www.google.com/maps/@${c.latitude},${c.longitude},'
        '250a,35y,45h,60t/data=!3m1!1e3';
    launchExternal(url);
  }

  void _showPremiumSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ce lieu est reserve aux membres Premium.')),
    );
  }
}
