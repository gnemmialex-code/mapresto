import 'package:flutter/material.dart';

import '../models/place.dart';
import 'app_colors.dart';

/// Associe a chaque type de lieu une couleur et une icone, utilisees
/// par les markers, cartes et fiches.
class PlaceVisuals {
  PlaceVisuals._();

  static Color color(PlaceType type) {
    switch (type) {
      case PlaceType.bar:
        return AppColors.bar;
      case PlaceType.restaurant:
        return AppColors.restaurant;
      case PlaceType.hotel:
        return AppColors.hotel;
      case PlaceType.rooftop:
        return AppColors.rooftop;
      case PlaceType.parc:
        return AppColors.parc;
      case PlaceType.adresse:
        return AppColors.adresse;
    }
  }

  static IconData icon(PlaceType type) {
    switch (type) {
      case PlaceType.bar:
        return Icons.local_bar;
      case PlaceType.restaurant:
        return Icons.restaurant;
      case PlaceType.hotel:
        return Icons.hotel;
      case PlaceType.rooftop:
        return Icons.deck;
      case PlaceType.parc:
        return Icons.park;
      case PlaceType.adresse:
        return Icons.photo_camera;
    }
  }
}
