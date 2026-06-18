import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collection_style.dart';
import '../models/place.dart';
import '../models/place_annotation.dart';
import '../models/user_collection.dart';
import '../services/mock_data_service.dart';
import '../services/sharing_service.dart';

/// Resultat d'une tentative d'utilisation d'un code de parrainage.
enum ReferralResult { success, invalid, ownCode }

/// Gere les collections de l'utilisateur, sa carte perso (freemium),
/// l'espace createur/influenceur, la generation de codes et l'import.
class CollectionsViewModel extends ChangeNotifier {
  CollectionsViewModel({
    required MockDataService dataService,
    required SharingService sharingService,
    required List<Place> places,
  })  : _dataService = dataService,
        _sharingService = sharingService,
        _catalog = places {
    _collections = List.of(_dataService.getUserCollections());
    // Carte perso vide au depart (plan gratuit).
    _myMap = UserCollection(
      id: 'my-map',
      ownerName: 'Moi',
      code: '',
      style: const CollectionStyle(
        id: 'my-style',
        name: 'Ma carte',
        primaryColor: Color(0xFF6C5CE7),
        iconStyle: 'minimal',
        description: 'Mes adresses a Paris.',
      ),
      places: const [],
    );
    _referralCode = _generateReferralCode();
    _loadAnnotations();
  }

  /// Limite de base de lieux pour le plan gratuit (carte perso).
  static const int freeMapLimit = 10;

  /// Bonus de lieux accorde par filleul.
  static const int referralBonusPlaces = 5;

  /// Duree du Premium offert par filleul.
  static const Duration referralPremiumDuration = Duration(days: 5);

  final MockDataService _dataService;
  final SharingService _sharingService;
  final List<Place> _catalog;

  late List<UserCollection> _collections;
  UserCollection? _lastImported;

  late UserCollection _myMap;
  bool _creatorUnlocked = false;

  // ---- Parrainage ----
  late final String _referralCode;
  int _referralCount = 0;
  int _bonusPlaces = 0;
  DateTime? _premiumUntil;

  // ---- Annotations (notes + catégories par lieu) ----
  Map<String, PlaceAnnotation> _annotations = {};

  List<UserCollection> get collections => List.unmodifiable(_collections);
  List<CollectionStyle> get availableStyles => _dataService.getStyles();
  UserCollection? get lastImported => _lastImported;

  /// Exemples de cartes d'influenceurs (pour la vitrine + tester les codes).
  List<UserCollection> get influencerShowcase =>
      _dataService.getInfluencerCollections();

  /// Catalogue complet des lieux (pour construire sa carte).
  List<Place> get catalog => _catalog;

  // ---- Carte perso / espace createur ----
  UserCollection get myMap => _myMap;
  bool get isCreatorUnlocked => _creatorUnlocked;
  int get myMapCount => _myMap.places.length;

  /// Limite effective = base + bonus de parrainage (illimite si Createur).
  int get mapLimit => freeMapLimit + _bonusPlaces;
  int get remainingFreeSlots => (mapLimit - myMapCount).clamp(0, mapLimit);
  bool get canAddToMyMap => _creatorUnlocked || myMapCount < mapLimit;

  /// Acces aux lieux sauvegardes : 5 max en gratuit, illimite si Premium/Createur.
  static const int freeAccessLimit = 5;
  bool get hasFullAccess => _creatorUnlocked || isPremiumActive;
  List<Place> get accessibleSavedPlaces => hasFullAccess
      ? _myMap.places
      : _myMap.places.take(freeAccessLimit).toList();
  List<Place> get lockedSavedPlaces => hasFullAccess
      ? const []
      : _myMap.places.skip(freeAccessLimit).toList();

  // ---- Parrainage (lecture) ----
  String get referralCode => _referralCode;
  int get referralCount => _referralCount;
  int get bonusPlaces => _bonusPlaces;
  DateTime? get premiumUntil => _premiumUntil;
  bool get isPremiumActive =>
      _premiumUntil != null && _premiumUntil!.isAfter(DateTime.now());
  int get premiumDaysLeft {
    if (!isPremiumActive) return 0;
    return _premiumUntil!.difference(DateTime.now()).inHours ~/ 24 + 1;
  }

  bool isInMyMap(Place p) => _myMap.places.any((e) => e.id == p.id);

  /// Ajoute un lieu a la carte perso. Renvoie false si la limite gratuite
  /// est atteinte (l'UI proposera alors de passer au plan Createur).
  bool addToMyMap(Place p) {
    if (isInMyMap(p)) return true;
    if (!canAddToMyMap) return false;
    _myMap = _myMap.copyWith(places: [..._myMap.places, p]);
    notifyListeners();
    return true;
  }

