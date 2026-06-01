import 'package:flutter/foundation.dart';

/// Avis d'un lieu.
///
/// >>> POINT DE BRANCHEMENT BACKEND <<<
/// Pour des avis REELS, remplir cette liste depuis l'API Google Places
/// (champ `reviews`) ou Tripadvisor. On n'invente JAMAIS d'avis cote app :
/// tant que l'API n'est pas branchee, la fiche renvoie vers les avis Google
/// reels via le lien Maps.
@immutable
class Review {
  final String author;
  final double rating;
  final String text;
  final String relativeTime; // ex: "il y a 2 semaines"
  final String source; // ex: "Google"

  const Review({
    required this.author,
    required this.rating,
    required this.text,
    required this.relativeTime,
    this.source = 'Google',
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        author: json['author'] as String,
        rating: (json['rating'] as num).toDouble(),
        text: json['text'] as String,
        relativeTime: json['relativeTime'] as String? ?? '',
        source: json['source'] as String? ?? 'Google',
      );

  Map<String, dynamic> toJson() => {
        'author': author,
        'rating': rating,
        'text': text,
        'relativeTime': relativeTime,
        'source': source,
      };
}

/// Type de lieu affiche sur la carte.
enum PlaceType { bar, restaurant, hotel }

extension PlaceTypeX on PlaceType {
  String get label {
    switch (this) {
      case PlaceType.bar:
        return 'Bar';
      case PlaceType.restaurant:
        return 'Restaurant';
      case PlaceType.hotel:
        return 'Hotel';
    }
  }

  static PlaceType fromString(String value) {
    return PlaceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PlaceType.bar,
    );
  }
}

/// Modele d'un lieu (bar / restaurant / hotel).
///
/// `fromJson` / `toJson` sont prets pour brancher une API REST plus tard :
/// il suffira de remplacer MockDataService par un vrai client HTTP qui
/// renvoie ces memes objets.
@immutable
class Place {
  final String id;
  final String name;
  final PlaceType type;
  final double latitude;
  final double longitude;
  final String address;
  final double rating;
  final int reviewCount;
  final int priceLevel; // 1 a 4
  final List<String> ambianceTags;
  final List<String> musicTags;
  final List<String> styleTags;
  final List<String> photos; // URLs ou assets
  final List<String> videos; // URLs ou assets
  final bool isPremium;

  // ---- Donnees enrichies (filtres avances) ----
  /// Prix moyen reel en euros (par personne ; par nuit pour un hotel).
  final int averagePrice;

  /// Frequentation / clientele type (ex: "20-30 ans", "business", "touristes").
  final List<String> crowdTags;

  /// Creneaux d'affluence reels (ex: "after-work", "soir", "nuit", "week-end").
  final List<String> peakTags;

  // ---- Liens externes ----
  final String? mapsUrl; // fiche Google Maps (avis reels, itineraire)
  final String? instagramUrl; // compte / hashtag Instagram
  final String? websiteUrl; // site officiel

  // ---- Medias ----
  /// Extraits video provenant de l'Instagram du lieu / createur.
  final List<String> instagramVideos;

  /// Nos propres videos (interviews tournees par l'equipe - a venir).
  final List<String> originalVideos;

  /// Avis reels (vides tant que l'API Places n'est pas branchee).
  final List<Review> reviews;

  const Place({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.priceLevel,
    this.ambianceTags = const [],
    this.musicTags = const [],
    this.styleTags = const [],
    this.photos = const [],
    this.videos = const [],
    this.isPremium = false,
    this.averagePrice = 0,
    this.crowdTags = const [],
    this.peakTags = const [],
    this.mapsUrl,
    this.instagramUrl,
    this.websiteUrl,
    this.instagramVideos = const [],
    this.originalVideos = const [],
    this.reviews = const [],
  });

  /// Representation "€" a "€€€€" du niveau de prix.
  String get priceLabel => '€' * priceLevel.clamp(1, 4);

  /// Unite de prix selon le type de lieu.
  String get priceUnit => type == PlaceType.hotel ? '/ nuit' : '/ pers';

  /// Libelle du prix reel (ex: "≈ 35 € / pers").
  String get averagePriceLabel => '≈ $averagePrice € $priceUnit';

  /// Lien d'itineraire Google Maps vers ce lieu.
  /// L'origine est omise : Google Maps utilise automatiquement la position
  /// actuelle de l'utilisateur. [mode] : driving | walking | transit | bicycling.
  String directionsUrl([String mode = 'driving']) =>
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$latitude,$longitude'
      '&travelmode=$mode';

  /// Tous les tags reunis (pratique pour l'affichage compact).
  List<String> get allTags => [...ambianceTags, ...musicTags, ...styleTags];

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PlaceTypeX.fromString(json['type'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      priceLevel: json['priceLevel'] as int,
      ambianceTags: List<String>.from(json['ambianceTags'] ?? const []),
      musicTags: List<String>.from(json['musicTags'] ?? const []),
      styleTags: List<String>.from(json['styleTags'] ?? const []),
      photos: List<String>.from(json['photos'] ?? const []),
      videos: List<String>.from(json['videos'] ?? const []),
      isPremium: json['isPremium'] as bool? ?? false,
      averagePrice: json['averagePrice'] as int? ?? 0,
      crowdTags: List<String>.from(json['crowdTags'] ?? const []),
      peakTags: List<String>.from(json['peakTags'] ?? const []),
      mapsUrl: json['mapsUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      instagramVideos: List<String>.from(json['instagramVideos'] ?? const []),
      originalVideos: List<String>.from(json['originalVideos'] ?? const []),
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'rating': rating,
        'reviewCount': reviewCount,
        'priceLevel': priceLevel,
        'ambianceTags': ambianceTags,
        'musicTags': musicTags,
        'styleTags': styleTags,
        'photos': photos,
        'videos': videos,
        'isPremium': isPremium,
        'averagePrice': averagePrice,
        'crowdTags': crowdTags,
        'peakTags': peakTags,
        'mapsUrl': mapsUrl,
        'instagramUrl': instagramUrl,
        'websiteUrl': websiteUrl,
        'instagramVideos': instagramVideos,
        'originalVideos': originalVideos,
        'reviews': reviews.map((e) => e.toJson()).toList(),
      };
}
