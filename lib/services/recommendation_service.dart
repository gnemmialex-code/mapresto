import '../models/place.dart';
import '../models/suggestion_preferences.dart';

/// Un lieu recommande, avec son score de correspondance et les raisons.
class Recommendation {
  final Place place;
  final double score; // 0..1
  final int matchPercent; // 0..100
  final List<String> reasons;

  const Recommendation({
    required this.place,
    required this.score,
    required this.matchPercent,
    required this.reasons,
  });
}

/// Moteur de recommandation : classe les lieux selon les preferences.
///
/// Score = 70% correspondance des tags choisis + 30% note du lieu.
/// (Ameliorer ici plus tard : ponderation par tag, distance, popularite,
/// apprentissage des gouts, etc.)
class RecommendationService {
  List<Recommendation> recommend(
    SuggestionPreferences prefs,
    List<Place> places, {
    int limit = 12,
  }) {
    final filtered = places.where((p) {
      if (prefs.type != null && p.type != prefs.type) return false;
      if (p.priceLevel > prefs.maxPriceLevel) return false;
      return true;
    });

    final recos = <Recommendation>[];
    for (final p in filtered) {
      final a = prefs.ambiance.where(p.ambianceTags.contains).toList();
      final s = prefs.style.where(p.styleTags.contains).toList();
      final c = prefs.crowd.where(p.crowdTags.contains).toList();
      final m = prefs.music.where(p.musicTags.contains).toList();
      final matched = a.length + s.length + c.length + m.length;

      final reasons = <String>[
        if (a.isNotEmpty) 'Ambiance : ${a.join(', ')}',
        if (s.isNotEmpty) 'Style : ${s.join(', ')}',
        if (c.isNotEmpty) 'Public : ${c.join(', ')}',
        if (m.isNotEmpty) 'Musique : ${m.join(', ')}',
      ];

      final tagScore =
          prefs.selectedTagCount == 0 ? 0.6 : matched / prefs.selectedTagCount;
      final ratingScore = p.rating / 5.0;
      final score = 0.7 * tagScore + 0.3 * ratingScore;

      recos.add(Recommendation(
        place: p,
        score: score,
        matchPercent: (score * 100).round().clamp(0, 100),
        reasons: reasons,
      ));
    }

    recos.sort((x, y) {
      final byScore = y.score.compareTo(x.score);
      return byScore != 0 ? byScore : y.place.rating.compareTo(x.place.rating);
    });

    return recos.take(limit).toList();
  }
}
