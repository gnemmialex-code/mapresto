import 'package:flutter/foundation.dart';

/// Annotations personnelles de l'utilisateur sur les lieux :
/// note perso + tags persos (par id de lieu).
///
/// >>> POINT DE BRANCHEMENT BACKEND <<<
/// Persister ces donnees (local: shared_preferences/Hive ; distant: API)
/// pour les retrouver entre sessions et appareils.
class UserTagsViewModel extends ChangeNotifier {
  final Map<String, double> _ratings = {};
  final Map<String, List<String>> _tags = {};

  double? ratingFor(String placeId) => _ratings[placeId];
  List<String> tagsFor(String placeId) =>
      List.unmodifiable(_tags[placeId] ?? const []);

  void setRating(String placeId, double rating) {
    _ratings[placeId] = rating;
    notifyListeners();
  }

  void clearRating(String placeId) {
    if (_ratings.remove(placeId) != null) notifyListeners();
  }

  void addTag(String placeId, String tag) {
    final t = tag.trim();
    if (t.isEmpty) return;
    final list = _tags.putIfAbsent(placeId, () => []);
    if (!list.contains(t)) {
      list.add(t);
      notifyListeners();
    }
  }

  void removeTag(String placeId, String tag) {
    final list = _tags[placeId];
    if (list != null && list.remove(tag)) notifyListeners();
  }
}
