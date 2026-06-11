import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/place_visuals.dart';
import '../../widgets/place_photo.dart';
import '../../widgets/primary_button.dart';
import '../place_detail/place_detail_screen.dart';

/// Ouvre une URL externe (nouvel onglet sur web, app native sinon).
Future<void> launchExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Affiche l'apercu d'un lieu : feuille glissante (~moitie d'ecran, extensible).
void showPlaceQuickSheet(BuildContext context, Place place) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PlaceQuickSheet(place: place),
  );
}

/// Bouton rond de controle pose sur la carte.
class MapControlButton extends StatelessWidget {
  const MapControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 3,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: AppColors.primary),
        onPressed: onTap,
      ),
    );
  }
}

/// Banniere freemium (lieux Premium masques).
class LockedBanner extends StatelessWidget {
  const LockedBanner({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lockOverlay,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: AppColors.premium, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count lieu(x) Premium masques. Version gratuite : 5 lieux.',
              style: AppTypography.caption.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feuille de detail rapide d'un lieu, glissante et animee.
class PlaceQuickSheet extends StatelessWidget {
  const PlaceQuickSheet({super.key, required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final color = PlaceVisuals.color(place.type);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.32,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: AppColors.surface,
            child: ListView(
              controller: controller,
              padding: EdgeInsets.zero,
              children: [
                _Header(place: place, color: color),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: _AnimatedIn(
                    child: _Body(place: place, color: color),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// En-tete : photo + degrade teinte + poignee + nom.
class _Header extends StatelessWidget {
  const _Header({required this.place, required this.color});
  final Place place;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (place.photos.isNotEmpty)
            PlacePhoto(
              path: place.photos.first,
              fallbackColor: color,
            )
          else
            Container(color: color),
          // Degrade pour lisibilite + teinte couleur du type.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  color.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0.2, 0.6, 1],
              ),
            ),
          ),
          // Poignee de glissement.
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Nom + type.
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PlaceVisuals.icon(place.type),
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(place.type.label,
                          style:
                              AppTypography.tag.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.place, required this.color});
  final Place place;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // "Allez sur le site" : site officiel si connu, sinon recherche Google.
    final siteUrl = place.websiteUrl ??
        'https://www.google.com/search?q='
            '${Uri.encodeComponent('${place.name} Paris site officiel')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Actions : Y aller + Allez sur le site.
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => launchExternal(place.directionsUrl()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Y aller'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Allez sur le site',
                icon: Icons.public,
                color: color,
                expand: false,
                onPressed: () => launchExternal(siteUrl),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Tout le detail du lieu, directement dans la feuille.
        PlaceDetailContent(place: place, embedded: true),
      ],
    );
  }
}

/// Animation d'entree : fondu + leger glissement vers le haut.
class _AnimatedIn extends StatelessWidget {
  const _AnimatedIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: child),
      ),
      child: child,
    );
  }
}
