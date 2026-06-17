import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: fit,
        placeholder: (_, _) => _ShimmerBox(color: fallbackColor),
        errorWidget: (_, _, _) => _PhotoPlaceholder(color: fallbackColor),
      );
    }
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, _, _) => _PhotoPlaceholder(color: fallbackColor),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: (color ?? Colors.grey.shade700).withValues(alpha: 0.25),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade700;
    return Container(
      color: c.withValues(alpha: 0.12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 36, color: c.withValues(alpha: 0.5)),
          const SizedBox(height: 6),
          Text(
            'Photo à venir',
            style: TextStyle(
              fontSize: 12,
              color: c.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
