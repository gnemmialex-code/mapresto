import 'package:url_launcher/url_launcher.dart';

import '../models/place_suggestion.dart';

/// Envoie les suggestions de lieux manquants.
///
/// Par defaut : ouvre le client mail de l'utilisateur avec un message
/// preremple adresse a l'equipe (aucun backend requis).
///
/// >>> POINT DE BRANCHEMENT EMAIL AUTOMATIQUE <<<
/// Pour un envoi 100% automatique (sans client mail), renseigner [formEndpoint]
/// avec une URL de service de formulaire (ex: Formspree https://formspree.io/f/xxxx
/// ou EmailJS) et poster `suggestion.toJson()` en HTTP (package `http`).
/// Le service enverra alors directement l'email a l'equipe.
class SuggestionService {
  /// Adresse qui recevra les suggestions.
  static const String ownerEmail = 'gnemmialex@gmail.com';

  /// Endpoint d'envoi automatique (null = on utilise le client mail).
  static const String? formEndpoint = null;

  /// Soumet une suggestion. Renvoie true si l'action a pu etre declenchee.
  Future<bool> submit(PlaceSuggestion suggestion) async {
    // (Quand formEndpoint sera defini : faire un POST ici et renvoyer le statut.)
    final subject = 'Lieu a ajouter : ${suggestion.name}';
    final uri = Uri.parse(
      'mailto:$ownerEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(suggestion.toEmailBody())}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
