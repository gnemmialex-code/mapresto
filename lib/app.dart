import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/freemium_service.dart';
import 'services/mock_data_service.dart';
import 'services/sharing_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/collections_view_model.dart';
import 'viewmodels/map_view_model.dart';
import 'viewmodels/places_view_model.dart';
import 'viewmodels/theme_controller.dart';
import 'viewmodels/user_tags_view_model.dart';
import 'views/feed/video_feed_screen.dart';
import 'views/map/map_tab.dart';
import 'views/maps/maps_hub_screen.dart';
import 'views/places/places_list_screen.dart';

/// Racine de l'application : injecte services + viewmodels via Provider,
/// configure le theme et la navigation principale.
class ParisMapApp extends StatelessWidget {
  const ParisMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Services (singletons pour la session). A remplacer par de vrais
    // clients API/repositories plus tard sans toucher aux viewmodels.
    final mockData = MockDataService();
    final freemium = FreemiumService();
    final sharing = SharingService(mockData);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlacesViewModel(
            dataService: mockData,
            freemiumService: freemium,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MapViewModel()),
        ChangeNotifierProvider(create: (_) => UserTagsViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => CollectionsViewModel(
            dataService: mockData,
            sharingService: sharing,
          ),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) {
          final dark = themeCtrl.isDark;
          return MaterialApp(
            title: 'ParisMap Video Guide',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeFor(dark),
            home: const RootNavigation(),
          );
        },
      ),
    );
  }
}

/// Navigation principale par BottomNavigationBar (3 onglets).
class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  // Anime un fondu doux a chaque changement d'onglet (etat preserve).
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
    // IndexedStack conserve l'etat de chaque onglet (position carte, scroll...).
    // Le feed video recoit isActive pour se mettre en pause hors de son onglet.
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
              icon: Icon(Icons.play_circle_outline), label: 'Videos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Mon Espace'),
        ],
      ),
    );
  }
}
