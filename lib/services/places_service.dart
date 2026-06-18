import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/place.dart';
import 'mock_data_service.dart';

/// Charge les lieux depuis Supabase ou, en repli, depuis MockDataService.
/// Dans les deux cas les lieux sont enrichis (crowd, peak, cuisine, horaires).
class PlacesService {
  // Bucket Supabase Storage public : "place-photos"
  // Structure : place-photos/{uuid}/1.jpg, /2.jpg, ...
  static const int _maxPhotos = 8;
  // ── Vidéos démo (utilisées si aucune vraie vidéo n'est définie) ─────────────
  static const _videoA =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
  static const _videoB =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  // ── VIDÉOS PAR LIEU ──────────────────────────────────────────────────────────
  //
  // Ajoutez vos URLs de vidéos MP4 ici.
  // Clé   = ID du lieu (ex: 'p01')
  // Valeur = liste d'URLs MP4 (URL distante ou chemin assets/places/...)
  //
  // Ces vidéos apparaissent dans :
  //   • L'onglet "Vidéos" (feed vertical façon TikTok) — seule la 1re est utilisée
  //   • La fiche du lieu > section "Videos Instagram"
  //
  // Pour ajouter un fichier LOCAL : déposez-le dans assets/places/ et utilisez
  //   le chemin  'assets/places/nom_du_fichier.mp4'
  //
  // Pour une URL DISTANTE (Supabase, CDN…) : collez l'URL publique directement.
  //
  // ─── EXEMPLES ────────────────────────────────────────────────────────────────
  // 'p01': ['https://votre-cdn.com/perchoir-marais.mp4'],
  // 'p02': [
  //   'https://votre-cdn.com/little-red-door-cocktail.mp4',
  //   'https://votre-cdn.com/little-red-door-ambiance.mp4',
  // ],
  // 'p17': ['assets/places/septime_interview.mp4'],
  // ─────────────────────────────────────────────────────────────────────────────
  static const Map<String, List<String>> _videoMap = {
    // ← Ajoutez vos entrées ici (override manuel, prioritaire sur Supabase) :
    // 'p01': ['https://...'],
  };

  // ── Auto-détection Supabase Storage ──────────────────────────────────────────
  //
  // Deux formats acceptés dans le bucket "place-videos" (public) :
  //
  //   FORMAT DOSSIER (recommandé) :
  //     p01/1.mp4, p01/2.mp4, p01/3.mp4
  //
  //   FORMAT PLAT (legacy) :
  //     p01_1.mp4, p01_2.mp4, p01_3.mp4
  //
  // La 1ʳᵉ vidéo de chaque lieu apparaît dans l'onglet Vidéos (feed TikTok).
  // Toutes les vidéos d'un lieu apparaissent dans sa fiche > Galerie.
  // ─────────────────────────────────────────────────────────────────────────────

  // Nombre max de slots vidéo générés par lieu (format dossier).
  static const int _maxVideosPerFolder = 3;

