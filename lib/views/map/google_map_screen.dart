import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/map_view_model.dart';
import '../../viewmodels/places_view_model.dart';
import '../../widgets/filter_bar.dart';
import 'map_shared.dart';

/// Carte NATIVE Google Maps (Android/iOS) : satellite + vraie 3D (tilt +
/// batiments). Utilisee uniquement si AppConfig.useNativeGoogleMaps == true.
class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({super.key});

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  static const LatLng _paris = LatLng(48.8566, 2.3522);

  GoogleMapController? _controller;
  MapType _mapType = MapType.normal;
  bool _is3D = false;

  // Derniere position camera (pour basculer en 3D au bon endroit).
  LatLng _target = _paris;
  double _zoom = MapViewModel.defaultZoom;

  // Hue du marker selon le type de lieu.
  double _hue(PlaceType type) {
    switch (type) {
      case PlaceType.bar:
        return BitmapDescriptor.hueViolet;
      case PlaceType.restaurant:
        return BitmapDescriptor.hueOrange;
      case PlaceType.hotel:
        return BitmapDescriptor.hueAzure;
    }
  }

  Set<Marker> _buildMarkers(List<Place> visible, List<Place> locked) {
    return {
      for (final p in locked)
        Marker(
          markerId: MarkerId('lock-${p.id}'),
          position: LatLng(p.latitude, p.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          onTap: _showPremiumSnack,
        ),
      for (final p in visible)
        Marker(
          markerId: MarkerId(p.id),
          position: LatLng(p.latitude, p.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_hue(p.type)),
          onTap: () {
            context.read<MapViewModel>().selectPlace(p);
            showPlaceQuickSheet(context, p);
          },
        ),
    };
  }

  void _toggle3D() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _is3D = !_is3D);
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _target,
          // On zoome pour que les batiments 3D apparaissent.
          zoom: _is3D ? math.max(_zoom, 17) : _zoom,
          tilt: _is3D ? 65 : 0,
          bearing: _is3D ? 30 : 0,
        ),
      ),
    );
  }

  void _showPremiumSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ce lieu est reserve aux membres Premium.')),
    );
  }

  void _openTypePicker() {
    const options = {
      MapType.normal: ('Plan', Icons.map_outlined),
      MapType.satellite: ('Satellite', Icons.satellite_alt),
      MapType.hybrid: ('Hybride', Icons.layers_outlined),
      MapType.terrain: ('Relief', Icons.terrain),
    };
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
            for (final entry in options.entries)
              ListTile(
                leading: Icon(entry.value.$2,
                    color: _mapType == entry.key
                        ? AppColors.primary
                        : AppColors.textSecondary),
                title: Text(entry.value.$1),
                trailing: _mapType == entry.key
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _mapType = entry.key);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placesVm = context.watch<PlacesViewModel>();
    final visible = placesVm.visiblePlaces;
    final locked = placesVm.lockedPlaces;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _paris,
              zoom: MapViewModel.defaultZoom,
            ),
            mapType: _mapType,
            markers: _buildMarkers(visible, locked),
            buildingsEnabled: true, // batiments 3D
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onMapCreated: (c) => _controller = c,
            onCameraMove: (pos) {
              _target = pos.target;
              _zoom = pos.zoom;
            },
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
                  icon: Icons.layers_outlined,
                  tooltip: 'Style de carte',
                  onTap: _openTypePicker,
                ),
                const SizedBox(height: 10),
                MapControlButton(
                  icon: Icons.threed_rotation,
                  tooltip: _is3D ? 'Vue 2D' : 'Vue 3D',
                  onTap: _toggle3D,
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
        ],
      ),
    );
  }
}
