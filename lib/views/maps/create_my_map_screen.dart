import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/collections_view_model.dart';
import '../../widgets/premium_lock_overlay.dart';
import '../../widgets/primary_button.dart';
import '../place_detail/place_detail_screen.dart';
import '../places/place_card_widget.dart';
import 'creator_space_screen.dart';
import 'mini_map_view.dart';
import 'place_picker_sheet.dart';

/// "Je cree ma carte" : plan gratuit limite a 10 lieux + filtres limites.
class CreateMyMapScreen extends StatelessWidget {
  const CreateMyMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();
    final map = vm.myMap;
    final color = map.style.primaryColor;
    final atLimit = !vm.canAddToMyMap;

    return Scaffold(
      appBar: AppBar(title: const Text('Je cree ma carte')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: color,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Ajouter un lieu'),
        onPressed: () => PlacePickerSheet.show(
          context,
          onLimitReached: () => _showPaywall(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Jauge de progression freemium ----
          _QuotaCard(
            count: vm.myMapCount,
            limit: vm.mapLimit,
            unlocked: vm.isCreatorUnlocked,
            color: color,
          ),
          const SizedBox(height: 16),

          MiniMapView(places: map.places, color: color),
          const SizedBox(height: 16),

          // ---- Filtres limites (gratuit) ----
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_alt, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Filtres de base seulement. Les filtres avances '
                    '(ambiance, musique, affluence...) sont reserves au plan '
                    'Createur.',
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (atLimit) ...[
            _UpgradeBanner(onUpgrade: () => _showPaywall(context)),
            const SizedBox(height: 16),
          ],

          Text('Mes lieux (${map.places.length})',
              style: AppTypography.subtitle),
          const SizedBox(height: 8),
          if (map.places.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('Ajoutez vos premieres adresses avec le bouton +.'),
              ),
            ),
          // Lieux accessibles (5 max en gratuit).
          for (final p in vm.accessibleSavedPlaces)
            Dismissible(
              key: ValueKey(p.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => vm.removeFromMyMap(p),
              child: PlaceCardWidget(
                place: p,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlaceDetailScreen(place: p),
                  ),
                ),
              ),
            ),

          // Lieux verrouilles (au-dela de 5) : acces Premium requis.
          if (vm.lockedSavedPlaces.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.premium.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.premium.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: AppColors.premium, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Plan gratuit : ${CollectionsViewModel.freeAccessLimit} '
                      'lieux accessibles. ${vm.lockedSavedPlaces.length} '
                      'lieu(x) verrouille(s) - debloquez l\'acces complet.',
                      style: AppTypography.caption,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final p in vm.lockedSavedPlaces)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: PremiumLockOverlay(
                  compact: true,
                  onUnlock: () => _showPaywall(context),
                  child: PlaceCardWidget(place: p),
                ),
              ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: AppColors.premium),
            SizedBox(width: 8),
            Text('Limite atteinte'),
          ],
        ),
        content: Text(
          'Votre plan est limite a ${context.read<CollectionsViewModel>().mapLimit} '
          'lieux et aux filtres de base.\n\nParrainez des amis (+5 lieux chacun) '
          'ou passez au plan Createur pour des adresses illimitees, tous les '
          'filtres et un style personnalise.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.premium),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreatorSpaceScreen(),
                ),
              );
            },
            child: const Text('Decouvrir Createur'),
          ),
        ],
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({
    required this.count,
    required this.limit,
    required this.unlocked,
    required this.color,
  });

  final int count;
  final int limit;
  final bool unlocked;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = unlocked ? 1.0 : (count / limit).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(unlocked ? 'Plan Createur' : 'Plan gratuit',
                  style: AppTypography.subtitle),
              const Spacer(),
              Text(
                unlocked ? '$count lieux' : '$count / $limit',
                style: AppTypography.subtitle.copyWith(
                  color: (!unlocked && count >= limit)
                      ? AppColors.premium
                      : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.background,
              color: (!unlocked && count >= limit) ? AppColors.premium : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner({required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.premium.withValues(alpha: 0.18),
          AppColors.premium.withValues(alpha: 0.06),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.premium.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.premium),
              const SizedBox(width: 8),
              Text('Limite gratuite atteinte', style: AppTypography.subtitle),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Passez Createur pour des adresses illimitees, tous les filtres '
            'et un style personnalise.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Passer au plan Createur',
            icon: Icons.lock_open,
            color: AppColors.premium,
            onPressed: onUpgrade,
          ),
        ],
      ),
    );
  }
}
