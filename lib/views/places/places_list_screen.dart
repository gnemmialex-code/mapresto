import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/places_view_model.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/premium_lock_overlay.dart';
import '../../widgets/primary_button.dart';
import '../contribute/add_address_screen.dart';
import '../contribute/review_form_screen.dart';
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

                // ---- Contribuer (fin de liste) ----
                const SizedBox(height: 24),
                const _ContributeFooter(),
                const SizedBox(height: 24),
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

/// Pied de liste : contribuer (proposer une adresse / donner son avis).
class _ContributeFooter extends StatelessWidget {
  const _ContributeFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text('Une adresse manque ? Un avis a partager ?',
              style: AppTypography.subtitle, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            'Aidez la communaute a enrichir la carte.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Ajouter une adresse',
            icon: Icons.add_location_alt,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddAddressScreen()),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReviewFormScreen()),
              ),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Donner mon avis'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
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
