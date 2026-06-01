import 'place.dart';

/// Moment de la journee pour l'itineraire "Adresse parfaite".
enum Moment { midi, soir }

extension MomentX on Moment {
  String get label => this == Moment.midi ? 'Midi' : 'Soir';
}

/// Parametres saisis dans le formulaire.
class ItineraryRequest {
  final Moment moment;
  final double startLat;
  final double startLng;
  final String startLabel;
  final Set<String> ambiance;
  final int maxPriceLevel;

  const ItineraryRequest({
    required this.moment,
    required this.startLat,
    required this.startLng,
    required this.startLabel,
    this.ambiance = const {},
    this.maxPriceLevel = 4,
  });
}

/// Une etape de l'itineraire.
class ItineraryStop {
  final String role; // ex: "Apero", "Diner", "Dernier verre"
  final Place place;
  final double distanceFromPrev; // metres depuis l'etape precedente

  const ItineraryStop({
    required this.role,
    required this.place,
    required this.distanceFromPrev,
  });
}

/// Itineraire complet propose.
class Itinerary {
  final Moment moment;
  final double startLat;
  final double startLng;
  final String startLabel;
  final List<ItineraryStop> stops;

  const Itinerary({
    required this.moment,
    required this.startLat,
    required this.startLng,
    required this.startLabel,
    required this.stops,
  });

  double get totalDistance =>
      stops.fold(0, (sum, s) => sum + s.distanceFromPrev);
}
