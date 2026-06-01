import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Superpose un voile "Premium" sur un contenu verrouille (freemium).
///
/// >>> POINT DE BRANCHEMENT PAYWALL <<<
/// Brancher [onUnlock] sur l'ouverture d'un ecran d'achat reel.
class PremiumLockOverlay extends StatelessWidget {
  const PremiumLockOverlay({
    super.key,
    required this.child,
    this.onUnlock,
    this.compact = false,
  });

  final Widget child;
  final VoidCallback? onUnlock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Contenu reel, attenue et non interactif.
        IgnorePointer(
          child: Opacity(opacity: 0.45, child: child),
        ),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: AppColors.lockOverlay.withValues(alpha: 0.55),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, color: Colors.white, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    'Premium',
                    style: AppTypography.subtitle.copyWith(color: Colors.white),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Debloquez tous les lieux',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption
                          .copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onUnlock,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.premium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Debloquer'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
