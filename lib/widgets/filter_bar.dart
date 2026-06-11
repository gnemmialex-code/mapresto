import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/place.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/places_view_model.dart';
import 'primary_button.dart';
import 'tag_chip.dart';

const _kFilterColor = Color(0xFFF4845F);
const _kAiColor = Color(0xFF7C3AED);
const _kPreviewCount = 5;

// ────────────────────────────────────────────────────────────────────
// Barre de filtres (rangée 1 : types, rangée 2 : prix + "Voir plus")
// ────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in PlaceType.values)
                  _TypeChip(label: t.label, type: t, vm: vm),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var level = 1; level <= 4; level++)
                        _QuickFilterChip(
                          label: '€' * level,
                          selected: vm.filter.maxPriceLevel == level,
                          onTap: () => vm.setMaxPriceLevel(
                            vm.filter.maxPriceLevel == level ? null : level,
                          ),
                        ),
                      if (vm.isAiSearchActive)
                        _QuickFilterChip(
                          label: '🤖 IA active',
                          selected: true,
                          color: _kAiColor,
                          onTap: () => vm.clearAiSearch(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _VoirPlusButton(vm: vm),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Chips de type (rangée 1)
// ────────────────────────────────────────────────────────────────────

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
        onSelected: (_) => vm.setType(vm.filter.type == type ? null : type),
        labelStyle: AppTypography.tag.copyWith(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.background,
        showCheckmark: false,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Chips de filtre rapide (rangée 2)
// ────────────────────────────────────────────────────────────────────

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _kFilterColor;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? c : Colors.black12,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.tag.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Bouton "Voir plus" (ouvre la modal)
// ────────────────────────────────────────────────────────────────────

class _VoirPlusButton extends StatelessWidget {
  const _VoirPlusButton({required this.vm});
  final PlacesViewModel vm;

  int get _extraCount {
    final f = vm.filter;
    var n = 0;
    if (f.minRating != null) n++;
    if (f.maxAveragePrice != null) n++;
    n += f.ambiance.length +
        f.music.length +
        f.style.length +
        f.cuisine.length +
        f.crowd.length +
        f.peak.length +
        f.openingHours.length;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final active = _extraCount > 0 || vm.isAiSearchActive;
    final color = vm.isAiSearchActive ? _kAiColor : _kFilterColor;
    return GestureDetector(
      onTap: () => _openFilterSheet(context, vm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : Colors.black12,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              vm.isAiSearchActive ? Icons.auto_awesome : Icons.tune_rounded,
              size: 14,
              color: active ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              vm.isAiSearchActive
                  ? 'IA (${vm.filteredPlaces.length})'
                  : active
                      ? 'Filtres ($_extraCount)'
                      : 'Voir plus',
              style: AppTypography.tag.copyWith(
                color: active ? color : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Ouverture de la modal
// ────────────────────────────────────────────────────────────────────

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

// ────────────────────────────────────────────────────────────────────
// Modal de filtres avancés (StatefulWidget pour onglet IA)
// ────────────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int _tab = 0; // 0 = Filtres, 1 = Recherche IA
  final _aiController = TextEditingController();
  bool _aiLoading = false;
  String? _aiError;
  List<String>? _aiResultIds;

  @override
  void dispose() {
    _aiController.dispose();
    super.dispose();
  }

  Future<void> _runAiSearch(PlacesViewModel vm) async {
    final query = _aiController.text.trim();
    if (query.isEmpty) return;

    if (!Config.isClaudeConfigured) {
      setState(() => _aiError =
          'Clé API Claude non configurée.\nAjoutez CLAUDE_API_KEY dans config.dart ou via --dart-define.');
      return;
    }

    setState(() {
      _aiLoading = true;
      _aiError = null;
      _aiResultIds = null;
    });

    try {
      final placesSummary = vm.allPlaces.map((p) {
        final tags = [
          ...p.ambianceTags,
          ...p.musicTags,
          ...p.styleTags,
          ...p.cuisineTags,
          ...p.crowdTags,
        ].join(', ');
        return '${p.id}|${p.name}|${p.type.name}|${p.priceLevel}★|$tags';
      }).join('\n');

      final prompt =
          'Tu es un assistant de recommandation de lieux à Paris. '
          'Voici la liste des lieux disponibles (format: id|nom|type|prix|tags) :\n\n'
          '$placesSummary\n\n'
          'Recherche de l\'utilisateur : "$query"\n\n'
          'Retourne uniquement un tableau JSON des IDs les plus pertinents, '
          'triés par pertinence décroissante, max 20 résultats. '
          'Format exact : ["p01","p02",...]. Ne retourne rien d\'autre.';

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': Config.claudeApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 512,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur API ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (data['content'] as List).first['text'] as String;
      final jsonMatch = RegExp(r'\[.*?\]', dotAll: true).firstMatch(text);
      if (jsonMatch == null) throw Exception('Réponse inattendue');

      final ids = List<String>.from(jsonDecode(jsonMatch.group(0)!));
      setState(() => _aiResultIds = ids);
    } catch (e) {
      setState(() => _aiError = 'Recherche impossible : $e');
    } finally {
      setState(() => _aiLoading = false);
    }
  }

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
            // Handle
            Center(
              child: Container(
                width: 44, height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Onglets Filtres / IA ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TabToggle(
                  selected: _tab == 0,
                  label: 'Filtres',
                  icon: Icons.tune_rounded,
                  color: _kFilterColor,
                  onTap: () => setState(() { _tab = 0; }),
                ),
                const SizedBox(width: 8),
                _TabToggle(
                  selected: _tab == 1,
                  label: 'Recherche IA',
                  icon: Icons.auto_awesome,
                  color: _kAiColor,
                  onTap: () => setState(() { _tab = 1; }),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    vm.clearFilters();
                    setState(() {
                      _aiResultIds = null;
                      _aiError = null;
                      _aiController.clear();
                    });
                  },
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_tab == 0) ..._buildFiltersTab(context, vm, filter),
            if (_tab == 1) ..._buildAiTab(context, vm),
          ],
        ),
      ),
    );
  }

  // ── Onglet Filtres ──────────────────────────────────────────────

  List<Widget> _buildFiltersTab(
    BuildContext context,
    PlacesViewModel vm,
    dynamic filter,
  ) {
    return [
      // Note minimale
      const _SectionHeader(label: 'Note minimale'),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Slider(
              value: filter.minRating ?? 0,
              min: 0, max: 5, divisions: 10,
              activeColor: _kFilterColor,
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
      const SizedBox(height: 16),

      // Budget maximum
      const _SectionHeader(label: 'Budget maximum'),
      const SizedBox(height: 4),
      Text(
        '(au total, pas par personne)',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Slider(
              value: (filter.maxAveragePrice ?? 0).toDouble(),
              min: 0, max: 500, divisions: 50,
              activeColor: _kFilterColor,
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
      const SizedBox(height: 20),

      // Premium banner
      const _PremiumBanner(),
      const SizedBox(height: 16),

      _ExpandableTagSection(
        title: 'Ambiance',
        options: MockDataService.ambianceOptions,
        isSelected: vm.isAmbianceSelected,
        onToggle: vm.toggleAmbiance,
      ),
      _ExpandableTagSection(
        title: 'Musique',
        options: MockDataService.musicOptions,
        isSelected: vm.isMusicSelected,
        onToggle: vm.toggleMusic,
      ),
      _ExpandableTagSection(
        title: 'Style du lieu',
        options: MockDataService.styleOptions,
        isSelected: vm.isStyleSelected,
        onToggle: vm.toggleStyle,
      ),
      _ExpandableTagSection(
        title: 'Cuisine',
        options: MockDataService.cuisineOptions,
        isSelected: vm.isCuisineSelected,
        onToggle: vm.toggleCuisine,
      ),
      _ExpandableTagSection(
        title: 'Fréquentation',
        options: MockDataService.crowdOptions,
        isSelected: vm.isCrowdSelected,
        onToggle: vm.toggleCrowd,
      ),
      _ExpandableTagSection(
        title: "Horaires d'affluence",
        options: MockDataService.peakOptions,
        isSelected: vm.isPeakSelected,
        onToggle: vm.togglePeak,
      ),
      _ExpandableTagSection(
        title: "Horaires d'ouverture",
        options: MockDataService.openingHoursOptions,
        isSelected: vm.isOpeningHoursSelected,
        onToggle: vm.toggleOpeningHours,
      ),
      const SizedBox(height: 12),
      PrimaryButton(
        label: 'Voir ${vm.filteredPlaces.length} lieux',
        icon: Icons.check,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
  }

  // ── Onglet Recherche IA ─────────────────────────────────────────

  List<Widget> _buildAiTab(BuildContext context, PlacesViewModel vm) {
    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _kAiColor.withValues(alpha: 0.12),
              _kAiColor.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kAiColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: _kAiColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recherche IA',
                    style: AppTypography.subtitle
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Décrivez ce que vous cherchez en langage naturel.',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Champ de saisie
      Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kAiColor.withValues(alpha: 0.25)),
        ),
        child: TextField(
          controller: _aiController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Ex: bar cosy avec jazz et cocktails, pas trop cher, ambiance intimiste...',
            hintStyle: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            contentPadding: const EdgeInsets.all(14),
            border: InputBorder.none,
          ),
        ),
      ),
      const SizedBox(height: 12),

      // Bouton rechercher
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _aiLoading ? null : () => _runAiSearch(vm),
          icon: _aiLoading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.search, size: 18),
          label: Text(
              _aiLoading ? 'Recherche en cours...' : 'Trouver les meilleurs lieux'),
          style: FilledButton.styleFrom(
            backgroundColor: _kAiColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),

      // Erreur
      if (_aiError != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _aiError!,
            style: AppTypography.caption.copyWith(color: Colors.red),
          ),
        ),
      ],

      // Résultats
      if (_aiResultIds != null) ...[
        const SizedBox(height: 16),
        Text(
          '${_aiResultIds!.length} lieux recommandés',
          style: AppTypography.subtitle.copyWith(
            fontWeight: FontWeight.w700,
            color: _kAiColor,
          ),
        ),
        const SizedBox(height: 8),
        for (final id in _aiResultIds!) ...[
          Builder(builder: (ctx) {
            final place = vm.allPlaces.where((p) => p.id == id).firstOrNull;
            if (place == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _kAiColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.name,
                              style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${place.type.label} · ${place.priceLabel}',
                            style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text('${place.rating} ★',
                        style: AppTypography.caption.copyWith(
                            color: _kAiColor,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Voir ces ${_aiResultIds!.length} lieux sur la carte',
          icon: Icons.map_outlined,
          onPressed: () {
            vm.setAiSearchResults(_aiResultIds!);
            Navigator.of(context).pop();
          },
        ),
      ],

      if (!Config.isClaudeConfigured) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Text(
            '⚠️ Clé API Claude non configurée.\n'
            'Ajoutez CLAUDE_API_KEY dans lib/config.dart ou via\n'
            'flutter run --dart-define=CLAUDE_API_KEY=sk-ant-...',
            style: AppTypography.caption
                .copyWith(color: Colors.orange.shade800),
          ),
        ),
      ],
    ];
  }
}

// ────────────────────────────────────────────────────────────────────
// Toggle onglets Filtres / IA
// ────────────────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  const _TabToggle({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.black12,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.tag.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Section de tags expandable (5 visibles + "voir plus")
// ────────────────────────────────────────────────────────────────────

class _ExpandableTagSection extends StatefulWidget {
  const _ExpandableTagSection({
    required this.title,
    required this.options,
    required this.isSelected,
    required this.onToggle,
  });
  final String title;
  final List<String> options;
  final bool Function(String) isSelected;
  final void Function(String) onToggle;

  @override
  State<_ExpandableTagSection> createState() =>
      _ExpandableTagSectionState();
}

class _ExpandableTagSectionState extends State<_ExpandableTagSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.options.length > _kPreviewCount;
    final visible = _expanded
        ? widget.options
        : widget.options.take(_kPreviewCount).toList();
    final hiddenCount = widget.options.length - _kPreviewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppTypography.subtitle
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in visible)
              TagChip(
                label: tag,
                color: _kFilterColor,
                selected: widget.isSelected(tag),
                onTap: () => widget.onToggle(tag),
              ),
          ],
        ),
        if (hasMore) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expanded
                      ? 'Voir moins'
                      : '+ $hiddenCount autre${hiddenCount > 1 ? 's' : ''}',
                  style: AppTypography.caption.copyWith(
                    color: _kFilterColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _kFilterColor,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Composants internes
// ────────────────────────────────────────────────────────────────────

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
                    Text('Filtres Premium',
                        style: AppTypography.subtitle
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
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
                  'Filtrage avancé par ambiance, musique, cuisine et horaires.',
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
