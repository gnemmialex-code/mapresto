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
    final fallback = Container(color: fallbackColor ?? Colors.grey.shade800);
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: fit,
        placeholder: (_, _) =>
            Container(color: fallbackColor?.withValues(alpha: 0.3)),
        errorWidget: (_, _, _) => fallback,
      );
    }
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
