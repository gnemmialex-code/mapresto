import 'place.dart';

/// Proposition d'adresse soumise depuis "Ajouter une adresse".
/// Recue dans la table Supabase `address_submissions` (statut "pending")
/// pour verification avant mise en ligne.
class AddressSubmission {
  final String name;
  final String address;
  final String description;
  final PlaceType type;
  final String? website;
  final String? instagram;
  final String? submitterEmail;
  final List<String> photoUrls;

  const AddressSubmission({
    required this.name,
    required this.address,
    required this.description,
    required this.type,
    this.website,
    this.instagram,
    this.submitterEmail,
    this.photoUrls = const [],
  });

  Map<String, dynamic> toRow() => {
        'name': name,
        'address': address,
        'description': description,
        'type': type.name,
        'website': _orNull(website),
        'instagram': _orNull(instagram),
        'submitter_email': _orNull(submitterEmail),
        'photo_urls': photoUrls,
      };

  /// Corps d'email de repli si Supabase est indisponible.
  String toEmailBody() => [
        'Nouvelle adresse proposee :',
        '',
        'Nom         : $name',
        'Type        : ${type.label}',
        'Adresse     : $address',
        'Description : $description',
        'Site web    : ${website?.isNotEmpty == true ? website : '-'}',
        'Instagram   : ${instagram?.isNotEmpty == true ? instagram : '-'}',
        'Propose par : ${submitterEmail?.isNotEmpty == true ? submitterEmail : 'anonyme'}',
        '',
        '(Photos non jointes — envoyees uniquement via Supabase.)',
        '(Envoye depuis ParisMap Video Guide)',
      ].join('\n');
}

/// Avis soumis depuis "Donner mon avis".
/// Recu dans la table Supabase `review_submissions` (statut "pending").
class ReviewSubmission {
  final String? placeId; // null si lieu propose (pas encore en ligne)
  final String placeName;
  final bool isNewPlace;
  final String? newPlaceAddress;
  final int rating; // 1 a 5
  final String comment;
  final String? submitterName;
  final String? submitterEmail;
  final List<String> photoUrls;

  const ReviewSubmission({
    required this.placeName,
    required this.rating,
    required this.comment,
    this.placeId,
    this.isNewPlace = false,
    this.newPlaceAddress,
    this.submitterName,
    this.submitterEmail,
    this.photoUrls = const [],
  });

  Map<String, dynamic> toRow() => {
        'place_id': placeId,
        'place_name': placeName,
        'is_new_place': isNewPlace,
        'new_place_address': _orNull(newPlaceAddress),
        'rating': rating,
        'comment': comment,
        'submitter_name': _orNull(submitterName),
        'submitter_email': _orNull(submitterEmail),
        'photo_urls': photoUrls,
      };

  String toEmailBody() => [
        'Nouvel avis :',
        '',
        'Lieu        : $placeName${isNewPlace ? ' (nouveau lieu propose)' : ''}',
        if (isNewPlace)
          'Adresse     : ${newPlaceAddress?.isNotEmpty == true ? newPlaceAddress : '-'}',
        'Note        : $rating/5',
        'Commentaire : $comment',
        'Auteur      : ${submitterName?.isNotEmpty == true ? submitterName : 'anonyme'}'
            '${submitterEmail?.isNotEmpty == true ? ' ($submitterEmail)' : ''}',
        '',
        '(Photos non jointes — envoyees uniquement via Supabase.)',
        '(Envoye depuis ParisMap Video Guide)',
      ].join('\n');
}

String? _orNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
