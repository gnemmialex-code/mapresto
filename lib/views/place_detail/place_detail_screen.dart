import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/place_visuals.dart';
import '../../viewmodels/collections_view_model.dart';
import '../../viewmodels/user_reviews_view_model.dart';
import '../../viewmodels/user_tags_view_model.dart';
import '../maps/create_my_map_screen.dart';
import '../../widgets/place_photo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/tag_chip.dart';
import 'place_video_player.dart';

/// Fiche detaillee d'un lieu : photos, infos, tags, videos.
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final color = PlaceVisuals.color(place.type);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---- Carousel photos en en-tete ----
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            foregroundColor: Colors.white,
            backgroundColor: color,
            flexibleSpace: FlexibleSpaceBar(
              background: _PhotoCarousel(photos: place.photos, color: color),
            ),
          ),
          SliverToBoxAdapter(
            child: PlaceDetailContent(place: place),
          ),
        ],
      ),
    );
  }
}

/// Contenu detaille d'un lieu, reutilisable (fiche plein ecran ET feuille
/// glissante de la carte). Avec [embedded] = true on masque le bloc
/// titre/type (deja affiche par l'en-tete de la feuille) ainsi que le bloc
/// d'actions principales (deja fournies au-dessus dans la feuille).
class PlaceDetailContent extends StatelessWidget {
  const PlaceDetailContent({
    super.key,
    required this.place,
    this.embedded = false,
  });

  final Place place;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final color = PlaceVisuals.color(place.type);

    return Padding(
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!embedded) ...[
            Row(
              children: [
                Icon(PlaceVisuals.icon(place.type), color: color, size: 18),
                const SizedBox(width: 6),
                Text(place.type.label,
                    style: AppTypography.caption.copyWith(color: color)),
                const Spacer(),
                Text(place.priceLabel, style: AppTypography.subtitle),
              ],
            ),
            const SizedBox(height: 6),
            Text(place.name, style: AppTypography.title),
            const SizedBox(height: 6),
          ],

