import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/place_visuals.dart';
import '../../viewmodels/collections_view_model.dart';

/// Feuille pour ajouter/retirer des lieux du catalogue a sa carte perso.
/// [onLimitReached] est appele quand le plan gratuit (10 lieux) est sature.
class PlacePickerSheet extends StatefulWidget {
  const PlacePickerSheet({super.key, this.onLimitReached});

  final VoidCallback? onLimitReached;

  static Future<void> show(BuildContext context, {VoidCallback? onLimitReached}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: PlacePickerSheet(onLimitReached: onLimitReached),
      ),
    );
  }

  @override
  State<PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<PlacePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();
    final catalog = vm.catalog
        .where((p) =>
            _query.isEmpty ||
            p.name.toLowerCase().contains(_query.toLowerCase()) ||
            p.address.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Ajouter des lieux', style: AppTypography.title),
              const Spacer(),
              Text(
                vm.isCreatorUnlocked
                    ? '${vm.myMapCount} lieux'
                    : '${vm.myMapCount}/${vm.mapLimit}',
                style: AppTypography.subtitle.copyWith(
                  color: vm.canAddToMyMap
                      ? AppColors.primary
                      : AppColors.premium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher un lieu...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: catalog.length,
              itemBuilder: (_, i) {
                final p = catalog[i];
                final inMap = vm.isInMyMap(p);
                final color = PlaceVisuals.color(p.type);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(PlaceVisuals.icon(p.type), color: color),
                  ),
                  title: Text(p.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${p.type.label} · ${p.priceLabel} · ${p.averagePrice}€',
                    style: AppTypography.caption,
                  ),
                  trailing: inMap
                      ? IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: AppColors.primary),
                          onPressed: () => vm.removeFromMyMap(p),
                        )
                      : IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            final ok = vm.addToMyMap(p);
                            if (!ok) widget.onLimitReached?.call();
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
