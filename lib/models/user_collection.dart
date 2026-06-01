import 'package:flutter/foundation.dart';
import 'collection_style.dart';
import 'place.dart';

/// Collection d'adresses appartenant a un utilisateur, partageable via un code.
/// Sert aussi bien pour la carte perso d'un utilisateur "gratuit" que pour la
/// carte publique d'un influenceur (avec handle, cover, badge verifie).
@immutable
class UserCollection {
  final String id;
  final String ownerName;
  final String code; // ex : "PARIS-CHIC-1234"
  final CollectionStyle style;
  final List<Place> places;

  // ---- Profil createur / influenceur ----
  final String? authorHandle; // ex : "@lea.inparis"
  final bool isInfluencer; // carte publique d'un createur
  final String? coverImage; // image de couverture (URL)

  const UserCollection({
    required this.id,
    required this.ownerName,
    required this.code,
    required this.style,
    required this.places,
    this.authorHandle,
    this.isInfluencer = false,
    this.coverImage,
  });

  UserCollection copyWith({
    String? id,
    String? ownerName,
    String? code,
    CollectionStyle? style,
    List<Place>? places,
    String? authorHandle,
    bool? isInfluencer,
    String? coverImage,
  }) {
    return UserCollection(
      id: id ?? this.id,
      ownerName: ownerName ?? this.ownerName,
      code: code ?? this.code,
      style: style ?? this.style,
      places: places ?? this.places,
      authorHandle: authorHandle ?? this.authorHandle,
      isInfluencer: isInfluencer ?? this.isInfluencer,
      coverImage: coverImage ?? this.coverImage,
    );
  }
}
