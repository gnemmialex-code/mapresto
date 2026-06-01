import 'place.dart';

/// Reponses de l'utilisateur au questionnaire "carte sur-mesure".
class SuggestionPreferences {
  final PlaceType? type;
  final Set<String> ambiance;
  final Set<String> style;
  final Set<String> crowd;
  final Set<String> music;
  final int maxPriceLevel; // 1..4

  const SuggestionPreferences({
    this.type,
    this.ambiance = const {},
    this.style = const {},
    this.crowd = const {},
    this.music = const {},
    this.maxPriceLevel = 4,
  });

  int get selectedTagCount =>
      ambiance.length + style.length + crowd.length + music.length;
}
