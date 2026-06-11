import 'package:flutter/material.dart';

/// Palette centrale de l'application.
///
/// Les couleurs de marque sont constantes (identiques clair/sombre).
/// Les neutres (fonds, textes) dependent du mode et sont pilotes par
/// [setDark] (appele par le ThemeController au changement de theme).
class AppColors {
  AppColors._();

  static bool _dark = false;
  static void setDark(bool value) => _dark = value;
  static bool get isDark => _dark;

  // ---- Couleurs de marque (constantes) ----
  static const Color primary = Color(0xFF6C5CE7); // violet
  static const Color primaryDark = Color(0xFF4B3FB8);
  static const Color accent = Color(0xFFE0B25C); // or

  static const Color premium = Color(0xFFE0B25C);

  // Couleurs par type de lieu.
  static const Color bar = Color(0xFF8C7CFF);
  static const Color restaurant = Color(0xFFE17055);
  static const Color hotel = Color(0xFF4BA3F0);
  static const Color rooftop = Color(0xFFFD9644);
  static const Color parc = Color(0xFF26C281);
  static const Color adresse = Color(0xFFE84393);

  static const Color rating = Color(0xFFF1C40F);

  // ---- Neutres (dependent du mode clair/sombre) ----
  static Color get background =>
      _dark ? const Color(0xFF101014) : const Color(0xFFF7F7FB);
  static Color get surface =>
      _dark ? const Color(0xFF1B1B23) : const Color(0xFFFFFFFF);
  static Color get textPrimary =>
      _dark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C28);
  static Color get textSecondary =>
      _dark ? const Color(0xFF9A9AAC) : const Color(0xFF7A7A8C);

  // Voile sombre (cadenas, overlays) : sombre dans les deux modes.
  static const Color lockOverlay = Color(0xCC0E0E14);
}
