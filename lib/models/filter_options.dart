import 'package:flutter/foundation.dart';
import 'place.dart';

/// Criteres de filtrage appliques a la liste des lieux.
@immutable
class FilterOptions {
  final PlaceType? type;
  final double? minRating;
  final int? maxPriceLevel;
  final int? minAveragePrice;
  final int? maxAveragePrice;
  final List<String> ambiance;
  final List<String> music;
  final List<String> style;
  final List<String> cuisine;
  final List<String> crowd;
  final List<String> peak;
  final List<String> openingHours;

  const FilterOptions({
    this.type,
    this.minRating,
    this.maxPriceLevel,
    this.minAveragePrice,
    this.maxAveragePrice,
    this.ambiance = const [],
    this.music = const [],
    this.style = const [],
    this.cuisine = const [],
    this.crowd = const [],
    this.peak = const [],
    this.openingHours = const [],
  });

  bool get isActive =>
      type != null ||
      minRating != null ||
      maxPriceLevel != null ||
      minAveragePrice != null ||
      maxAveragePrice != null ||
      ambiance.isNotEmpty ||
      music.isNotEmpty ||
      style.isNotEmpty ||
      cuisine.isNotEmpty ||
      crowd.isNotEmpty ||
      peak.isNotEmpty ||
      openingHours.isNotEmpty;

  int get activeCount {
    var count = 0;
    if (type != null) count++;
    if (minRating != null) count++;
    if (maxPriceLevel != null) count++;
    if (minAveragePrice != null || maxAveragePrice != null) count++;
    count += ambiance.length +
        music.length +
        style.length +
        cuisine.length +
        crowd.length +
        peak.length +
        openingHours.length;
    return count;
  }

  bool matches(Place place) {
    if (type != null && place.type != type) return false;
    if (minRating != null && place.rating < minRating!) return false;
    if (maxPriceLevel != null && place.priceLevel > maxPriceLevel!) return false;
    if (minAveragePrice != null && place.averagePrice < minAveragePrice!) return false;
    if (maxAveragePrice != null && place.averagePrice > maxAveragePrice!) return false;
    if (ambiance.isNotEmpty && !ambiance.any(place.ambianceTags.contains)) return false;
    if (music.isNotEmpty && !music.any(place.musicTags.contains)) return false;
    if (style.isNotEmpty && !style.any(place.styleTags.contains)) return false;
    if (cuisine.isNotEmpty && !cuisine.any(place.cuisineTags.contains)) return false;
    if (crowd.isNotEmpty && !crowd.any(place.crowdTags.contains)) return false;
    if (peak.isNotEmpty && !peak.any(place.peakTags.contains)) return false;
    if (openingHours.isNotEmpty && !openingHours.any(place.openingHours.contains)) return false;
    return true;
  }
}
