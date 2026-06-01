import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/places_view_model.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/premium_lock_overlay.dart';
import '../place_detail/place_detail_screen.dart';
import 'place_card_widget.dart';

/// Liste scrollable des lieux, avec filtres et logique freemium.
class PlacesListScreen extends StatelessWidget {
  const PlacesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlacesViewModel>();
    final visible = vm.visiblePlaces;
    final locked = vm.lockedPlaces;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lieux'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: const FilterBar(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${visible.length} lieu(x) affiche(s)',
                  style: AppTypography.caption,
                ),
                const Spacer(),
                if (vm.filtersActive)
                  TextButton.icon(
                    onPressed: vm.clearFilters,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Effacer filtres'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (visible.isEmpty && locked.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text('Aucun lieu ne correspond aux filtres.'),
                    ),
                  ),
                for (final p in visible)
                  PlaceCardWidget(
                    place: p,
                    onTap: () => _openDetail(context, p),
                  ),

                // Lieux verrouilles (Premium).
                if (locked.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.lock,
                          size: 16, color: AppColors.premium),
                      const SizedBox(width: 6),
                      Text('Lieux Premium', style: AppTypography.subtitle),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final p in locked)
                    PremiumLockOverlay(
                      compact: true,
                      onUnlock: () => _showPaywall(context),
                      child: PlaceCardWidget(place: p),
                    ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, place) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
    );
  }

  void _showPaywall(BuildContext context) {
    // >>> POINT DE BRANCHEMENT PAYWALL <<<
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paywall a brancher ici.')),
    );
  }
}
