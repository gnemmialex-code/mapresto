import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/user_collection.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../place_detail/place_detail_screen.dart';
import '../places/place_card_widget.dart';
import '../maps/mini_map_view.dart';

/// Affiche le plan prive d'un influenceur (read-only), accessible via code.
class PrivateMapScreen extends StatelessWidget {
  const PrivateMapScreen({super.key, required this.collection});

  final UserCollection collection;

  @override
  Widget build(BuildContext context) {
    final style = collection.style;
    final color = style.primaryColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (collection.coverImage != null)
                    CachedNetworkImage(
                      imageUrl: collection.coverImage!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(color: color),
                    )
                  else
                    Container(color: color),
                  // Voile degrade pour lisibilite.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tete profil influenceur.
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: color,
                        child: Text(
                          collection.ownerName.isNotEmpty
                              ? collection.ownerName[0]
                              : '?',
                          style: AppTypography.title
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(style.name,
                                      style: AppTypography.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (collection.isInfluencer) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified,
                                      color: AppColors.primary, size: 18),
                                ],
                              ],
                            ),
                            if (collection.authorHandle != null)
                              Text(collection.authorHandle!,
                                  style: AppTypography.caption
                                      .copyWith(color: color)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Badge plan prive.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text('Plan prive debloque',
                            style: AppTypography.tag.copyWith(color: color)),
                      ],
                    ),
                  ),
                  if (style.description != null) ...[
                    const SizedBox(height: 10),
                    Text(style.description!, style: AppTypography.body),
                  ],
                  const SizedBox(height: 16),
                  // Mini-carte stylee.
                  MiniMapView(places: collection.places, color: color),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.place, size: 18, color: color),
                      const SizedBox(width: 4),
                      Text('${collection.places.length} adresses',
                          style: AppTypography.subtitle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final p in collection.places)
                    PlaceCardWidget(
                      place: p,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlaceDetailScreen(place: p),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
