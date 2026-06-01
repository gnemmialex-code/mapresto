import 'package:latlong2/latlong.dart';

import '../models/itinerary.dart';
import '../models/place.dart';

/// Un "role" d'etape : type de lieu attendu + styles preferes.
class _Role {
  final String label;
  final PlaceType type;
  final List<String> preferredStyles;
  const _Role(this.label, this.type, this.preferredStyles);
}

/// Compose un itineraire "Adresse parfaite" (midi ou soir) : une suite de
/// lieux enchaines, en partant de la position de l'utilisateur.
///
/// Strategie : pour chaque etape, on choisit le meilleur lieu du bon type,
/// proche de l'etape precedente, bien note et conforme aux preferences
/// (glouton, plus proche/meilleur a chaque etape).
class ItineraryService {
  static const _midi = [
    _Role('Dejeuner', PlaceType.restaurant,
        ['bistrot', 'gastronomique', 'terrasse']),
    _Role('Cafe & balade', PlaceType.bar, ['terrasse', 'cocktails']),
  ];

  static const _soir = [
    _Role('Apero', PlaceType.bar, ['terrasse', 'cocktails']),
    _Role('Diner', PlaceType.restaurant,
        ['gastronomique', 'bistrot', 'terrasse']),
    _Role('Dernier verre', PlaceType.bar,
        ['cocktails', 'rooftop', 'speakeasy']),
  ];

  static const Distance _distance = Distance();

  Itinerary build(ItineraryRequest req, List<Place> places) {
    final roles = req.moment == Moment.midi ? _midi : _soir;
    final used = <String>{};
    var curLat = req.startLat;
    var curLng = req.startLng;
    final stops = <ItineraryStop>[];

    for (final role in roles) {
      Place? best;
      var bestScore = -1.0;
      var bestDist = 0.0;

      for (final p in places) {
        if (p.type != role.type) continue;
        if (used.contains(p.id)) continue;
        if (p.priceLevel > req.maxPriceLevel) continue;

        final dist = _distance.as(LengthUnit.Meter,
            LatLng(curLat, curLng), LatLng(p.latitude, p.longitude));
        final proximity = 1 / (1 + dist / 1000); // 0..1 (decroit avec la dist)
        final ratingScore = p.rating / 5.0;
        final styleBonus =
            role.preferredStyles.any(p.styleTags.contains) ? 0.25 : 0.0;
        final ambBonus = req.ambiance.isEmpty
            ? 0.0
            : req.ambiance.where(p.ambianceTags.contains).length /
                req.ambiance.length *
                0.25;

        final score =
            0.45 * proximity + 0.30 * ratingScore + styleBonus + ambBonus;
        if (score > bestScore) {
          bestScore = score;
          best = p;
          bestDist = dist;
        }
      }

      if (best != null) {
        used.add(best.id);
        stops.add(ItineraryStop(
            role: role.label, place: best, distanceFromPrev: bestDist));
        curLat = best.latitude;
        curLng = best.longitude;
      }
    }

    return Itinerary(
      moment: req.moment,
      startLat: req.startLat,
      startLng: req.startLng,
      startLabel: req.startLabel,
      stops: stops,
    );
  }

  /// Lien Google Maps de l'itineraire complet (a pied), avec etapes.
  String routeUrl(Itinerary it) {
    if (it.stops.isEmpty) return '';
    final origin = '${it.startLat},${it.startLng}';
    final dest =
        '${it.stops.last.place.latitude},${it.stops.last.place.longitude}';
    var url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin&destination=$dest&travelmode=walking';
    if (it.stops.length > 1) {
      final way = it.stops
          .sublist(0, it.stops.length - 1)
          .map((s) => '${s.place.latitude},${s.place.longitude}')
          .join('|');
      url += '&waypoints=${Uri.encodeComponent(way)}';
    }
    return url;
  }
}
