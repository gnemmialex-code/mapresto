import 'package:flutter/material.dart';

/// Styles de texte reutilisables dans toute l'app.
///
/// Police : San Francisco (police systeme Apple) sur les plateformes Apple,
/// repli systeme ailleurs.
///
/// Les styles ne fixent PAS de couleur : ils heritent de la couleur du theme
/// (claire en mode sombre, sombre en mode clair). Les cas particuliers
/// (texte blanc sur fond colore) utilisent `.copyWith(color: ...)`.
class AppTypography {
  AppTypography._();

  static const String family = '.SF Pro Text';

  static const List<String> fallback = [
    'SF Pro Text',
    'SF Pro Display',
    '.AppleSystemUIFont',
    'system-ui',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
  ];

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle tag = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
