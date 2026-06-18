import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/places_view_model.dart';
import '../viewmodels/theme_controller.dart';
import 'feed/video_feed_screen.dart';
import 'map/map_tab.dart';
import 'maps/maps_hub_screen.dart';
import 'place_detail/place_detail_screen.dart';
import 'places/places_list_screen.dart';

/// Navigation principale par BottomNavigationBar (4 onglets).
class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNewPlacesBanner());
    // Ouvre la fiche d'un lieu quand une alerte de proximite est tapee.
    NotificationService.instance.selectedPlaceId
        .addListener(_handleNotificationTap);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNotificationTap());
  }

  void _handleNotificationTap() {
    final id = NotificationService.instance.selectedPlaceId.value;
    if (id == null || !mounted) return;
    final place = context.read<PlacesViewModel>().placeById(id);
    NotificationService.instance.selectedPlaceId.value = null;
    if (place == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
    );
  }

  Future<void> _showNewPlacesBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('pending_new_places') ?? 0;
    if (count <= 0 || !mounted) return;
    await prefs.remove('pending_new_places');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppColors.primary,
        leading: const Icon(Icons.new_releases, color: Colors.white),
        content: Text(
          '$count nouveau${count > 1 ? 'x' : ''} lieu${count > 1 ? 'x' : ''} ajouté${count > 1 ? 's' : ''} !',
          style: AppTypography.body.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('Super !',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    NotificationService.instance.selectedPlaceId
        .removeListener(_handleNotificationTap);
    _anim.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final screens = [
      const MapTab(),
      const PlacesListScreen(),
      VideoFeedScreen(isActive: _index == 2),
      const MapsHubScreen(),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fade,
        builder: (context, child) {
          final t = _fade.value;
          return Opacity(
            opacity: 0.35 + 0.65 * t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 10),
              child: child,
            ),
          );
        },
        child: IndexedStack(index: _index, children: screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _select,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Carte'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Lieux'),
          BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline), label: 'Vidéos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_location_alt), label: 'Ma Carte'),
        ],
      ),
    );
  }
}
