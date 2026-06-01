import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_collection.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/collections_view_model.dart';
import '../../widgets/primary_button.dart';
import '../place_detail/place_detail_screen.dart';
import '../places/place_card_widget.dart';
import 'share_code_dialog.dart';

/// Detail d'une collection : style + liste de lieux + partage par code.
class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({super.key, required this.collection});

  final UserCollection collection;

  @override
  Widget build(BuildContext context) {
    final style = collection.style;
    final color = style.primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(style.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tete style.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(style.name,
                    style: AppTypography.title.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                if (style.description != null)
                  Text(style.description!,
                      style:
                          AppTypography.body.copyWith(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(collection.ownerName,
                        style: AppTypography.caption
                            .copyWith(color: Colors.white70)),
                    const SizedBox(width: 16),
                    const Icon(Icons.place, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text('${collection.places.length} lieux',
                        style: AppTypography.caption
                            .copyWith(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Partager via un code',
            icon: Icons.ios_share,
            color: color,
            onPressed: () {
              final code = context
                  .read<CollectionsViewModel>()
                  .shareCollection(collection);
              ShareCodeDialog.show(context,
                  collection: collection, code: code);
            },
          ),
          const SizedBox(height: 16),
          Text('Lieux de la collection', style: AppTypography.subtitle),
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
    );
  }
}
