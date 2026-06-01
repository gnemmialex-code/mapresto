import '../models/place.dart';

/// Resultat de la repartition freemium.
class FreemiumResult {
  final List<Place> visiblePlaces; // accessibles gratuitement
  final List<Place> lockedPlaces; // verrouilles (Premium)

  const FreemiumResult({
    required this.visiblePlaces,
    required this.lockedPlaces,
  });

  bool get hasLocked => lockedPlaces.isNotEmpty;
}

/// Gere la limitation freemium : max 5 lieux visibles quand des filtres
/// sont actifs. Le reste est marque comme "Premium".
///
/// >>> POINT DE BRANCHEMENT PAYWALL <<<
/// Quand un vrai systeme de paiement sera branche, exposer un booleen
/// `isPremiumUser` (depuis un service d'achat / RevenueCat / StoreKit) et
/// renvoyer tous les lieux comme `visiblePlaces` si l'utilisateur est premium.
class FreemiumService {
  static const int freeLimit = 5;

  /// [filtersActive] : la limite ne s'applique que lorsque des filtres
  /// sont actifs (conformement a la specification produit).
  /// [isPremiumUser] : si true, aucune limite (deja pret pour le paywall).
  FreemiumResult split(
    List<Place> places, {
    required bool filtersActive,
    bool isPremiumUser = false,
  }) {
    if (!filtersActive || isPremiumUser || places.length <= freeLimit) {
      return FreemiumResult(visiblePlaces: places, lockedPlaces: const []);
    }
    return FreemiumResult(
      visiblePlaces: places.take(freeLimit).toList(),
      lockedPlaces: places.skip(freeLimit).toList(),
    );
  }
}
