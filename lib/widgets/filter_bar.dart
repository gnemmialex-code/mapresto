import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/place.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/places_view_model.dart';
import 'primary_button.dart';
import 'tag_chip.dart';

/// Barre de filtres affichee en haut de la carte et de la liste.
/// - Chips de type (Tous / Bar / Resto / Hotel)
/// - Bouton "Filtres" ouvrant un panneau detaille (prix, note, tags).
class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlacesViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TypeChip(label: 'Tous', type: null, vm: vm),
                  for (final t in PlaceType.values)
                    _TypeChip(label: t.label, type: t, vm: vm),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _FiltersButton(vm: vm),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.type, required this.vm});

  final String label;
  final PlaceType? type;
  final PlacesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final selected = vm.filter.type == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => vm.setType(type),
        labelStyle: AppTypography.tag.copyWith(
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.background,
        showCheckmark: false,
      ),
    );
  }
}

class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.vm});
  final PlacesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final count = vm.activeFilterCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => _openFilterSheet(context, vm),
          icon: const Icon(Icons.tune, color: AppColors.primary),
          tooltip: 'Filtres',
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: AppTypography.tag.copyWith(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ouvre le panneau detaille de filtres (note min, prix max, tags).
void _openFilterSheet(BuildContext context, PlacesViewModel vm) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: vm,
      child: const _FilterSheet(),
    ),
  );
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlacesViewModel>();
    final filter = vm.filter;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtres', style: AppTypography.title),
                TextButton(
                  onPressed: vm.clearFilters,
                  child: const Text('Reinitialiser'),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ============ PARTIE 1 : FILTRES SIMPLES (gratuits) ============
            const _SectionHeader(label: 'Filtres simples'),
            const SizedBox(height: 12),

            // ---- Note minimale ----
            Text('Note minimale', style: AppTypography.subtitle),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: filter.minRating ?? 0,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: (filter.minRating ?? 0).toStringAsFixed(1),
                    onChanged: (v) => vm.setMinRating(v == 0 ? null : v),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    filter.minRating == null
                        ? '-'
                        : filter.minRating!.toStringAsFixed(1),
                    style: AppTypography.body,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ---- Prix max ----
            Text('Budget maximum', style: AppTypography.subtitle),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var level = 1; level <= 4; level++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TagChip(
                      label: '€' * level,
                      selected: filter.maxPriceLevel == level,
                      onTap: () => vm.setMaxPriceLevel(
                        filter.maxPriceLevel == level ? null : level,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ============ PARTIE 2 : FILTRES PREMIUM (avances) ============
            // V1 : tout est accessible, on indique simplement le statut Premium.
            const _PremiumBanner(),
            const SizedBox(height: 16),

            // ---- Prix reel (budget max en euros) ----
            Row(
              children: [
                Text('Prix reel max', style: AppTypography.subtitle),
                const SizedBox(width: 8),
                const _PremiumPill(),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: (filter.maxAveragePrice ?? 0).toDouble(),
                    min: 0,
                    max: 500,
                    divisions: 50,
                    label: filter.maxAveragePrice == null
                        ? 'Tous'
                        : '${filter.maxAveragePrice} €',
                    onChanged: (v) =>
                        vm.setMaxAveragePrice(v == 0 ? null : v.round()),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    filter.maxAveragePrice == null
                        ? 'Tous'
                        : '${filter.maxAveragePrice} €',
                    style: AppTypography.body,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _TagSection(
              title: 'Ambiance',
              premium: true,
              options: MockDataService.ambianceOptions,
              isSelected: vm.isAmbianceSelected,
              onToggle: vm.toggleAmbiance,
            ),
            _TagSection(
              title: 'Musique',
              premium: true,
              options: MockDataService.musicOptions,
              isSelected: vm.isMusicSelected,
              onToggle: vm.toggleMusic,
            ),
            _TagSection(
              title: 'Style & cuisine',
              premium: true,
              options: MockDataService.styleOptions,
              isSelected: vm.isStyleSelected,
              onToggle: vm.toggleStyle,
            ),
            _TagSection(
              title: 'Frequentation',
              premium: true,
              options: MockDataService.crowdOptions,
              isSelected: vm.isCrowdSelected,
              onToggle: vm.toggleCrowd,
            ),
            _TagSection(
              title: "Horaires d'affluence",
              premium: true,
              options: MockDataService.peakOptions,
              isSelected: vm.isPeakSelected,
              onToggle: vm.togglePeak,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Voir ${vm.filteredPlaces.length} lieux',
              icon: Icons.check,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({
    required this.title,
    required this.options,
    required this.isSelected,
    required this.onToggle,
    this.premium = false,
  });

  final String title;
  final List<String> options;
  final bool Function(String) isSelected;
  final void Function(String) onToggle;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTypography.subtitle),
            if (premium) ...[
              const SizedBox(width: 8),
              const _PremiumPill(),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in options)
              TagChip(
                label: tag,
                selected: isSelected(tag),
                onTap: () => onToggle(tag),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Petit en-tete de section (ex: "Filtres simples").
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(height: 1)),
      ],
    );
  }
}

/// Pastille doree "PREMIUM" affichee a cote des filtres avances.
class _PremiumPill extends StatelessWidget {
  const _PremiumPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.premium.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.premium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, size: 12, color: AppColors.premium),
          const SizedBox(width: 3),
          Text(
            'PREMIUM',
            style: AppTypography.tag.copyWith(
              color: AppColors.premium,
              fontSize: 10,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banniere d'introduction de la zone de filtres avances (Premium).
///
/// >>> POINT DE BRANCHEMENT PAYWALL <<<
/// En V1 tout est accessible. Plus tard, conditionner l'activation de ces
/// filtres a `isPremiumUser` et brancher le bouton sur l'ecran d'achat.
class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.premium.withValues(alpha: 0.18),
            AppColors.premium.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.premium.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: AppColors.premium),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Filtres Premium', style: AppTypography.subtitle),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.premium,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Offert en V1',
                        style: AppTypography.tag
                            .copyWith(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Filtrage avance par ambiance, musique et cuisine.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
