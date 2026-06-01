import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';

/// Etat specifique a la carte : centre par defaut et lieu selectionne.
class MapViewModel extends ChangeNotifier {
  /// Centre de Paris (Notre-Dame), zoom adapte a la ville.
  static final LatLng parisCenter = LatLng(48.8566, 2.3522);
  static const double defaultZoom = 12.5;

  Place? _selectedPlace;
  Place? get selectedPlace => _selectedPlace;

  void selectPlace(Place place) {
    _selectedPlace = place;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPlace = null;
    notifyListeners();
  }
}
