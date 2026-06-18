// Tests unitaires deterministes (sans boot reseau de l'app).
//
// L'ancien smoke-test bootait ParisMapApp et cherchait un onglet "Collections"
// qui n'existe plus ; booter l'app entiere en test est de plus non
// deterministe (cartes + images reseau). On couvre ici la logique metier,
// dont les fonctionnalites recentes (filtre "ouvert maintenant", conciergerie).

import 'package:flutter_test/flutter_test.dart';

import 'package:parismap_video_guide/models/filter_options.dart';
import 'package:parismap_video_guide/models/place.dart';
import 'package:parismap_video_guide/services/concierge_service.dart';

Place _place({
  PlaceType type = PlaceType.bar,
  int priceLevel = 2,
  double rating = 4.2,
  List<String> openingHours = const [],
}) {
  return Place(
    id: 'p01',
    name: 'Le Perchoir',
    type: type,
    latitude: 48.86,
    longitude: 2.37,
    address: '14 rue Crespin du Gast, Paris',
    rating: rating,
    reviewCount: 1200,
    priceLevel: priceLevel,
    openingHours: openingHours,
  );
}

void main() {
  group('FilterOptions.isOpenNow', () {
    test('lieu "toute la journee" est toujours ouvert', () {
      expect(
        FilterOptions.isOpenNow(_place(openingHours: ['Toute la journée'])),
        isTrue,
      );
    });

    test('sans horaires connus, on ne masque pas le lieu (considere ouvert)', () {
      expect(FilterOptions.isOpenNow(_place(openingHours: const [])), isTrue);
    });
  });

  group('FilterOptions.matches', () {
    test('le filtre openNow garde un lieu ouvert toute la journee', () {
      const filter = FilterOptions(openNow: true);
      expect(filter.matches(_place(openingHours: ['Toute la journée'])), isTrue);
    });

    test('le filtre de type exclut les autres types', () {
      const filter = FilterOptions(type: PlaceType.restaurant);
      expect(filter.matches(_place(type: PlaceType.bar)), isFalse);
      expect(filter.matches(_place(type: PlaceType.restaurant)), isTrue);
    });

    test('activeCount et isActive refletent les filtres poses', () {
      const empty = FilterOptions();
      expect(empty.isActive, isFalse);
      expect(empty.activeCount, 0);

      const active = FilterOptions(openNow: true, maxPriceLevel: 2);
      expect(active.isActive, isTrue);
      expect(active.activeCount, 2);
    });
  });

  group('Place', () {
    test('priceLabel rend des euros bornes 1..4', () {
      expect(_place(priceLevel: 3).priceLabel, '€€€');
    });

    test('directionsUrl pointe vers la destination', () {
      final url = _place().directionsUrl();
      expect(url, contains('destination=48.86,2.37'));
      expect(url, contains('travelmode=driving'));
    });
  });

  group('ConciergeService', () {
    test('le message pour un lieu cite son nom et son type', () {
      final msg = ConciergeService.messageForPlace(_place());
      expect(msg, contains('Le Perchoir'));
      expect(msg, contains('Bar'));
    });
  });
}
