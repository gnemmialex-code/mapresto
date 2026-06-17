import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/theme_controller.dart';
import 'feed/video_feed_screen.dart';
import 'map/map_tab.dart';
import 'maps/maps_hub_screen.dart';
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
  void dispose() {
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
    context.watch<ThemeController>(); // écoute les changements de thème
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
