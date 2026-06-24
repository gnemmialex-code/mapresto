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

  // ---- Demande de recentrage ("Voir sur la carte") ----
  // Le compteur permet de detecter une nouvelle demande meme pour le meme lieu.
  Place? _focusTarget;
  Place? get focusTarget => _focusTarget;
  int _focusTick = 0;
  int get focusTick => _focusTick;

  void selectPlace(Place place) {
    _selectedPlace = place;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPlace = null;
    notifyListeners();
  }

  /// Demande a la carte de se recentrer sur [place] (basculer sur l'onglet
  /// Carte puis animer la camera vers le lieu).
  void requestFocus(Place place) {
    _selectedPlace = place;
    _focusTarget = place;
    _focusTick++;
    notifyListeners();
  }
}
