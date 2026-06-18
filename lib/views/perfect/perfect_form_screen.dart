import 'package:flutter/material.dart';

import '../../models/itinerary.dart';
import '../../services/location_service.dart';
import '../../services/mock_data_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/haptics.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/tag_chip.dart';
import 'perfect_result_screen.dart';

/// Point de depart predefini (evite d'avoir besoin d'un geocodeur).
class _StartPoint {
  final String name;
  final double lat;
  final double lng;
  const _StartPoint(this.name, this.lat, this.lng);
}

/// Formulaire "Adresse parfaite" : midi/soir + depart + preferences.
class PerfectFormScreen extends StatefulWidget {
  const PerfectFormScreen({super.key});

  @override
  State<PerfectFormScreen> createState() => _PerfectFormScreenState();
}

class _PerfectFormScreenState extends State<PerfectFormScreen> {
  static const List<_StartPoint> _points = [
    _StartPoint('Chatelet', 48.8584, 2.3470),
    _StartPoint('Le Marais', 48.8590, 2.3620),
    _StartPoint('Saint-Germain', 48.8540, 2.3340),
    _StartPoint('Bastille', 48.8530, 2.3690),
    _StartPoint('Pigalle', 48.8820, 2.3370),
    _StartPoint('Montmartre', 48.8867, 2.3431),
    _StartPoint('Canal Saint-Martin', 48.8710, 2.3650),
    _StartPoint('Champs-Elysees', 48.8698, 2.3079),
    _StartPoint('Tour Eiffel', 48.8584, 2.2945),
    _StartPoint('Bercy', 48.8330, 2.3820),
  ];

  final LocationService _location = LocationService();

  Moment _moment = Moment.soir;
  bool _useMyLocation = true;
  _StartPoint _start = _points.first;
  final Set<String> _ambiance = {};
  double _maxPrice = 4;
  bool _loading = false;

  Future<void> _submit() async {
    Haptics.medium();
    setState(() => _loading = true);

    double lat;
    double lng;
    String label;
    if (_useMyLocation) {
      final loc = await _location.current();
      lat = loc.latitude;
      lng = loc.longitude;
      label = loc.isReal ? 'Ma position' : 'Paris (position simulee)';
    } else {
      lat = _start.lat;
      lng = _start.lng;
      label = _start.name;
    }

    if (!mounted) return;
    setState(() => _loading = false);

    final request = ItineraryRequest(
      moment: _moment,
      startLat: lat,
      startLng: lng,
      startLabel: label,
      ambiance: _ambiance,
      maxPriceLevel: _maxPrice.round(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PerfectResultScreen(request: request)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adresse parfaite')),
      body: Stack(
        children: [
          ListView(
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
                    const Icon(Icons.route, color: AppColors.premium, size: 30),
                    const SizedBox(height: 10),
                    Text('Votre programme idéal',
                        style:
                            AppTypography.title.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      'On vous trace un itineraire d\'adresses pour un super '
                      'midi ou une belle soiree.',
                      style: AppTypography.body.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Moment
              Text('Pour quand ?', style: AppTypography.subtitle),
              const SizedBox(height: 8),
              SegmentedButton<Moment>(
                segments: const [
                  ButtonSegment(
                    value: Moment.midi,
                    label: Text('Midi'),
                    icon: Icon(Icons.wb_sunny_outlined),
                  ),
                  ButtonSegment(
                    value: Moment.soir,
                    label: Text('Soir'),
                    icon: Icon(Icons.nightlight_outlined),
                  ),
                ],
                selected: {_moment},
                onSelectionChanged: (s) => setState(() => _moment = s.first),
              ),
              const SizedBox(height: 22),

              // Depart
              Text('Point de depart', style: AppTypography.subtitle),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Ma position'),
                    avatar: const Icon(Icons.my_location, size: 16),
                    selected: _useMyLocation,
                    onSelected: (_) => setState(() => _useMyLocation = true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Choisir un lieu'),
                    selected: !_useMyLocation,
                    onSelected: (_) => setState(() => _useMyLocation = false),
                  ),
                ],
              ),
              if (!_useMyLocation) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<_StartPoint>(
                  initialValue: _start,
                  decoration: const InputDecoration(
                    labelText: 'Quartier de depart',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.place),
                  ),
                  items: [
                    for (final p in _points)
                      DropdownMenuItem(value: p, child: Text(p.name)),
                  ],
                  onChanged: (v) => setState(() => _start = v ?? _start),
                ),
              ],
              const SizedBox(height: 22),

              // Ambiance
              Text('Ambiance souhaitee (optionnel)',
                  style: AppTypography.subtitle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in MockDataService.ambianceOptions)
                    TagChip(
                      label: t,
                      selected: _ambiance.contains(t),
                      onTap: () => setState(() => _ambiance.contains(t)
                          ? _ambiance.remove(t)
                          : _ambiance.add(t)),
                    ),
                ],
              ),
              const SizedBox(height: 22),

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
                label: 'Composer mon itineraire',
                icon: Icons.auto_awesome,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
