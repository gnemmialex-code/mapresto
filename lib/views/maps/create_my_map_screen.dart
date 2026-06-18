import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../models/place_annotation.dart';
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

/// "Je crée ma carte" : plan gratuit limité à 10 lieux + filtres limités.
class CreateMyMapScreen extends StatefulWidget {
  const CreateMyMapScreen({super.key});

  @override
  State<CreateMyMapScreen> createState() => _CreateMyMapScreenState();
}

class _CreateMyMapScreenState extends State<CreateMyMapScreen> {
  String? _selectedCategory; // null = Tous

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();
    final map = vm.myMap;
    final color = map.style.primaryColor;
    final atLimit = !vm.canAddToMyMap;
    final categories = vm.allCategories;

    // Filtrage par catégorie
    final accessible = vm.accessibleSavedPlaces;
    final filtered = _selectedCategory == null
        ? accessible
        : accessible.where((p) {
            final a = vm.annotationFor(p.id);
            return a?.category == _selectedCategory;
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Je crée ma carte')),
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
          // ---- Jauge freemium ----
          _QuotaCard(
            count: vm.myMapCount,
            limit: vm.mapLimit,
            unlocked: vm.isCreatorUnlocked,
            color: color,
          ),
          const SizedBox(height: 16),

          MiniMapView(places: map.places, color: color),
          const SizedBox(height: 16),

          // ---- Filtre catégories ----
          if (categories.isNotEmpty) ...[
            _CategoryFilter(
              categories: categories,
              selected: _selectedCategory,
              onSelect: (c) => setState(() =>
                  _selectedCategory = _selectedCategory == c ? null : c),
            ),
            const SizedBox(height: 12),
          ],

          // ---- Filtres de base ----
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
                    'Filtres de base seulement. Les filtres avancés '
                    '(ambiance, musique, affluence...) sont réservés au plan '
                    'Créateur.',
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

          Text(
            _selectedCategory != null
                ? '$_selectedCategory (${filtered.length})'
                : 'Mes lieux (${map.places.length})',
            style: AppTypography.subtitle,
          ),
          const SizedBox(height: 8),

          if (map.places.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('Ajoutez vos premières adresses avec le bouton +.'),
              ),
            ),

          // ---- Lieux accessibles ----
          for (final p in filtered)
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
              child: _AnnotatedPlaceCard(
                place: p,
                annotation: vm.annotationFor(p.id),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => PlaceDetailScreen(place: p)),
                ),
                onEdit: () => _editAnnotation(context, p, vm),
              ),
            ),

          // ---- Lieux verrouillés ----
          if (vm.lockedSavedPlaces.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.premium.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.premium.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: AppColors.premium, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Plan gratuit : ${CollectionsViewModel.freeAccessLimit} '
                      'lieux accessibles. ${vm.lockedSavedPlaces.length} '
                      'lieu(x) verrouillé(s) - débloquez l\'accès complet.',
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

  void _editAnnotation(
      BuildContext context, Place place, CollectionsViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _AnnotationSheet(place: place),
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
          'Votre plan est limité à ${context.read<CollectionsViewModel>().mapLimit} '
          'lieux et aux filtres de base.\n\nParrainez des amis (+5 lieux chacun) '
          'ou passez au plan Créateur pour des adresses illimitées, tous les '
          'filtres et un style personnalisé.',
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
            child: const Text('Découvrir Créateur'),
          ),
        ],
      ),
    );
  }
}

// ── Carte lieu avec annotation ────────────────────────────────────────

class _AnnotatedPlaceCard extends StatelessWidget {
  const _AnnotatedPlaceCard({
    required this.place,
    required this.onTap,
    required this.onEdit,
    this.annotation,
  });
  final Place place;
  final PlaceAnnotation? annotation;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasNote = annotation?.note.isNotEmpty ?? false;
    final hasCat = annotation?.category.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            PlaceCardWidget(place: place, onTap: onTap),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.edit_note, size: 16,
                      color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        if (hasCat || hasNote)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCat) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(annotation!.category,
                        style: AppTypography.tag
                            .copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(width: 8),
                ],
                if (hasNote)
                  Expanded(
                    child: Text(
                      annotation!.note,
                      style: AppTypography.caption
                          .copyWith(fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }
}

// ── Bottom sheet annotation ───────────────────────────────────────────

class _AnnotationSheet extends StatefulWidget {
  const _AnnotationSheet({required this.place});
  final Place place;

  @override
  State<_AnnotationSheet> createState() => _AnnotationSheetState();
}

class _AnnotationSheetState extends State<_AnnotationSheet> {
  late final TextEditingController _noteCtrl;
  late final TextEditingController _catCtrl;
  late String _selectedCat;

  @override
  void initState() {
    super.initState();
    final vm = context.read<CollectionsViewModel>();
    final ann = vm.annotationFor(widget.place.id);
    _noteCtrl = TextEditingController(text: ann?.note ?? '');
    _catCtrl = TextEditingController();
    _selectedCat = ann?.category ?? '';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();
    final categories = vm.allCategories;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.place.name,
                style:
                    AppTypography.subtitle.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),

            // ---- Note perso ----
            Text('Ma note',
                style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Super terrasse, demander la table du fond...',
                hintStyle:
                    AppTypography.caption.copyWith(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Catégorie ----
            Text('Catégorie',
                style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            if (categories.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final cat in categories)
                    GestureDetector(
                      onTap: () => setState(() =>
                          _selectedCat = _selectedCat == cat ? '' : cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedCat == cat
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedCat == cat
                                ? AppColors.primary
                                : Colors.black12,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: AppTypography.tag.copyWith(
                            color: _selectedCat == cat
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Nouvelle catégorie
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _catCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nouvelle catégorie…',
                      hintStyle: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final newCat = _catCtrl.text.trim();
                    if (newCat.isNotEmpty) {
                      setState(() {
                        _selectedCat = newCat;
                        _catCtrl.clear();
                      });
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  child: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              label: 'Enregistrer',
              icon: Icons.check,
              onPressed: () async {
                final vm = context.read<CollectionsViewModel>();
                await vm.setAnnotation(
                  widget.place.id,
                  note: _noteCtrl.text.trim(),
                  category: _selectedCat,
                );
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filtre catégories ────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });
  final List<String> categories;
  final String? selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Catégories',
            style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in categories)
                GestureDetector(
                  onTap: () => onSelect(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected == cat
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected == cat
                            ? AppColors.primary
                            : Colors.black12,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: AppTypography.tag.copyWith(
                        color: selected == cat
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Quota card ───────────────────────────────────────────────────────

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
              Text(unlocked ? 'Plan Créateur' : 'Plan gratuit',
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
              color:
                  (!unlocked && count >= limit) ? AppColors.premium : color,
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
            'Passez Créateur pour des adresses illimitées, tous les filtres '
            'et un style personnalisé.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Passer au plan Créateur',
            icon: Icons.lock_open,
            color: AppColors.premium,
            onPressed: onUpgrade,
          ),
        ],
      ),
    );
  }
}