  void removeFromMyMap(Place p) {
    _myMap = _myMap.copyWith(
      places: _myMap.places.where((e) => e.id != p.id).toList(),
    );
    notifyListeners();
  }

  /// Debloque l'espace Createur/Influenceur (mock paywall reussi).
  ///
  /// >>> POINT DE BRANCHEMENT PAYWALL <<<
  /// Appeler ceci apres un achat valide (StoreKit / RevenueCat / backend).
  void unlockCreator() {
    _creatorUnlocked = true;
    _myMap = _myMap.copyWith(isInfluencer: true);
    notifyListeners();
  }

  // ---- Parrainage (actions) ----

  // ---- Annotations ----

  PlaceAnnotation? annotationFor(String placeId) => _annotations[placeId];

  List<String> get allCategories => _annotations.values
      .map((a) => a.category)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  Future<void> setAnnotation(
    String placeId, {
    required String note,
    required String category,
  }) async {
    _annotations[placeId] = PlaceAnnotation(
      placeId: placeId,
      note: note,
      category: category,
    );
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'place_annotations', PlaceAnnotation.encodeMap(_annotations));
  }

  Future<void> _loadAnnotations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('place_annotations');
    if (raw != null) {
      _annotations = PlaceAnnotation.decodeMap(raw);
      notifyListeners();
    }
  }

  String _generateReferralCode() {
    final n = Random().nextInt(9000) + 1000;
    return 'PARIS-PARRAIN-$n';
  }

  /// Saisie d'un code de parrainage (dans les parametres).
  ///
  /// Dans une vraie app, le filleul saisit le code de son parrain et c'est
  /// LE PARRAIN qui est recompense cote serveur. Ici (demo local mono-appareil)
  /// on applique la recompense a l'utilisateur courant pour la rendre visible.
  ///
  /// >>> POINT DE BRANCHEMENT BACKEND <<<
  /// Remplacer par un appel API : POST { code, deviceId } -> le serveur valide
  /// (pas deja utilise, pas son propre code) puis cree l'recompense du parrain.
  ReferralResult redeemReferralCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.length < 4) return ReferralResult.invalid;
    if (code == _referralCode) return ReferralResult.ownCode;
    _grantReferralReward();
    return ReferralResult.success;
  }

  /// Recompense d'un parrainage reussi : +5 lieux + 5 jours de Premium.
  void _grantReferralReward() {
    _referralCount++;
    _bonusPlaces += referralBonusPlaces;
    final base = isPremiumActive ? _premiumUntil! : DateTime.now();
    _premiumUntil = base.add(referralPremiumDuration);
    notifyListeners();
  }

  /// Met a jour le style de la carte perso (espace Createur).
  void updateMyMapStyle({
    String? name,
    Color? color,
    String? iconStyle,
    String? description,
    String? handle,
  }) {
    final s = _myMap.style;
    _myMap = _myMap.copyWith(
      authorHandle: handle ?? _myMap.authorHandle,
      style: CollectionStyle(
        id: s.id,
        name: name ?? s.name,
        primaryColor: color ?? s.primaryColor,
        iconStyle: iconStyle ?? s.iconStyle,
        description: description ?? s.description,
      ),
    );
    notifyListeners();
  }

  /// Publie la carte perso et renvoie son code de partage.
  String publishMyMap() {
    if (_myMap.code.isEmpty) {
      final code = _sharingService.generateCode(_myMap);
      _myMap = _myMap.copyWith(code: code);
      notifyListeners();
    }
    return _myMap.code;
  }

  /// Cree une nouvelle collection (vide ou pre-remplie) avec un style donne.
  UserCollection createCollection({
    required String name,
    required CollectionStyle style,
    List<Place> places = const [],
  }) {
    final collection = UserCollection(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      ownerName: name,
      code: '', // genere a la demande lors du partage
      style: style,
      places: places,
    );
    _collections.add(collection);
    notifyListeners();
    return collection;
  }

  /// Genere (ou recupere) le code de partage d'une collection.
  String shareCollection(UserCollection collection) {
    if (collection.code.isNotEmpty) return collection.code;
    final code = _sharingService.generateCode(collection);
    final index = _collections.indexWhere((c) => c.id == collection.id);
    if (index != -1) {
      _collections[index] = collection.copyWith(code: code);
      notifyListeners();
    }
    return code;
  }

  /// Importe une collection a partir d'un code. Renvoie null si invalide.
  UserCollection? importByCode(String code) {
    final imported = _sharingService.resolveCode(code);
    if (imported == null) return null;
    _lastImported = imported;
    // On evite les doublons par code.
    if (!_collections.any((c) => c.code == imported.code)) {
      _collections.add(imported);
    }
    notifyListeners();
    return imported;
  }
}
