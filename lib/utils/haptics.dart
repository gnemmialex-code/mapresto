import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Retours haptiques centralises.
///
/// On passe TOUJOURS par ce helper (jamais [HapticFeedback] directement) :
/// - le web n'a pas de vibreur => on no-op pour eviter les exceptions ;
/// - on garde un vocabulaire coherent (selection / impact / succes) dans
///   toute l'app, facile a desactiver globalement plus tard.
class Haptics {
  Haptics._();

  /// Petit "tick" pour une selection (chips, toggles, onglets).
  static void selection() {
    if (kIsWeb) return;
    HapticFeedback.selectionClick();
  }

  /// Impact leger : tap sur une carte, ouverture d'une fiche, favori.
  static void light() {
    if (kIsWeb) return;
    HapticFeedback.lightImpact();
  }

  /// Impact moyen : action confirmee (itineraire lance, lieu ajoute).
  static void medium() {
    if (kIsWeb) return;
    HapticFeedback.mediumImpact();
  }

  /// Vibration courte : erreur / limite atteinte.
  static void warning() {
    if (kIsWeb) return;
    HapticFeedback.vibrate();
  }
}
