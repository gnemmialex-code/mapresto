import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/place_visuals.dart';
import '../../viewmodels/user_tags_view_model.dart';
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

          // ---- Videos Instagram ----
          if (place.instagramVideos.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.camera_alt, size: 18, color: Color(0xFFE1306C)),
                const SizedBox(width: 6),
                _SectionTitle('Videos Instagram'),
                const Spacer(),
                if (place.instagramUrl != null)
                  TextButton(
                    onPressed: () => _launchUrl(place.instagramUrl!),
                    child: const Text('Voir le compte'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: place.instagramVideos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _VideoThumb(
                  color: const Color(0xFFE1306C),
                  label: 'Instagram',
                  onTap: () =>
                      PlaceVideoPlayer.open(context, place.instagramVideos[i]),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

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

          // ---- Action collection ----
          PrimaryButton(
            label: 'Ajouter a ma collection',
            icon: Icons.bookmark_add,
            color: color,
            onPressed: () {
              // TODO: brancher l'ajout reel a une collection.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${place.name}" ajoute (mock).')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PhotoCarousel extends StatelessWidget {
  const _PhotoCarousel({required this.photos, required this.color});
  final List<String> photos;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(color: color);
    }
    return PageView(
      children: [
        for (final url in photos)
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.background),
            errorWidget: (_, _, _) => Container(color: color),
          ),
      ],
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

/// Section avis : note agregee + acces aux avis REELS Google.
/// Si `place.reviews` est rempli (API branchee), on les liste ; sinon on
/// renvoie vers Google Maps (on n'invente pas d'avis).
class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle('Avis'),
            const Spacer(),
            const Icon(Icons.star, color: AppColors.rating, size: 18),
            const SizedBox(width: 4),
            Text('${place.rating}', style: AppTypography.subtitle),
            Text(' · ${place.reviewCount} avis', style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: 8),
        if (place.reviews.isEmpty) ...[
          // Pas d'avis fabriques : on pointe vers les avis Google reels.
          Text(
            'Avis verifies via Google. Consultez-les directement a la source.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 8),
          if (place.mapsUrl != null)
            OutlinedButton.icon(
              onPressed: () => _launchUrl(place.mapsUrl!),
              icon: const Icon(Icons.reviews_outlined, size: 18),
              label: const Text('Voir les vrais avis (Google)'),
            ),
        ] else
          for (final r in place.reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(r.author, style: AppTypography.subtitle),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: AppColors.rating, size: 14),
                      Text(' ${r.rating}', style: AppTypography.caption),
                      const Spacer(),
                      Text(r.relativeTime, style: AppTypography.caption),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(r.text, style: AppTypography.body),
                ],
              ),
            ),
      ],
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

/// Ouvre une URL externe (nouvel onglet sur web, app native sinon).
Future<void> _launchUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