  Future<Map<String, List<String>>> _buildStorageVideoMap() async {
    if (!Config.isSupabaseConfigured) return {};
    try {
      final root = await Supabase.instance.client.storage
          .from('place-videos')
          .list();
      final map = <String, List<String>>{};
      for (final item in root) {
        // Format plat : p01_1.mp4
        final flat = RegExp(r'^(p\d+)_(\d+)\.mp4$').firstMatch(item.name);
        if (flat != null) {
          final id = flat.group(1)!;
          final url = '${Config.supabaseUrl}'
              '/storage/v1/object/public/place-videos/${item.name}';
          map.putIfAbsent(id, () => []).add(url);
          continue;
        }
        // Format dossier : p01 (entrée virtuelle renvoyée par Supabase Storage)
        // → génère les slots 1..N ; les slots inexistants seront filtrés
        //   par _SmartVideoTile (GET Range) côté galerie et par le player dans le feed.
        final folder = RegExp(r'^(p\d+)/?$').firstMatch(item.name);
        if (folder != null) {
          final id = folder.group(1)!;
          map[id] = [
            for (var i = 1; i <= _maxVideosPerFolder; i++)
              '${Config.supabaseUrl}'
              '/storage/v1/object/public/place-videos/$id/$i.mp4',
          ];
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  static String _storageUrl(String placeId, int index) =>
      '${Config.supabaseUrl}'
      '/storage/v1/object/public/place-photos/$placeId/$index.jpg';

  static List<String> _photosForPlace(String placeId) => [
        for (var i = 1; i <= _maxPhotos; i++) _storageUrl(placeId, i),
      ];

  // Génère les slots vidéo Supabase de façon optimiste (comme pour les photos).
  // Les slots inexistants sont filtrés par _SmartVideoTile (galerie)
  // et par VideoFeedScreen (feed) via GET Range asynchrone.
  static List<String> _autoVideoUrls(String placeId) => [
        for (var i = 1; i <= _maxVideosPerFolder; i++)
          '${Config.supabaseUrl}'
          '/storage/v1/object/public/place-videos/$placeId/$i.mp4',
      ];

  // Mots-clés cuisine extraits des styleTags lors de l'enrichissement.
  static const _cuisineKeywords = {
    'bistrot', 'brasserie', 'gastronomique', 'brunch', 'italien', 'pizza',
    'japonais', 'libanais', 'indien', 'thai', 'vietnamien', 'coréen',
    'mexicain', 'burger', 'vegan', 'fruits de mer', 'steakhouse', 'crêperie',
    'street food', 'tapas',
  };

  Future<List<Place>> getPlaces() async {
    final storageVideos = await _buildStorageVideoMap();

    if (!Config.isSupabaseConfigured) {
      return MockDataService().getPlaces()
          .map((p) => _enrich(p, storageVideos: storageVideos))
          .toList();
    }
    try {
      final data = await Supabase.instance.client
          .from('places')
          .select()
          .order('name', ascending: true);
      return (data as List<dynamic>)
          .map((row) => _fromRow(row as Map<String, dynamic>))
          .map((p) => _enrich(p, storageVideos: storageVideos))
          .toList();
    } catch (_) {
      return MockDataService().getPlaces()
          .map((p) => _enrich(p, storageVideos: storageVideos))
          .toList();
    }
  }

  Place _fromRow(Map<String, dynamic> r) => Place(
        id: r['id'] as String,
        name: r['name'] as String,
        type: PlaceTypeX.fromString(r['type'] as String),
        latitude: (r['latitude'] as num).toDouble(),
        longitude: (r['longitude'] as num).toDouble(),
        address: r['address'] as String,
        rating: (r['rating'] as num).toDouble(),
        reviewCount: (r['review_count'] as num).toInt(),
        priceLevel: (r['price_level'] as num).toInt(),
        ambianceTags: List<String>.from(r['ambiance_tags'] ?? const []),
        musicTags: List<String>.from(r['music_tags'] ?? const []),
        styleTags: List<String>.from(r['style_tags'] ?? const []),
        cuisineTags: List<String>.from(r['cuisine_tags'] ?? const []),
        isPremium: r['is_premium'] as bool? ?? false,
        averagePrice: (r['average_price_per_person'] as num?)?.toInt() ?? 0,
        openingHours: List<String>.from(r['opening_hours'] ?? const []),
        websiteUrl: r['website_url'] as String?,
      );

  Place _enrich(Place p, {Map<String, List<String>> storageVideos = const {}}) {
    // Ambiance : ajouter 'calme' si lieu intime et non festif.
    final ambiance = [...p.ambianceTags];
    if ((ambiance.contains('intimiste') || ambiance.contains('cosy')) &&
        !ambiance.contains('festif') &&
        !ambiance.contains('animé')) {
      ambiance.add('calme');
    }

    // Style : séparer venue-style et cuisine depuis styleTags.
    final cuisineTags = <String>{
      ...p.styleTags.where(_cuisineKeywords.contains),
      ...p.cuisineTags,
    }.toList();
    final style = p.styleTags
        .where((t) => !_cuisineKeywords.contains(t))
        .toList();
    if (p.priceLevel >= 4 || style.contains('palace') || p.isPremium) {
      if (!style.contains('luxueux')) style.add('luxueux');
    }

    // Crowd, peak et horaires dérivés à partir du lieu ORIGINAL
    // (styleTags encore mixtes à ce stade, donc cuisine visible pour dérivation).
    final crowdTags = _crowd(p);
    final peakTags = _peak(p);
    final openingHours = p.openingHours.isEmpty ? _openingHours(p) : p.openingHours;

    // Prix moyen : utiliser la valeur Supabase si non nulle, sinon dériver.
    final avgPrice = p.averagePrice > 0 ? p.averagePrice : _averagePrice(p);

    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query='
        '${Uri.encodeComponent('${p.name} ${p.address}')}';
    final slug = p.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final instagramUrl = 'https://www.instagram.com/explore/tags/$slug/';

    return Place(
      id: p.id,
      name: p.name,
      type: p.type,
      latitude: p.latitude,
      longitude: p.longitude,
      address: p.address,
      rating: p.rating,
      reviewCount: p.reviewCount,
      priceLevel: p.priceLevel,
      ambianceTags: ambiance,
      musicTags: p.musicTags,
      styleTags: style,
      cuisineTags: cuisineTags,
      photos: _photosForPlace(p.id),
      videos: const [],
      isPremium: p.isPremium,
      averagePrice: avgPrice,
      crowdTags: crowdTags,
      peakTags: peakTags,
      openingHours: openingHours,
      mapsUrl: mapsUrl,
      instagramUrl: instagramUrl,
      websiteUrl: p.websiteUrl,
      instagramVideos: storageVideos.containsKey(p.id)
          ? storageVideos[p.id]!          // Supabase list() a détecté ce lieu
          : _videoMap.containsKey(p.id)
              ? _videoMap[p.id]!          // Override manuel _videoMap
              : Config.isSupabaseConfigured
                  ? _autoVideoUrls(p.id)  // Optimiste : on tente, le player filtre
                  : [p.id.hashCode.isEven ? _videoA : _videoB], // Mode mock
      originalVideos: const [],
      reviews: const [],
    );
  }

  int _averagePrice(Place p) {
    const barTiers     = [15, 25, 45, 70];
    const restoTiers   = [20, 35, 60, 110];
    const hotelTiers   = [90, 150, 250, 430];
    const rooftopTiers = [15, 25, 45, 70];
    const parcTiers    = [0, 5, 12, 20];
    const adresseTiers = [0, 0, 0, 0];
    final tiers = switch (p.type) {
      PlaceType.bar      => barTiers,
      PlaceType.restaurant => restoTiers,
      PlaceType.hotel    => hotelTiers,
      PlaceType.rooftop  => rooftopTiers,
      PlaceType.parc     => parcTiers,
      PlaceType.adresse  => adresseTiers,
    };
    final base = tiers[(p.priceLevel - 1).clamp(0, 3)];
    if (base == 0) return 0;
    return base + p.id.hashCode.abs() % 11;
  }

  List<String> _crowd(Place p) {
    final s = <String>{};
    final a = p.ambianceTags;
    final st = p.styleTags;
    if (st.contains('club') || a.contains('festif') || a.contains('animé')) {
      s.addAll(['20-30 ans', 'étudiants']);
    }
    if (a.contains('business') ||
        st.contains('gastronomique') ||
        st.contains('palace')) {
      s.add('business');
    }
    if (st.contains('vue Tour Eiffel') ||
        st.contains('palace') ||
        st.contains('rooftop') ||
        p.isPremium) {
      s.add('touristes');
    }
    if (a.contains('familial')) s.add('familles');
    if (a.contains('cosy') ||
        a.contains('intimiste') ||
        st.contains('bistrot') ||
        st.contains('vins nature')) {
      s.add('locaux');
    }
    if (st.contains('cocktails') ||
        a.contains('branché') ||
        a.contains('chic')) {
      s.addAll(['after-work', '30-45 ans']);
    }
    if (p.type == PlaceType.parc || p.type == PlaceType.adresse) {
      s.add('familles');
      if (p.rating >= 4.5 ||
          st.contains('vue Tour Eiffel') ||
          st.contains('instagrammable')) {
        s.add('touristes');
      }
    }
    if (s.isEmpty) s.add('locaux');
    return s.toList();
  }

  List<String> _peak(Place p) {
    final s = <String>{};
    switch (p.type) {
      case PlaceType.bar:
        s.addAll(['after-work', 'soir', 'week-end']);
        if (p.styleTags.contains('club') || p.ambianceTags.contains('festif')) {
          s.add('nuit');
        }
        break;
      case PlaceType.restaurant:
        s.addAll(['midi', 'soir']);
        if (p.styleTags.contains('brunch')) s.addAll(['matin', 'week-end']);
        break;
      case PlaceType.hotel:
        s.addAll(['soir', 'nuit', 'week-end']);
        break;
      case PlaceType.rooftop:
        s.addAll(['after-work', 'soir', 'week-end']);
        if (p.ambianceTags.contains('festif')) s.add('nuit');
        break;
      case PlaceType.parc:
        s.addAll(['matin', 'après-midi', 'week-end']);
        if (p.ambianceTags.contains('animé')) s.add('soir');
        break;
      case PlaceType.adresse:
        s.addAll(['matin', 'après-midi', 'week-end']);
        break;
    }
    if (p.styleTags.contains('terrasse') || p.styleTags.contains('jardin')) {
      s.add('après-midi');
    }
    return s.toList();
  }

  List<String> _openingHours(Place p) {
    switch (p.type) {
      case PlaceType.restaurant:
        final hasBrunch = p.styleTags.contains('brunch');
        if (hasBrunch) return ['Matin + Midi', 'Midi + Soir', 'Week-end uniquement'];
        return ['Midi + Soir'];
      case PlaceType.bar:
        final isClub = p.styleTags.contains('club') ||
            p.ambianceTags.contains('festif');
        if (isClub) return ['Soir + Nuit', 'Week-end uniquement'];
        return ['Soir uniquement', 'Week-end uniquement'];
      case PlaceType.hotel:
        return ['Toute la journée'];
      case PlaceType.rooftop:
        return ['Soir uniquement', 'Week-end uniquement'];
      case PlaceType.parc:
      case PlaceType.adresse:
        return ['Toute la journée', 'Matin + Midi', 'Midi + Soir'];
    }
  }
}
