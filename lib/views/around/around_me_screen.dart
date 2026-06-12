import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/places_view_model.dart';
import '../../viewmodels/theme_controller.dart';
import '../map/map_shared.dart';
import '../map/map_style.dart';
import '../map/place_marker_widget.dart';
import '../places/place_card_widget.dart';

/// "Autour de moi" : etablissements dans un rayon (100 m -> 15 km).
class AroundMeScreen extends StatefulWidget {
  const AroundMeScreen({super.key});

  @override
  State<AroundMeScreen> createState() => _AroundMeScreenState();
}

class _AroundMeScreenState extends State<AroundMeScreen> {
  final LocationService _locationService = LocationService();
  final MapController _map = MapController();

  UserLocation? _user;
  bool _loading = true;
  double _radiusKm = 2;
  PlaceType? _type;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loc = await _locationService.current();
    if (!mounted) return;
    setState(() {
      _user = loc;
      _loading = false;
    });
    // Recentre la carte sur la nouvelle position.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToRadius());
  }

  /// Relance la detection de position (apres refus, GPS lent, etc.).
  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _load();
  }

  /// Action proposee selon la raison du repli.
  Future<void> _enableLocation() async {
    final status = _user?.status;
    if (status == LocationStatus.serviceDisabled) {
      await _locationService.openLocationSettings();
    } else if (status == LocationStatus.deniedForever) {
      await _locationService.openAppSettings();
    }
    // Dans tous les cas on retente (re-demande la permission si refusee).
    await _refresh();
  }

  String _fallbackMessage(LocationStatus status) => switch (status) {
        LocationStatus.serviceDisabled =>
          'GPS desactive — activez la localisation',
        LocationStatus.deniedForever =>
          'Position refusee — autorisez-la dans les reglages',
        LocationStatus.denied => 'Position refusee — autorisez l\'acces',
        LocationStatus.timeout => 'GPS introuvable — reessayez',
        _ => 'Position indisponible — reessayez',
      };

  double get _radiusMeters => _radiusKm * 1000;

  /// Lieux dans le rayon, tries par distance.
  List<MapEntry<Place, double>> _nearby(List<Place> places) {
    final user = _user!;
    final list = <MapEntry<Place, double>>[];
    for (final p in places) {
      if (_type != null && p.type != _type) continue;
      final d = _locationService.distanceMeters(
          user.latitude, user.longitude, p.latitude, p.longitude);
      if (d <= _radiusMeters) list.add(MapEntry(p, d));
    }
    list.sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  void _fitToRadius() {
    final user = _user;
    if (user == null) return;
    final dLat = _radiusKm / 111.0;
    final dLng = _radiusKm / (111.0 * math.cos(user.latitude * math.pi / 180));
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(user.latitude - dLat, user.longitude - dLng),
          LatLng(user.latitude + dLat, user.longitude + dLng),
        ),
        padding: const EdgeInsets.all(30),
      ),
    );
  }

  void _setRadius(double km) {
    setState(() => _radiusKm = km);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToRadius());
  }

  String _fmt(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: _Bar(onRefresh: null),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user!;
    final nearby = _nearby(context.watch<PlacesViewModel>().allPlaces);
    final retina = RetinaMode.isHighDensity(context);
    final mapDark = context.watch<ThemeController>().mapIsDark;

    return Scaffold(
      appBar: _Bar(onRefresh: _refresh),
      body: Column(
        children: [
          // ---- Carte ----
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: LatLng(user.latitude, user.longitude),
                    initialZoom: 14,
                    onMapReady: _fitToRadius,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    ...mapBaseLayers(MapStyle.plan,
                        retina: retina, dark: mapDark),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(user.latitude, user.longitude),
                          radius: _radiusMeters,
                          useRadiusInMeter: true,
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        for (final e in nearby)
                          Marker(
                            point: LatLng(e.key.latitude, e.key.longitude),
                            width: 40,
                            height: 46,
                            child: PlaceMarkerWidget(
                              place: e.key,
                              onTap: () => showPlaceQuickSheet(context, e.key),
                            ),
                          ),
                        // Position de l'utilisateur.
                        Marker(
                          point: LatLng(user.latitude, user.longitude),
                          width: 24,
                          height: 24,
                          child: const _UserDot(),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!user.isReal)
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fallbackMessage(user.status),
                              style: AppTypography.tag
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _enableLocation,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Activer ma position',
                                style: AppTypography.tag
                                    .copyWith(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ---- Controles : type + rayon ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _typeChip('Tous', null),
                    for (final t in PlaceType.values) _typeChip(t.label, t),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.social_distance,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Rayon : ${_radiusKm < 1 ? '${(_radiusKm * 1000).round()} m' : '${_radiusKm.toStringAsFixed(1)} km'}',
                        style: AppTypography.subtitle),
                  ],
                ),
                Slider(
                  value: _radiusKm,
                  min: 0.1,
                  max: 15,
                  onChanged: _setRadius,
                ),
              ],
            ),
          ),

          // ---- Liste ----
          Expanded(
            child: nearby.isEmpty
                ? Center(
                    child: Text(
                      'Aucun lieu dans ${_radiusKm < 1 ? '${(_radiusKm * 1000).round()} m' : '${_radiusKm.toStringAsFixed(1)} km'}.',
                      style: AppTypography.body,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: nearby.length,
                    itemBuilder: (context, i) {
                      final e = nearby[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.near_me,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text('a ${_fmt(e.value)}',
                                    style: AppTypography.caption
                                        .copyWith(color: AppColors.primary)),
                              ],
                            ),
                          ),
                          PlaceCardWidget(
                            place: e.key,
                            onTap: () => showPlaceQuickSheet(context, e.key),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, PlaceType? value) {
    final selected = _type == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      showCheckmark: false,
      labelStyle: AppTypography.tag.copyWith(
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      onSelected: (_) => setState(() => _type = value),
    );
  }
}

class _Bar extends StatelessWidget implements PreferredSizeWidget {
  const _Bar({required this.onRefresh});
  final VoidCallback? onRefresh;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
        title: const Text('Autour de moi'),
        actions: [
          IconButton(
            tooltip: 'Actualiser ma position',
            icon: const Icon(Icons.my_location),
            onPressed: onRefresh,
          ),
        ],
      );
}

class _UserDot extends StatelessWidget {
  const _UserDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
    );
  }
}
