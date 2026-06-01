import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/place_visuals.dart';

/// Carte resumant un lieu dans la liste.
class PlaceCardWidget extends StatelessWidget {
  const PlaceCardWidget({
    super.key,
    required this.place,
    this.onTap,
  });

  final Place place;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = PlaceVisuals.color(place.type);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vignette photo.
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: place.photos.isEmpty
                      ? Container(color: AppColors.background)
                      : CachedNetworkImage(
                          imageUrl: place.photos.first,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              Container(color: AppColors.background),
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.background,
                            child: Icon(PlaceVisuals.icon(place.type),
                                color: color),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(PlaceVisuals.icon(place.type),
                            size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(place.type.label,
                            style: AppTypography.caption.copyWith(color: color)),
                        const Spacer(),
                        Text('${place.priceLabel} · ${place.averagePrice}€',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: AppColors.rating),
                        const SizedBox(width: 2),
                        Text('${place.rating}',
                            style: AppTypography.caption),
                        Text('  (${place.reviewCount})',
                            style: AppTypography.caption),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final tag in place.allTags.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(tag,
                                style: AppTypography.tag.copyWith(color: color)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