          // ---- Note ----
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.rating, size: 18),
              const SizedBox(width: 4),
              Text('${place.rating}', style: AppTypography.subtitle),
              const SizedBox(width: 6),
              Text('(${place.reviewCount} avis)', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 12),

          // ---- Prix reel ----
          Row(
            children: [
              Icon(Icons.euro, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(place.averagePriceLabel, style: AppTypography.subtitle),
            ],
          ),
          const SizedBox(height: 16),

          // ---- Liens (Maps / Instagram / Site) ----
          _LinkButtons(place: place, color: color),
          const SizedBox(height: 20),

          // ---- Galerie (photos + videos) ----
          if (place.photos.isNotEmpty || place.instagramVideos.isNotEmpty) ...[
            _GallerySection(
              photos: place.photos,
              videos: place.instagramVideos,
              color: color,
            ),
            const SizedBox(height: 20),
          ],

          // ---- Avis (reels via Google) ----
          _ReviewsSection(place: place),
          const SizedBox(height: 20),

          // ---- Ma note & mes tags (personnels) ----
          _UserAnnotations(place: place),
          const SizedBox(height: 20),

          // ---- Frequentation ----
          if (place.crowdTags.isNotEmpty) ...[
            _SectionTitle('Frequentation'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in place.crowdTags)
                  TagChip(label: t, color: AppColors.accent),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ---- Horaires d'affluence ----
          if (place.peakTags.isNotEmpty) ...[
            _SectionTitle("Horaires d'affluence"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in place.peakTags)
                  TagChip(label: t, color: AppColors.hotel),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ---- Adresse ----
          _SectionTitle('Adresse'),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.place, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(place.address, style: AppTypography.body)),
            ],
          ),
          if (!embedded) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Voir sur la carte'),
            ),
            const SizedBox(height: 12),
            // ---- Y aller (itineraire Google Maps) ----
            PrimaryButton(
              label: 'Y aller (itineraire)',
              icon: Icons.directions,
              color: color,
              onPressed: () => _launchUrl(place.directionsUrl()),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _ModeChip(
                  icon: Icons.directions_car,
                  label: 'Voiture',
                  onTap: () => _launchUrl(place.directionsUrl('driving')),
                ),
                _ModeChip(
                  icon: Icons.directions_walk,
                  label: 'A pied',
                  onTap: () => _launchUrl(place.directionsUrl('walking')),
                ),
                _ModeChip(
                  icon: Icons.directions_transit,
                  label: 'Transports',
                  onTap: () => _launchUrl(place.directionsUrl('transit')),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // ---- Tags ----
          if (place.allTags.isNotEmpty) ...[
            _SectionTitle('Ambiance & style'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in place.ambianceTags)
                  TagChip(label: t, color: AppColors.primary),
                for (final t in place.musicTags)
                  TagChip(label: t, color: AppColors.restaurant),
                for (final t in place.styleTags)
                  TagChip(label: t, color: AppColors.hotel),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // (videos maintenant intégrées dans la galerie)

          // ---- Nos videos (interviews maison) ----
          Row(
            children: [
              Icon(Icons.videocam, size: 18, color: color),
              const SizedBox(width: 6),
              _SectionTitle('Nos videos'),
            ],
          ),
          const SizedBox(height: 8),
          if (place.originalVideos.isEmpty)
            _ComingSoonVideo(color: color)
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: place.originalVideos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _VideoThumb(
                  color: color,
                  label: 'Interview',
                  onTap: () =>
                      PlaceVideoPlayer.open(context, place.originalVideos[i]),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // ---- Avis de la communaute ----
          _UserReviewSection(place: place),
          const SizedBox(height: 20),

          // ---- Ajouter a ma carte ----
          _AddToMyMapButton(place: place, color: color),
        ],
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.photos, required this.color});
  final List<String> photos;
  final Color color;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _failed = <String>{};
  int _page = 0;

  List<String> get _shown =>
      widget.photos.where((p) => !_failed.contains(p)).toList();

  void _markFailed(String url) {
    if (!mounted || _failed.contains(url)) return;
    setState(() {
      _failed.add(url);
      final count = _shown.length;
      if (_page >= count && count > 0) _page = count - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (widget.photos.isEmpty ||
        (shown.isEmpty && _failed.length == widget.photos.length)) {
      return Container(color: widget.color);
    }
    return Stack(
      children: [
        PageView(
          key: ValueKey(shown.length),
          onPageChanged: (i) => setState(() => _page = i),
          children: [
            for (final path in shown)
              _ErrorAwarePhoto(
                path: path,
                color: widget.color,
                onError: () => _markFailed(path),
              ),
          ],
        ),
        if (shown.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < shown.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _page == i ? 16 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: _page == i ? 0.95 : 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorAwarePhoto extends StatefulWidget {
  const _ErrorAwarePhoto({
    required this.path,
    required this.color,
    required this.onError,
  });
  final String path;
  final Color color;
  final VoidCallback onError;

  @override
  State<_ErrorAwarePhoto> createState() => _ErrorAwarePhotoState();
}

class _ErrorAwarePhotoState extends State<_ErrorAwarePhoto> {
  @override
  Widget build(BuildContext context) {
    if (!widget.path.startsWith('http')) {
      return Image.asset(
        widget.path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) { if (mounted) widget.onError(); });
          return const SizedBox.shrink();
        },
      );
    }
    return CachedNetworkImage(
      imageUrl: widget.path,
      fit: BoxFit.cover,
      placeholder: (_, _) =>
          Container(color: widget.color.withValues(alpha: 0.25)),
      errorWidget: (_, _, _) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) { if (mounted) widget.onError(); });
        return Container(color: widget.color.withValues(alpha: 0.15));
      },
    );
  }
}

// ── Galerie (photos + videos) ────────────────────────────────────────────────

class _GallerySection extends StatelessWidget {
  const _GallerySection({
    required this.photos,
    required this.videos,
    required this.color,
  });
  final List<String> photos;
  final List<String> videos;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_outlined, size: 18, color: color),
            const SizedBox(width: 6),
            _SectionTitle('Galerie'),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileSize = (constraints.maxWidth - 8) / 3;
            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < photos.length; i++)
                  _SmartGalleryTile(
                    url: photos[i],
                    color: color,
                    size: tileSize,
                    onTap: () => _openViewer(context, i),
                  ),
                for (final url in videos)
                  _SmartVideoTile(url: url, color: color, size: tileSize),
              ],
            );
          },
        ),
      ],
    );
  }

  void _openViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => _PhotoViewerScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _SmartGalleryTile extends StatefulWidget {
  const _SmartGalleryTile({
    required this.url,
    required this.color,
    required this.size,
    required this.onTap,
  });
  final String url;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  State<_SmartGalleryTile> createState() => _SmartGalleryTileState();
}

