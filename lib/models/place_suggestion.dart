import 'place.dart';

/// Suggestion d'un lieu manquant, envoyee a l'equipe pour ajout sur la carte.
class PlaceSuggestion {
  final String name;
  final PlaceType type;
  final String address;
  final String? website;
  final String? instagram;
  final String? comment;
  final String? submitterEmail;

  const PlaceSuggestion({
    required this.name,
    required this.type,
    required this.address,
    this.website,
    this.instagram,
    this.comment,
    this.submitterEmail,
  });

  /// Corps de l'email (lisible) recapitulant la suggestion.
  String toEmailBody() {
    final lines = [
      'Nouveau lieu a ajouter sur la carte :',
      '',
      'Nom        : $name',
      'Type       : ${type.label}',
      'Adresse    : $address',
      'Site web   : ${website?.isNotEmpty == true ? website : '-'}',
      'Instagram  : ${instagram?.isNotEmpty == true ? instagram : '-'}',
      'Commentaire: ${comment?.isNotEmpty == true ? comment : '-'}',
      'Propose par: ${submitterEmail?.isNotEmpty == true ? submitterEmail : 'anonyme'}',
      '',
      '(Envoye depuis ParisMap Video Guide)',
    ];
    return lines.join('\n');
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'address': address,
        'website': website,
        'instagram': instagram,
        'comment': comment,
        'submitterEmail': submitterEmail,
      };
}
