import 'package:flutter/material.dart';

/// Style visuel d'une collection (couleur, icones, nom).
@immutable
class CollectionStyle {
  final String id;
  final String name;
  final Color primaryColor;
  final String iconStyle; // "minimal", "bold", "outline"
  final String? description;

  const CollectionStyle({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.iconStyle,
    this.description,
  });

  /// Construit une couleur depuis une chaine hex ("#RRGGBB" ou "RRGGBB").
  static Color colorFromHex(String hex) {
    final clean = hex.replaceAll('#', '');
    final value = int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
    return Color(value);
  }

  String get colorHex =>
      // ignore: deprecated_member_use
      '#${primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
