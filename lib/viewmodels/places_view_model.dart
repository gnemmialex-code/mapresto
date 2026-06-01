import 'package:flutter/foundation.dart';

import '../models/filter_options.dart';
import '../models/place.dart';
import '../services/freemium_service.dart';
import '../services/mock_data_service.dart';

/// Coeur de l'app : detient tous les lieux, l'etat des filtres et applique
/// la logique freemium. Partage par l'ecran Carte ET l'ecran Liste.
class PlacesViewModel extends ChangeNotifier {
  PlacesViewModel({
    required MockDataService dataService,
    required FreemiumService freemiumService,
  })  : _dataService = dataService,
        _freemiumService = freemiumService {
    _allPlaces = _dataService.getPlaces();
  }

  final MockDataService _dataService;
  final FreemiumService _freemiumService;

  late final List<Place> _allPlaces;

  // Etat des filtres (stocke champ par champ pour gerer simplement les null).
  PlaceType? _type;
  double? _minRating;
  int? _maxPriceLevel;
  int? _maxAveragePrice;
  final Set<String> _ambiance = {};
  final Set<String> _music = {};
  final Set<String> _style = {};
  final Set<String> _crowd = {};
  final Set<String> _peak = {};

  // ---- Lecture de l'etat ----
  List<Place> get allPlaces => List.unmodifiable(_allPlaces);

  FilterOptions get filter => FilterOptions(
        type: _type,
        minRating: _minRating,
        maxPriceLevel: _maxPriceLevel,
        maxAveragePrice: _maxAveragePrice,
        ambiance: _ambiance.toList(),
        music: _music.toList(),
        style: _style.toList(),
        crowd: _crowd.toList(),
        peak: _peak.toList(),
      );

  bool get filtersActive => filter.isActive;
  int get activeFilterCount => filter.activeCount;

  /// Lieux respectant les filtres (avant limitation freemium).
  List<Place> get filteredPlaces {
    final f = filter;
    if (!f.isActive) return _allPlaces;
    return _allPlaces.where(f.matches).toList();
  }

  /// Repartition freemium calculee a la demande.
  FreemiumResult get _result => _freemiumService.split(
        filteredPlaces,
        filtersActive: filtersActive,
      );

  List<Place> get visiblePlaces => _result.visiblePlaces;
  List<Place> get lockedPlaces => _result.lockedPlaces;
  bool get hasLockedPlaces => _result.hasLocked;

  // ---- Mutations des filtres ----
  void setType(PlaceType? type) {
    _type = type;
    notifyListeners();
  }

  void setMinRating(double? value) {
    _minRating = value;
    notifyListeners();
  }

  void setMaxPriceLevel(int? value) {
    _maxPriceLevel = value;
    notifyListeners();
  }

  void setMaxAveragePrice(int? value) {
    _maxAveragePrice = value;
    notifyListeners();
  }

  void toggleAmbiance(String tag) => _toggle(_ambiance, tag);
  void toggleMusic(String tag) => _toggle(_music, tag);
  void toggleStyle(String tag) => _toggle(_style, tag);
  void toggleCrowd(String tag) => _toggle(_crowd, tag);
  void togglePeak(String tag) => _toggle(_peak, tag);

  bool isAmbianceSelected(String tag) => _ambiance.contains(tag);
  bool isMusicSelected(String tag) => _music.contains(tag);
  bool isStyleSelected(String tag) => _style.contains(tag);
  bool isCrowdSelected(String tag) => _crowd.contains(tag);
  bool isPeakSelected(String tag) => _peak.contains(tag);

  void _toggle(Set<String> set, String tag) {
    if (!set.add(tag)) set.remove(tag);
    notifyListeners();
  }

  void clearFilters() {
    _type = null;
    _minRating = null;
    _maxPriceLevel = null;
    _maxAveragePrice = null;
    _ambiance.clear();
    _music.clear();
    _style.clear();
    _crowd.clear();
    _peak.clear();
    notifyListeners();
  }

  Place? placeById(String id) {
    for (final p in _allPlaces) {
      if (p.id == id) return p;
    }
    return null;
  }
}
