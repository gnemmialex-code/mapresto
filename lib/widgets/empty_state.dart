import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Etat vide soigne et reutilisable.
///
/// Plutot qu'une page blanche ou un simple texte, on propose une icone
/// illustree, un titre, un message d'aide et (optionnellement) une ou deux
/// actions concretes pour sortir de l'impasse (ex: "Elargir le rayon",
/// "Reinitialiser les filtres").
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.accent,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color? accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: compact ? 24 : 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, size: 38, color: color),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (onPrimaryAction != null && primaryActionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onPrimaryAction,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(primaryActionLabel!),
              ),
            ],
            if (onSecondaryAction != null && secondaryActionLabel != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!,
                    style: TextStyle(color: color)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
