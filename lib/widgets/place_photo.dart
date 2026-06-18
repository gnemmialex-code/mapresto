import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'skeleton.dart';

/// Affiche une photo d'un lieu qu'elle soit une URL reseau ou un asset local.
///
/// Convention assets locaux :
///   assets/places/{place_id}_photo_1.jpg   (images)
///   assets/places/{place_id}_video_1.mp4   (videos — utilisees par PlaceVideoPlayer)
///
/// Si [path] commence par "http" → CachedNetworkImage.
/// Sinon                         → Image.asset (chemin depuis la racine du projet).
class PlacePhoto extends StatelessWidget {
  const PlacePhoto({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.fallbackColor,
  });

  final String path;
  final BoxFit fit;
  final Color? fallbackColor;

  bool get _isNetwork => path.startsWith('http');

  Widget _fallback() => Container(
        color: (fallbackColor ?? Colors.grey.shade700).withValues(alpha: 0.12),
      );

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: fit,
        placeholder: (_, _) => const _ShimmerBox(),
        errorWidget: (_, _, _) => _fallback(),
      );
    }
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox();

  @override
  Widget build(BuildContext context) {
    // Shimmer anime : impression de chargement bien plus fluide qu'un gris fixe.
    return const Shimmer(child: Skeleton(height: double.infinity, radius: 0));
  }
}
