import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place.dart';

/// Conciergerie : met l'utilisateur en relation directe avec vous via
/// WhatsApp Business (reservation, renseignements, recommandations...).
///
/// >>> A CONFIGURER <<<
/// Renseignez votre numero WhatsApp Business au format international SANS
/// le "+" ni espaces (ex: France 06 12 34 56 78 -> "33612345678").
/// Vous pouvez aussi le passer au build :
///   flutter run --dart-define=WHATSAPP_NUMBER=33612345678
class ConciergeService {
  ConciergeService._();

  static const String whatsappNumber = String.fromEnvironment(
    'WHATSAPP_NUMBER',
    defaultValue: '33762782116', // WhatsApp Business (FR +33 7 62 78 21 16)
  );

  /// true tant que le numero par defaut (placeholder) n'a pas ete remplace.
  static bool get isConfigured => whatsappNumber != '33600000000';

  /// Ouvre WhatsApp avec un message pre-rempli. Renvoie false si l'ouverture
  /// a echoue (WhatsApp absent / lien invalide).
  static Future<bool> openWhatsApp({String? message}) async {
    final text = message ?? _defaultMessage;
    final uri = Uri.parse(
        'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(text)}');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Message d'introduction generique.
  static const String _defaultMessage =
      'Bonjour 👋 Je vous contacte depuis l\'app mapresto pour la conciergerie '
      '(réservation, renseignements, recommandations).';

  /// Message pre-rempli centre sur un lieu precis.
  static String messageForPlace(Place p) =>
      'Bonjour 👋 Je suis intéressé(e) par "${p.name}" (${p.type.label}) '
      'sur mapresto. Pouvez-vous m\'aider pour une réservation ou des '
      'renseignements ?';

  static void debugWarnIfUnconfigured() {
    if (!isConfigured && kDebugMode) {
      debugPrint(
          '⚠️ ConciergeService: numero WhatsApp non configure (placeholder). '
          'Renseignez ConciergeService.whatsappNumber.');
    }
  }
}
