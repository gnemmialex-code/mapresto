import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/place.dart';
import 'services/freemium_service.dart';
import 'services/mock_data_service.dart';
import 'services/places_service.dart';
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
class _AppWithPlaces extends StatelessWidget {
  const _AppWithPlaces({required this.places});
  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final mockData = MockDataService();
    final freemium = FreemiumService();
    final sharing = SharingService(mockData);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlacesViewModel(
            places: places,
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
            places: places,
          ),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) {
          return MaterialApp(
            title: 'ParisMap Video Guide',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeFor(themeCtrl.isDark),
            // L'écran d'onboarding/filtre s'affiche au lancement.
            // Il navigue vers RootNavigation une fois les filtres validés.
            home: const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
