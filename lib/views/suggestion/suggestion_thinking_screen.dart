import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/suggestion_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'suggestion_result_screen.dart';

/// Ecran "reflexion" : animation pendant que l'algo compose la carte.
class SuggestionThinkingScreen extends StatefulWidget {
  const SuggestionThinkingScreen({super.key, required this.prefs});
  final SuggestionPreferences prefs;

  @override
  State<SuggestionThinkingScreen> createState() =>
      _SuggestionThinkingScreenState();
}

class _SuggestionThinkingScreenState extends State<SuggestionThinkingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();

  static const _steps = [
    'Analyse de vos gouts...',
    'Comparaison des lieux de Paris...',
    'Calcul des correspondances...',
    'Selection des meilleurs spots...',
  ];
  int _step = 0;
  Timer? _stepTimer;
  Timer? _doneTimer;

  @override
  void initState() {
    super.initState();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % _steps.length);
    });
    _doneTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuggestionResultScreen(prefs: widget.prefs),
        ),
      );
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _stepTimer?.cancel();
    _doneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _spin,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.premium, width: 2),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AppColors.premium, size: 48),
                ),
              ),
              const SizedBox(height: 28),
              Text('On compose votre carte',
                  style: AppTypography.title.copyWith(color: Colors.white)),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _steps[_step],
                  key: ValueKey(_step),
                  style: AppTypography.body.copyWith(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white24,
                  color: AppColors.premium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
