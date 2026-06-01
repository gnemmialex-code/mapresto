import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Petite puce affichant un tag (ambiance, musique, style...).
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.color,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? base : base.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: base.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: AppTypography.tag.copyWith(
            color: selected ? Colors.white : base,
          ),
        ),
      ),
    );
  }
}
