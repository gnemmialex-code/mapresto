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
                for (var i = 0; i < visible.length; i++)
                  _FadeSlideIn(
                    key: ValueKey('slide_${visible[i].id}'),
                    index: i,
                    child: PlaceCardWidget(
                      place: visible[i],
                      onTap: () => _openDetail(context, visible[i]),
                    ),
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
                  for (var i = 0; i < locked.length; i++)
                    _FadeSlideIn(
                      key: ValueKey('slide_locked_${locked[i].id}'),
                      index: visible.length + i,
                      child: PremiumLockOverlay(
                        compact: true,
                        onUnlock: () => _showPaywall(context),
                        child: PlaceCardWidget(place: locked[i]),
                      ),
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

// ─── Animation d'entrée staggered ────────────────────────────────────────────
// Chaque carte apparaît avec un fade + slide-up, décalé selon son index.
// Le délai max est plafonné à 550 ms pour ne pas faire attendre les longues listes.

class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final delay = (widget.index * 55).clamp(0, 550);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (_, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 22),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
