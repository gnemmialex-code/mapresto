import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/place.dart';
import 'services/freemium_service.dart';
import 'services/mock_data_service.dart';
import 'services/places_service.dart';
import 'services/proximity_service.dart';
import 'services/sharing_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'viewmodels/collections_view_model.dart';
import 'viewmodels/map_view_model.dart';
import 'viewmodels/places_view_model.dart';
import 'viewmodels/theme_controller.dart';
import 'viewmodels/user_reviews_view_model.dart';
import 'viewmodels/user_tags_view_model.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/root_navigation.dart';

/// Racine : charge les lieux (Supabase ou mock) puis monte l'app.
class ParisMapApp extends StatefulWidget {
  const ParisMapApp({super.key});

  @override
  State<ParisMapApp> createState() => _ParisMapAppState();
}

class _ParisMapAppState extends State<ParisMapApp> {
  late final Future<List<Place>> _placesFuture;

  @override
  void initState() {
    super.initState();
    _placesFuture = PlacesService().getPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Place>>(
      future: _placesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Color(0xFFF7F7FB),
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }
        final places = snapshot.data ?? const [];
        return _AppWithPlaces(places: places);
      },
    );
  }
}

/// Partie de l'app qui nécessite les lieux chargés.
class _AppWithPlaces extends StatefulWidget {
  const _AppWithPlaces({required this.places});
  final List<Place> places;

  @override
  State<_AppWithPlaces> createState() => _AppWithPlacesState();
}

class _AppWithPlacesState extends State<_AppWithPlaces> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    _checkNewPlaces();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _onboardingDone = prefs.getBool('onboarding_done') ?? false);
    }
  }

  Future<void> _checkNewPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCount = prefs.getInt('last_known_places') ?? 0;
    final current = widget.places.length;
    await prefs.setInt('last_known_places', current);
    if (current > lastCount && lastCount > 0) {
      await prefs.setInt('pending_new_places', current - lastCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mockData = MockDataService();
    final freemium = FreemiumService();
    final sharing = SharingService(mockData);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlacesViewModel(
            places: widget.places,
            freemiumService: freemium,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MapViewModel()),
        ChangeNotifierProvider(create: (_) => UserTagsViewModel()),
        ChangeNotifierProvider(create: (_) => UserReviewsViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => CollectionsViewModel(
            dataService: mockData,
            sharingService: sharing,
            places: widget.places,
          ),
        ),
        // Alertes de proximite : relie la source "lieux enregistres" a la
        // carte perso (CollectionsViewModel) et restaure l'etat sauvegarde.
        ChangeNotifierProxyProvider<CollectionsViewModel, ProximityService>(
          create: (_) => ProximityService()..restore(),
          update: (_, collections, proximity) {
            proximity!.attachSavedPlacesSource(() => collections.myMap.places);
            return proximity;
          },
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) {
          if (_onboardingDone == null) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.themeFor(themeCtrl.isDark),
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            );
          }
          return MaterialApp(
            title: 'ParisMap Video Guide',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeFor(themeCtrl.isDark),
            home: _onboardingDone! ? const RootNavigation() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
