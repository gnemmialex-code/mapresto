import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/suggestion_preferences.dart';
import '../../services/recommendation_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/places_view_model.dart';
import '../../widgets/primary_button.dart';
import '../place_detail/place_detail_screen.dart';
import '../places/place_card_widget.dart';
import '../maps/mini_map_view.dart';

/// Resultat du questionnaire : carte + classement des meilleurs lieux.
class SuggestionResultScreen extends StatefulWidget {
  const SuggestionResultScreen({super.key, required this.prefs});
  final SuggestionPreferences prefs;

  @override
  State<SuggestionResultScreen> createState() => _SuggestionResultScreenState();
}

class _SuggestionResultScreenState extends State<SuggestionResultScreen> {
  late final List<Recommendation> _recos;

  @override
  void initState() {
    super.initState();
    final places = context.read<PlacesViewModel>().allPlaces;
    _recos = RecommendationService().recommend(widget.prefs, places);
  }

  @override
  Widget build(BuildContext context) {
    final places = _recos.map((r) => r.place).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Votre carte sur-mesure')),
      body: _recos.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun lieu ne correspond. Elargissez vos criteres.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.premium),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_recos.length} lieux selectionnes pour vous',
                        style: AppTypography.subtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MiniMapView(places: places, color: AppColors.primary),
                const SizedBox(height: 16),
                for (var i = 0; i < _recos.length; i++)
                  _RecoCard(reco: _recos[i], rank: i + 1),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Refaire le questionnaire',
                  icon: Icons.refresh,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}

class _RecoCard extends StatelessWidget {
  const _RecoCard({required this.reco, required this.rank});
  final Recommendation reco;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text('$rank',
                    style: AppTypography.tag.copyWith(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.premium.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${reco.matchPercent}% match',
                    style: AppTypography.tag
                        .copyWith(color: AppColors.premium)),
              ),
              if (reco.reasons.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reco.reasons.first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          PlaceCardWidget(
            place: reco.place,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaceDetailScreen(place: reco.place),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
