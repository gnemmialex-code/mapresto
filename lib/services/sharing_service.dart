import 'dart:math';

import '../models/user_collection.dart';
import 'mock_data_service.dart';

/// Gere les codes de partage de collections.
///
/// Pour l'instant 100% local : un petit mapping `code -> UserCollection`.
///
/// >>> POINT DE BRANCHEMENT BACKEND <<<
/// Remplacer `generateCode` par un appel POST qui enregistre la collection
/// cote serveur et renvoie un code, et `resolveCode` par un GET qui
/// telecharge la collection correspondant au code.
class SharingService {
  SharingService(this._mockData) {
    // On pre-enregistre les collections mock pour qu'elles soient
    // importables via leur code (utile pour tester l'import).
    for (final c in _mockData.getUserCollections()) {
      _store[c.code] = c;
    }
    // Cartes d'influenceurs accessibles via leur code public.
    for (final c in _mockData.getInfluencerCollections()) {
      _store[c.code] = c;
    }
  }

  final MockDataService _mockData;
  final Map<String, UserCollection> _store = {};
  final Random _random = Random();

  static const List<String> _adjectives = [
    'CHIC',
    'COOL',
    'NIGHT',
    'ROOFTOP',
    'SECRET',
    'GOLD',
  ];

  /// Genere un code lisible du type "PARIS-CHIC-4821" et enregistre la
  /// collection pour qu'elle soit resolvable ensuite.
  String generateCode(UserCollection collection) {
    final adj = _adjectives[_random.nextInt(_adjectives.length)];
    final number = _random.nextInt(9000) + 1000;
    final code = 'PARIS-$adj-$number';
    _store[code] = collection.copyWith(code: code);
    return code;
  }

  /// Resout un code en collection. Renvoie null si le code est inconnu.
  /// La recherche est insensible a la casse et aux espaces.
  UserCollection? resolveCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (_store.containsKey(code)) return _store[code];

    // Fallback de demo : tout code "valide" non trouve renvoie une
    // collection mock, pour que la fonctionnalite soit testable hors-ligne.
    if (code.length >= 4) {
      final styles = _mockData.getStyles();
      return UserCollection(
        id: 'imported-$code',
        ownerName: 'Invite',
        code: code,
        style: styles.last,
        places: _mockData.getPlaces().take(4).toList(),
      );
    }
    return null;
  }
}
