import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../services/mock_data_service.dart';
import '../../viewmodels/places_view_model.dart';
import '../root_navigation.dart';

const _kAccent = Color(0xFFF4845F);
const _kDark = Color(0xFF1C1C28);
const _kGrey = Color(0xFF6B7280);
const _kBg = Color(0xFFF3F4F6);
const _kBorder = Color(0xFFE5E7EB);
const double _kMaxBudget = 300;
const int _previewCount = 5;

/// Écran d'accueil : carte animée + panel bulle de filtres.
class OnboardingFilterScreen extends StatefulWidget {
  const OnboardingFilterScreen({super.key});

  @override
  State<OnboardingFilterScreen> createState() =>
      _OnboardingFilterScreenState();
}

class _OnboardingFilterScreenState extends State<OnboardingFilterScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  late final AnimationController _panAnim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );

  int _wpIdx = 0;

  static const _waypoints = [
    LatLng(48.8584, 2.2945), // Tour Eiffel
    LatLng(48.8867, 2.3431), // Montmartre
    LatLng(48.8530, 2.3499), // Notre-Dame
    LatLng(48.8738, 2.2950), // Arc de Triomphe
    LatLng(48.8632, 2.3708), // Bastille
    LatLng(48.8462, 2.3372), // Panthéon
  ];

  @override
  void initState() {
    super.initState();
    _panAnim.addListener(_onTick);
    _panAnim.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        _wpIdx = (_wpIdx + 1) % _waypoints.length;
        _panAnim.forward(from: 0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future.delayed(
        const Duration(milliseconds: 600),
        () { if (mounted) _panAnim.forward(); },
      ),
    );
  }

  void _onTick() {
    final t = Curves.easeInOut.transform(_panAnim.value);
    final from = _waypoints[_wpIdx];
    final to = _waypoints[(_wpIdx + 1) % _waypoints.length];
    try {
      _mapController.move(
        LatLng(
          from.latitude + (to.latitude - from.latitude) * t,
          from.longitude + (to.longitude - from.longitude) * t,
        ),
        13.3,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _panAnim.dispose();
    super.dispose();
  }

  void _goToMap() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const RootNavigation(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Carte animée (fond) ──
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _waypoints[0],
                initialZoom: 13.3,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.parismap.parismap_video_guide',
                  maxNativeZoom: 20,
                ),
              ],
            ),
          ),

          // ── Gradient en haut pour le titre ──
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.40,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Contenu ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Paris',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          shadows: [Shadow(blurRadius: 16, color: Colors.black87)],
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Où voulez-vous aller ?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black87)],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _FilterPanel(onConfirm: _goToMap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Panel principal (bulle blanche translucide)
// ─────────────────────────────────────────────────────────────

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  RangeValues _budgetRange = const RangeValues(0, _kMaxBudget);

  bool get _budgetCustomActive =>
      _budgetRange.start > 0 || _budgetRange.end < _kMaxBudget;

  void _updateBudget(PlacesViewModel vm, RangeValues v) {
    setState(() => _budgetRange = v);
    vm.setMinAveragePrice(v.start > 0 ? v.start.round() : null);
    vm.setMaxAveragePrice(v.end < _kMaxBudget ? v.end.round() : null);
  }

  void _resetBudget(PlacesViewModel vm) {
    setState(() => _budgetRange = const RangeValues(0, _kMaxBudget));
    vm.setMinAveragePrice(null);
    vm.setMaxAveragePrice(null);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlacesViewModel>();
    final filter = vm.filter;
    final maxH = MediaQuery.of(context).size.height * 0.70;

    // ── Validation : seul le type de lieu est requis ──
    final typeOk = filter.type != null;
    final ambianceOk = filter.ambiance.isNotEmpty;
    final isValid = typeOk;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          // Bulle blanche translucide
          color: Colors.white.withValues(alpha: 0.91),
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Type de lieu ──
                _SectionLabel('Type de lieu', isRequired: true, isFilled: typeOk),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final t in PlaceType.values)
                        _TypeChip(type: t, vm: vm),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Budget par visite ──
                _SectionLabel('Budget par visite', isRequired: false, isFilled: false),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var lvl = 1; lvl <= 4; lvl++)
                      _LevelChip(
                        label: '€' * lvl,
                        selected: filter.maxPriceLevel == lvl,
                        onTap: () => vm.setMaxPriceLevel(
                          filter.maxPriceLevel == lvl ? null : lvl,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Montant personnalisé
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: _kBorder, height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'ou montant précis',
                        style: TextStyle(
                          color: _kGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: _kBorder, height: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _kAccent,
                    inactiveTrackColor: _kBg,
                    thumbColor: _kAccent,
                    overlayColor: _kAccent.withValues(alpha: 0.15),
                    rangeThumbShape: const RoundRangeSliderThumbShape(
                        enabledThumbRadius: 10),
                    valueIndicatorColor: _kAccent,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    showValueIndicator: ShowValueIndicator.onDrag,
                  ),
                  child: RangeSlider(
                    values: _budgetRange,
                    min: 0,
                    max: _kMaxBudget,
                    divisions: 60,
                    labels: RangeLabels(
                      '${_budgetRange.start.round()}€',
                      _budgetRange.end >= _kMaxBudget
                          ? '${_kMaxBudget.round()}€+'
                          : '${_budgetRange.end.round()}€',
                    ),
                    onChanged: (v) => _updateBudget(vm, v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _budgetCustomActive
                          ? 'Entre ${_budgetRange.start.round()}€ '
                            'et ${_budgetRange.end >= _kMaxBudget ? "${_kMaxBudget.round()}€+" : "${_budgetRange.end.round()}€"}'
                          : 'Tous les budgets',
                      style: TextStyle(
                        color: _budgetCustomActive ? _kAccent : _kGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_budgetCustomActive)
                      GestureDetector(
                        onTap: () => _resetBudget(vm),
                        child: Text(
                          'Effacer',
                          style: TextStyle(
                            color: _kGrey,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),

                // ── Note minimale ──
                const _SectionLabel('Note minimale'),
                const SizedBox(height: 2),
                Text(
                  'note de l\'établissement sur 5',
                  style: TextStyle(
                    color: _kGrey,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _kAccent,
                          inactiveTrackColor: _kBg,
                          thumbColor: _kAccent,
                          overlayColor: _kAccent.withValues(alpha: 0.15),
                          valueIndicatorColor: _kAccent,
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Slider(
                          value: filter.minRating ?? 0,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          label: (filter.minRating ?? 0).toStringAsFixed(1),
                          onChanged: (v) =>
                              vm.setMinRating(v == 0 ? null : v),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        filter.minRating == null
                            ? '—'
                            : '${filter.minRating!.toStringAsFixed(1)} ★',
                        style: const TextStyle(
                          color: _kDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Sections de tags expandables ──
                _ExpandableTagSection(
                  title: 'Ambiance',
                  options: MockDataService.ambianceOptions,
                  isSelected: vm.isAmbianceSelected,
                  onToggle: vm.toggleAmbiance,
                  isRequired: false,
                  isFilled: ambianceOk,
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
                const SizedBox(height: 14),

                // ── Bouton ──
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: isValid ? _kAccent : _kBorder,
                    boxShadow: isValid
                        ? [BoxShadow(color: _kAccent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: isValid ? widget.onConfirm : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Voir la carte',
                            style: TextStyle(
                              color: isValid ? Colors.white : _kGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: isValid ? Colors.white : _kGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isValid) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Sélectionnez un type de lieu pour continuer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _kGrey.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section de tags avec "voir plus / voir moins"
// ─────────────────────────────────────────────────────────────

class _ExpandableTagSection extends StatefulWidget {
  const _ExpandableTagSection({
    required this.title,
    required this.options,
    required this.isSelected,
    required this.onToggle,
    this.isRequired = false,
    this.isFilled = false,
  });

  final String title;
  final List<String> options;
  final bool Function(String) isSelected;
  final void Function(String) onToggle;
  final bool isRequired;
  final bool isFilled;

  @override
  State<_ExpandableTagSection> createState() => _ExpandableTagSectionState();
}

class _ExpandableTagSectionState extends State<_ExpandableTagSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.options.length > _previewCount;
    final visible = _expanded
        ? widget.options
        : widget.options.take(_previewCount).toList();
    final hiddenCount = widget.options.length - _previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(widget.title, isRequired: widget.isRequired, isFilled: widget.isFilled),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in visible)
              _TagChip(
                label: tag,
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
                  style: const TextStyle(
                    color: _kAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _kAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets atomiques (panel clair)
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.isRequired = false, this.isFilled = false});
  final String text;
  final bool isRequired;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: _kGrey,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 7),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isFilled
                  ? const Color(0xFF27AE60).withValues(alpha: 0.12)
                  : _kAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isFilled
                    ? const Color(0xFF27AE60).withValues(alpha: 0.4)
                    : _kAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              isFilled ? '✓' : 'Requis',
              style: TextStyle(
                color: isFilled ? const Color(0xFF27AE60) : _kAccent,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, required this.vm});
  final PlaceType type;
  final PlacesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final selected = vm.filter.type == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => vm.setType(selected ? null : type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _kAccent : _kBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? _kAccent : _kBorder,
              width: 1.2,
            ),
            boxShadow: selected
                ? [BoxShadow(color: _kAccent.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            type.label,
            style: TextStyle(
              color: selected ? Colors.white : _kDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _kAccent : _kBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? _kAccent : _kBorder,
              width: 1.2,
            ),
            boxShadow: selected
                ? [BoxShadow(color: _kAccent.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _kDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kAccent : _kBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kAccent : _kBorder,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _kAccent.withValues(alpha: 0.22), blurRadius: 5, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _kDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
