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
  final bool openNow;

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
    this.openNow = false,
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
      openingHours.isNotEmpty ||
      openNow;

  int get activeCount {
    var count = 0;
    if (type != null) count++;
    if (minRating != null) count++;
    if (maxPriceLevel != null) count++;
    if (minAveragePrice != null || maxAveragePrice != null) count++;
    if (openNow) count++;
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
    if (openNow && !isOpenNow(place)) return false;
    return true;
  }

  /// Détermine si un lieu est ouvert maintenant selon ses créneaux habituels.
  static bool isOpenNow(Place place) {
    if (place.openingHours.isEmpty) return true;
    final now = DateTime.now();
    final h = now.hour;
    final isWeekend = now.weekday >= 6;
    for (final oh in place.openingHours) {
      final l = oh.toLowerCase();
      if (l.contains('toute la journée') || l.contains('toute la journee')) return true;
      if (l.contains('matin') && h >= 7 && h < 12) return true;
      if (l.contains('midi') && h >= 11 && h < 15) return true;
      if ((l.contains('après-midi') || l.contains('apres-midi')) && h >= 15 && h < 19) return true;
      if (l.contains('after-work') && h >= 17 && h < 21) return true;
      if (l.contains('soir') && (h >= 18 || h < 2)) return true;
      if (l.contains('nuit') && (h >= 22 || h < 6)) return true;
      if (l.contains('week-end') && isWeekend) return true;
    }
    return false;
  }
}
