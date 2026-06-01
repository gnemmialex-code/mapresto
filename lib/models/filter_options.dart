import 'package:flutter/foundation.dart';
import 'place.dart';

/// Criteres de filtrage appliques a la liste des lieux.
@immutable
class FilterOptions {
  final PlaceType? type;
  final double? minRating;
  final int? maxPriceLevel;
  final int? maxAveragePrice; // prix reel max en euros
  final List<String> ambiance;
  final List<String> music;
  final List<String> style;
  final List<String> crowd; // frequentation
  final List<String> peak; // horaires d'affluence

  const FilterOptions({
    this.type,
    this.minRating,
    this.maxPriceLevel,
    this.maxAveragePrice,
    this.ambiance = const [],
    this.music = const [],
    this.style = const [],
    this.crowd = const [],
    this.peak = const [],
  });

  /// Au moins un filtre est actif (declenche la logique freemium).
  bool get isActive =>
      type != null ||
      minRating != null ||
      maxPriceLevel != null ||
      maxAveragePrice != null ||
      ambiance.isNotEmpty ||
      music.isNotEmpty ||
      style.isNotEmpty ||
      crowd.isNotEmpty ||
      peak.isNotEmpty;

  /// Nombre de criteres actifs (pour afficher un badge sur le bouton filtres).
  int get activeCount {
    var count = 0;
    if (type != null) count++;
    if (minRating != null) count++;
    if (maxPriceLevel != null) count++;
    if (maxAveragePrice != null) count++;
    count += ambiance.length +
        music.length +
        style.length +
        crowd.length +
        peak.length;
    return count;
  }

  /// Teste si un lieu respecte les criteres.
  /// Pour des tags : on garde un lieu s'il possede AU MOINS un des tags choisis.
  /// (Ameliorer ici plus tard : ET logique, score de pertinence, etc.)
  bool matches(Place place) {
    if (type != null && place.type != type) return false;
    if (minRating != null && place.rating < minRating!) return false;
    if (maxPriceLevel != null && place.priceLevel > maxPriceLevel!) return false;
    if (maxAveragePrice != null && place.averagePrice > maxAveragePrice!) {
      return false;
    }
    if (ambiance.isNotEmpty &&
        !ambiance.any(place.ambianceTags.contains)) {
      return false;
    }
    if (music.isNotEmpty && !music.any(place.musicTags.contains)) return false;
    if (style.isNotEmpty && !style.any(place.styleTags.contains)) return false;
    if (crowd.isNotEmpty && !crowd.any(place.crowdTags.contains)) return false;
    if (peak.isNotEmpty && !peak.any(place.peakTags.contains)) return false;
    return true;
  }
}
