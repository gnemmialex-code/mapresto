import 'package:flutter/foundation.dart';

@immutable
class UserReview {
  const UserReview({
    required this.rating,
    required this.text,
    required this.date,
    this.author = 'Moi',
  });

  final String author;
  final double rating;
  final String text;
  final DateTime date;
}

/// Avis soumis par l'utilisateur, stockes en memoire par lieu.
///
/// >>> POINT DE BRANCHEMENT BACKEND <<<
/// Persister via shared_preferences ou Supabase pour retrouver les avis entre sessions.
class UserReviewsViewModel extends ChangeNotifier {
  final Map<String, List<UserReview>> _reviews = {};

  List<UserReview> reviewsFor(String placeId) =>
      List.unmodifiable(_reviews[placeId] ?? const []);

  void addReview(String placeId, UserReview review) {
    _reviews.putIfAbsent(placeId, () => []).add(review);
    notifyListeners();
  }
}
