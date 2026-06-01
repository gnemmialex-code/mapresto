import 'package:flutter/material.dart';

import '../../models/place.dart';
import '../../models/suggestion_preferences.dart';
import '../../services/mock_data_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/tag_chip.dart';
import 'suggestion_thinking_screen.dart';

/// Questionnaire "carte sur-mesure" : l'utilisateur decrit ce qu'il cherche.
class SuggestionFormScreen extends StatefulWidget {
  const SuggestionFormScreen({super.key});

  @override
  State<SuggestionFormScreen> createState() => _SuggestionFormScreenState();
}

class _SuggestionFormScreenState extends State<SuggestionFormScreen> {
  PlaceType? _type;
  final Set<String> _ambiance = {};
  final Set<String> _style = {};
  final Set<String> _crowd = {};
  final Set<String> _music = {};
  double _maxPrice = 4;

  void _toggle(Set<String> set, String tag) {
    setState(() => set.contains(tag) ? set.remove(tag) : set.add(tag));
  }

  void _submit() {
    final prefs = SuggestionPreferences(
      type: _type,
      ambiance: _ambiance,
      style: _style,
      crowd: _crowd,
      music: _music,
      maxPriceLevel: _maxPrice.round(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SuggestionThinkingScreen(prefs: prefs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte sur-mesure')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.premium, size: 30),
                const SizedBox(height: 10),
                Text('Dites-nous ce que vous aimez',
                    style: AppTypography.title.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  'On compose une carte avec les lieux faits pour vous.',
                  style: AppTypography.body.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Type
          Text('Je cherche...', style: AppTypography.subtitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _typeChip('Peu importe', null),
              for (final t in PlaceType.values) _typeChip(t.label, t),
            ],
          ),
          const SizedBox(height: 22),

          _TagQuestion(
            title: 'Quelle ambiance ?',
            options: MockDataService.ambianceOptions,
            selected: _ambiance,
            onToggle: (t) => _toggle(_ambiance, t),
          ),
          _TagQuestion(
            title: 'Style / cuisine ?',
            options: MockDataService.styleOptions,
            selected: _style,
            onToggle: (t) => _toggle(_style, t),
          ),
          _TagQuestion(
            title: 'Avec qui / quel public ?',
            options: MockDataService.crowdOptions,
            selected: _crowd,
            onToggle: (t) => _toggle(_crowd, t),
          ),
          _TagQuestion(
            title: 'Une ambiance musicale ?',
            options: MockDataService.musicOptions,
            selected: _music,
            onToggle: (t) => _toggle(_music, t),
          ),

          // Budget
          Text('Budget maximum', style: AppTypography.subtitle),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _maxPrice,
                  min: 1,
                  max: 4,
                  divisions: 3,
                  label: '€' * _maxPrice.round(),
                  onChanged: (v) => setState(() => _maxPrice = v),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text('€' * _maxPrice.round(),
                    style: AppTypography.subtitle),
              ),
            ],
          ),
          const SizedBox(height: 16),

          PrimaryButton(
            label: 'Voir ma carte sur-mesure',
            icon: Icons.map,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _typeChip(String label, PlaceType? value) {
    final selected = _type == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      labelStyle: AppTypography.tag.copyWith(
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      showCheckmark: false,
      onSelected: (_) => setState(() => _type = value),
    );
  }
}

class _TagQuestion extends StatelessWidget {
  const _TagQuestion({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.subtitle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in options)
              TagChip(
                label: t,
                selected: selected.contains(t),
                onTap: () => onToggle(t),
              ),
          ],
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}