class _SmartGalleryTileState extends State<_SmartGalleryTile> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: widget.url,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                Container(color: widget.color.withValues(alpha: 0.3)),
            errorWidget: (_, _, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _hidden = true);
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

// ── Tuile vidéo dans la galerie ──────────────────────────────────────────────

class _SmartVideoTile extends StatefulWidget {
  const _SmartVideoTile({
    required this.url,
    required this.color,
    required this.size,
  });
  final String url;
  final Color color;
  final double size;

  @override
  State<_SmartVideoTile> createState() => _SmartVideoTileState();
}

class _SmartVideoTileState extends State<_SmartVideoTile> {
  // null = vérification en cours, true = existe, false = introuvable
  bool? _exists;

  @override
  void initState() {
    super.initState();
    _checkExists();
  }

  Future<void> _checkExists() async {
    try {
      final r = await http
          .head(Uri.parse(widget.url))
          .timeout(const Duration(seconds: 5));
      if (mounted) setState(() => _exists = r.statusCode < 400);
    } catch (_) {
      if (mounted) setState(() => _exists = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_exists == false) return const SizedBox.shrink();

    final size = widget.size;
    final color = widget.color;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: GestureDetector(
          onTap: _exists == true
              ? () => PlaceVideoPlayer.open(context, widget.url)
              : null,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _exists == null
                ? Container(color: color.withValues(alpha: 0.25))
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        color: Colors.white.withValues(alpha: 0.92),
                        size: size * 0.42,
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'VIDÉO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewerScreen extends StatefulWidget {
  const _PhotoViewerScreen({required this.photos, required this.initialIndex});
  final List<String> photos;
  final int initialIndex;

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late int _current;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: PlacePhoto(
              path: widget.photos[i],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoThumb extends StatelessWidget {
  const _VideoThumb({required this.color, required this.onTap, this.label});
  final Color color;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            const Center(
              child:
                  Icon(Icons.play_circle_fill, color: Colors.white, size: 44),
            ),
            if (label != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: Text(label!,
                    style: AppTypography.tag.copyWith(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Carte "interview a venir" pour la section Nos videos.
class _ComingSoonVideo extends StatelessWidget {
  const _ComingSoonVideo({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.movie_creation_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interview a venir', style: AppTypography.subtitle),
                const SizedBox(height: 2),
                Text(
                  'Notre equipe tournera bientot une video exclusive de ce lieu.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Boutons de liens externes (Google Maps, Instagram, site web).
class _LinkButtons extends StatelessWidget {
  const _LinkButtons({required this.place, required this.color});
  final Place place;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (place.mapsUrl != null)
        _LinkChip(
          icon: Icons.map,
          label: 'Maps',
          color: const Color(0xFF1A73E8),
          onTap: () => _launchUrl(place.mapsUrl!),
        ),
      if (place.instagramUrl != null)
        _LinkChip(
          icon: Icons.camera_alt,
          label: 'Instagram',
          color: const Color(0xFFE1306C),
          onTap: () => _launchUrl(place.instagramUrl!),
        ),
      if (place.websiteUrl != null)
        _LinkChip(
          icon: Icons.language,
          label: 'Site web',
          color: color,
          onTap: () => _launchUrl(place.websiteUrl!),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Liens'),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: buttons),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: AppTypography.body
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Section avis Google : 5 cartes style Google, toujours visibles directement.
class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final reviews = place.reviews.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4285F4),
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SectionTitle('Avis Google'),
            const Spacer(),
            const Icon(Icons.star, color: AppColors.rating, size: 16),
            const SizedBox(width: 3),
            Text('${place.rating}', style: AppTypography.subtitle),
            Text(' · ${place.reviewCount}', style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: 10),
        if (reviews.isEmpty) ...[
          Text(
            'Consultez les avis directement sur Google.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 8),
          if (place.mapsUrl != null)
            OutlinedButton.icon(
              onPressed: () => _launchUrl(place.mapsUrl!),
              icon: const Icon(Icons.reviews_outlined, size: 18),
              label: const Text('Voir les avis (Google)'),
            ),
        ] else ...[
          for (final r in reviews) _GoogleReviewCard(review: r),
          if (place.mapsUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: OutlinedButton.icon(
                onPressed: () => _launchUrl(place.mapsUrl!),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Tous les avis sur Google Maps'),
              ),
            ),
        ],
      ],
    );
  }
}

class _GoogleReviewCard extends StatelessWidget {
  const _GoogleReviewCard({required this.review});
  final Review review;

  static const _kAvatarColors = [
    Color(0xFF4285F4),
    Color(0xFF34A853),
    Color(0xFFEA4335),
    Color(0xFF9C27B0),
    Color(0xFF00ACC1),
    Color(0xFFFF7043),
  ];

  static Color _avatarColor(String name) =>
      _kAvatarColors[name.codeUnitAt(0) % _kAvatarColors.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _avatarColor(review.author),
                child: Text(
                  review.author.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.author, style: AppTypography.subtitle),
                    Text(review.relativeTime, style: AppTypography.caption),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'G',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.rating ? Icons.star : Icons.star_border,
                  size: 13,
                  color: AppColors.rating,
                ),
              const SizedBox(width: 6),
              Text(
                '${review.rating.toInt()}/5',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(review.text, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.subtitle);
  }
}

/// Note et tags PERSONNELS de l'utilisateur sur le lieu.
class _UserAnnotations extends StatefulWidget {
  const _UserAnnotations({required this.place});
  final Place place;

  @override
  State<_UserAnnotations> createState() => _UserAnnotationsState();
}

class _UserAnnotationsState extends State<_UserAnnotations> {
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(UserTagsViewModel vm) {
    vm.addTag(widget.place.id, _tagController.text);
    _tagController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserTagsViewModel>();
    final id = widget.place.id;
    final rating = vm.ratingFor(id);
    final tags = vm.tagsFor(id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle('Ma note & mes tags'),
            const Spacer(),
            if (rating != null)
              TextButton(
                onPressed: () => vm.clearRating(id),
                child: const Text('Effacer'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        // Note perso (1 a 5 etoiles).
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              GestureDetector(
                onTap: () => vm.setRating(id, i.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    (rating ?? 0) >= i ? Icons.star : Icons.star_border,
                    color: AppColors.rating,
                    size: 30,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              rating != null ? '${rating.toStringAsFixed(0)}/5' : 'Pas note',
              style: AppTypography.caption,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tags persos.
        if (tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                Chip(
                  label: Text(t),
                  labelStyle: AppTypography.tag
                      .copyWith(color: AppColors.primary),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                  deleteIconColor: AppColors.primary,
                  onDeleted: () => vm.removeTag(id, t),
                ),
            ],
          ),
        const SizedBox(height: 8),
        // Ajout d'un tag.
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTag(vm),
                decoration: const InputDecoration(
                  hintText: 'Ajouter un tag (ex: "date", "vue", "calme")',
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _addTag(vm),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

/// Petit bouton de choix du mode de trajet.
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

/// Section avis de la communaute : affiche les avis soumis + bouton pour en laisser un.
class _UserReviewSection extends StatelessWidget {
  const _UserReviewSection({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserReviewsViewModel>();
    final reviews = vm.reviewsFor(place.id);
    final color = PlaceVisuals.color(place.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle('Avis de la communaute'),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Laisser mon avis'),
            ),
          ],
        ),
        if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Soyez le premier a donner votre avis sur ce lieu.',
              style: AppTypography.caption,
            ),
          )
        else
          for (final r in reviews)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(r.author, style: AppTypography.subtitle),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            for (var i = 1; i <= 5; i++)
                              Icon(
                                i <= r.rating ? Icons.star : Icons.star_border,
                                size: 13,
                                color: AppColors.rating,
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${r.date.day}/${r.date.month}/${r.date.year}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(r.text, style: AppTypography.body),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  void _openForm(BuildContext context) {
    final reviewsVm = context.read<UserReviewsViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReviewFormSheet(
        place: place,
        onSubmit: (rating, text) => reviewsVm.addReview(
          place.id,
          UserReview(rating: rating, text: text, date: DateTime.now()),
        ),
      ),
    );
  }
}

class _ReviewFormSheet extends StatefulWidget {
  const _ReviewFormSheet({required this.place, required this.onSubmit});
  final Place place;
  final void Function(double rating, String text) onSubmit;

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  double _rating = 0;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = PlaceVisuals.color(widget.place.type);
    final canSubmit = _rating > 0 && _ctrl.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Votre avis sur ${widget.place.name}',
              style: AppTypography.title),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _rating = i.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      _rating >= i ? Icons.star : Icons.star_border,
                      color: AppColors.rating,
                      size: 38,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Decrivez votre experience...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canSubmit
                  ? () {
                      widget.onSubmit(_rating, _ctrl.text.trim());
                      Navigator.pop(context);
                    }
                  : null,
              icon: const Icon(Icons.send),
              label: const Text('Envoyer mon avis'),
              style: FilledButton.styleFrom(backgroundColor: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton "Ajouter / Retirer de ma carte" branche sur CollectionsViewModel.
class _AddToMyMapButton extends StatelessWidget {
  const _AddToMyMapButton({required this.place, required this.color});
  final Place place;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();
    final isAdded = vm.isInMyMap(place);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _toggle(context, vm, isAdded),
          icon: Icon(isAdded ? Icons.bookmark_added : Icons.bookmark_add),
          label: Text(isAdded ? 'Dans ma carte  ✓' : 'Ajouter à ma carte'),
          style: FilledButton.styleFrom(
            backgroundColor: isAdded ? Colors.green.shade600 : color,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (isAdded) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateMyMapScreen()),
            ),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Voir dans ma carte'),
          ),
        ],
      ],
    );
  }

  void _toggle(BuildContext context, CollectionsViewModel vm, bool isAdded) {
    if (isAdded) {
      vm.removeFromMyMap(place);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${place.name}" retire de ma carte.')),
      );
    } else {
      final added = vm.addToMyMap(place);
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Limite atteinte. Passez au plan Createur pour ajouter plus de lieux.'),
            action: SnackBarAction(
              label: 'Voir',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateMyMapScreen()),
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${place.name}" ajoute a ma carte !'),
            action: SnackBarAction(
              label: 'Ma carte',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateMyMapScreen()),
              ),
            ),
          ),
        );
      }
    }
  }
}

/// Ouvre une URL externe (nouvel onglet sur web, app native sinon).
Future<void> _launchUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
