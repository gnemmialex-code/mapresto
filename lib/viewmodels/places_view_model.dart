import 'package:flutter/foundation.dart';

import '../models/filter_options.dart';
import '../models/place.dart';
import '../services/freemium_service.dart';

class PlacesViewModel extends ChangeNotifier {
  PlacesViewModel({
    required List<Place> places,
    required FreemiumService freemiumService,
  })  : _allPlaces = places,
        _freemiumService = freemiumService;

  final List<Place> _allPlaces;
  final FreemiumService _freemiumService;

  PlaceType? _type;
  double? _minRating;
  int? _maxPriceLevel;
  int? _minAveragePrice;
  int? _maxAveragePrice;
  final Set<String> _ambiance = {};
  final Set<String> _music = {};
  final Set<String> _style = {};
  final Set<String> _cuisine = {};
  final Set<String> _crowd = {};
  final Set<String> _peak = {};
  final Set<String> _openingHours = {};

  bool _openNow = false;

  // IDs retournés par la Recherche IA (null = mode filtres classiques).
  List<String>? _aiSearchIds;

  List<Place> get allPlaces => List.unmodifiable(_allPlaces);

  FilterOptions get filter => FilterOptions(
        type: _type,
        minRating: _minRating,
        maxPriceLevel: _maxPriceLevel,
        minAveragePrice: _minAveragePrice,
        maxAveragePrice: _maxAveragePrice,
        ambiance: _ambiance.toList(),
        music: _music.toList(),
        style: _style.toList(),
        cuisine: _cuisine.toList(),
        crowd: _crowd.toList(),
        peak: _peak.toList(),
        openingHours: _openingHours.toList(),
        openNow: _openNow,
      );

  bool get openNow => _openNow;
  void toggleOpenNow() { _openNow = !_openNow; notifyListeners(); }

  bool get filtersActive => filter.isActive || _aiSearchIds != null;
  int get activeFilterCount => filter.activeCount;
  bool get isAiSearchActive => _aiSearchIds != null;

  List<Place> get filteredPlaces {
    if (_aiSearchIds != null) {
      final ids = _aiSearchIds!;
      return ids
          .map((id) {
            try {
              return _allPlaces.firstWhere((p) => p.id == id);
            } catch (_) {
              return null;
            }
          })
          .whereType<Place>()
          .toList();
    }
    final f = filter;
    if (!f.isActive) return _allPlaces;
    return _allPlaces.where(f.matches).toList();
  }

  FreemiumResult get _result => _freemiumService.split(
        filteredPlaces,
        filtersActive: filtersActive,
        isPremiumUser: true,
      );

  List<Place> get visiblePlaces => _result.visiblePlaces;
  List<Place> get lockedPlaces => _result.lockedPlaces;
  bool get hasLockedPlaces => _result.hasLocked;

  void setType(PlaceType? type) { _type = type; notifyListeners(); }
  void setMinRating(double? value) { _minRating = value; notifyListeners(); }
  void setMaxPriceLevel(int? value) { _maxPriceLevel = value; notifyListeners(); }
  void setMinAveragePrice(int? value) { _minAveragePrice = value; notifyListeners(); }
  void setMaxAveragePrice(int? value) { _maxAveragePrice = value; notifyListeners(); }

  void toggleAmbiance(String tag) => _toggle(_ambiance, tag);
  void toggleMusic(String tag) => _toggle(_music, tag);
  void toggleStyle(String tag) => _toggle(_style, tag);
  void toggleCuisine(String tag) => _toggle(_cuisine, tag);
  void toggleCrowd(String tag) => _toggle(_crowd, tag);
  void togglePeak(String tag) => _toggle(_peak, tag);
  void toggleOpeningHours(String tag) => _toggle(_openingHours, tag);

  bool isAmbianceSelected(String tag) => _ambiance.contains(tag);
  bool isMusicSelected(String tag) => _music.contains(tag);
  bool isStyleSelected(String tag) => _style.contains(tag);
  bool isCuisineSelected(String tag) => _cuisine.contains(tag);
  bool isCrowdSelected(String tag) => _crowd.contains(tag);
  bool isPeakSelected(String tag) => _peak.contains(tag);
  bool isOpeningHoursSelected(String tag) => _openingHours.contains(tag);

  void _toggle(Set<String> set, String tag) {
    if (!set.add(tag)) set.remove(tag);
    notifyListeners();
  }

  /// Active la Recherche IA avec les IDs retournés par Claude.
  void setAiSearchResults(List<String> ids) {
    _aiSearchIds = ids;
    notifyListeners();
  }

  /// Revient au mode filtres classiques.
  void clearAiSearch() {
    _aiSearchIds = null;
    notifyListeners();
  }

  void clearFilters() {
    _type = null;
    _minRating = null;
    _maxPriceLevel = null;
    _minAveragePrice = null;
    _maxAveragePrice = null;
    _ambiance.clear();
    _music.clear();
    _style.clear();
    _cuisine.clear();
    _crowd.clear();
    _peak.clear();
    _openingHours.clear();
    _openNow = false;
    _aiSearchIds = null;
    notifyListeners();
  }

  Place? placeById(String id) {
    for (final p in _allPlaces) {
      if (p.id == id) return p;
    }
    return null;
  }
}
