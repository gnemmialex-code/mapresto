import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Effet "shimmer" anime reutilisable pour les etats de chargement.
///
/// Enveloppe n'importe quel arbre de [Skeleton] (boites grises) et fait
/// glisser un degrade clair par-dessus pour donner l'impression que le
/// contenu se charge. Beaucoup plus rapide percu qu'un simple spinner.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.isDark
        ? const Color(0xFF2A2A33)
        : const Color(0xFFE9E9F0);
    final highlight = AppColors.isDark
        ? const Color(0xFF3A3A47)
        : const Color(0xFFF7F7FB);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width;
            final slide = (_ctrl.value * 2 - 1) * dx;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(slide),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Translation horizontale appliquee au degrade du shimmer.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);
  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// Bloc gris arrondi, brique de base des squelettes.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? const Color(0xFF2A2A33)
            : const Color(0xFFE9E9F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Squelette d'une carte de lieu (reprend la silhouette de PlaceCardWidget).
class SkeletonPlaceCard extends StatelessWidget {
  const SkeletonPlaceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 150, radius: 0),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 170, height: 16),
                SizedBox(height: 10),
                Skeleton(width: 110, height: 12),
                SizedBox(height: 12),
                Row(
                  children: [
                    Skeleton(width: 60, height: 22, radius: 20),
                    SizedBox(width: 8),
                    Skeleton(width: 80, height: 22, radius: 20),
                    SizedBox(width: 8),
                    Skeleton(width: 54, height: 22, radius: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Liste de squelettes de cartes, enveloppee dans le shimmer.
class SkeletonPlaceList extends StatelessWidget {
  const SkeletonPlaceList({super.key, this.count = 4, this.padding});

  final int count;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
        children: [for (var i = 0; i < count; i++) const SkeletonPlaceCard()],
      ),
    );
  }
}
