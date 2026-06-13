import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_filter_screen.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kGold = Color(0xFFE0B25C);

// ══════════════════════════════════════════════════════════════════════════════
// Main Onboarding Screen
// ══════════════════════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const int _kSlideCount = 5;

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _skip() {
    _controller.animateToPage(
      _kSlideCount,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finish(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const OnboardingFilterScreen(),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Widget _buildSlide(int index) => switch (index) {
    0 => const _WelcomeSlide(),
    1 => const _FeatureSlide(
      title: 'Carte Interactive',
      description:
          'Naviguez sur Paris, filtrez par type, budget ou ambiance.\nChaque lieu s\'ouvre en fiche complète.',
      gradient: [Color(0xFF0B1929), Color(0xFF1C3E6E), Color(0xFF2979D0)],
      mockup: _MapMockup(),
    ),
    2 => const _FeatureSlide(
      title: 'Fiches Vidéo',
      description:
          'Chaque adresse a sa vidéo immersive. Voyez l\'ambiance, les photos et les avis avant même d\'y aller.',
      gradient: [Color(0xFF160B2E), Color(0xFF3D1580), _kPrimary],
      mockup: _VideoMockup(),
    ),
    3 => const _FeatureSlide(
      title: 'Vos Collections',
      description:
          'Créez des listes thématiques, enregistrez vos favoris et partagez-les avec vos proches via un code.',
      gradient: [Color(0xFF0A1F14), Color(0xFF145A32), Color(0xFF1E8449)],
      mockup: _CollectionMockup(),
    ),
    4 => const _FeatureSlide(
      title: 'Autour de Moi',
      description:
          'Géolocalisez-vous et découvrez les meilleures adresses à portée de main, triées par distance.',
      gradient: [Color(0xFF0A0E1E), Color(0xFF16213E), Color(0xFF0F3460)],
      mockup: _AroundMockup(),
    ),
    _ => _ProfilePage(onDone: _finish),
  };

  @override
  Widget build(BuildContext context) {
    final isProfilePage = _page == _kSlideCount;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _kSlideCount + 1,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double page = index.toDouble();
                  if (_controller.hasClients &&
                      _controller.position.haveDimensions) {
                    page = _controller.page ?? index.toDouble();
                  }
                  final dist = (page - index).abs().clamp(0.0, 1.0);
                  final ease = Curves.easeOutCubic.transform(1.0 - dist);
                  return Opacity(
                    opacity: 0.18 + ease * 0.82,
                    child: Transform.scale(
                      scale: 0.93 + ease * 0.07,
                      child: child,
                    ),
                  );
                },
                child: _buildSlide(index),
              );
            },
          ),
          if (!isProfilePage)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomBar(
                page: _page,
                total: _kSlideCount,
                onNext: _next,
                onSkip: _skip,
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Slide 1 : Welcome — cercles animés en fond
// ══════════════════════════════════════════════════════════════════════════════

class _WelcomeSlide extends StatefulWidget {
  const _WelcomeSlide();

  @override
  State<_WelcomeSlide> createState() => _WelcomeSlideState();
}

class _WelcomeSlideState extends State<_WelcomeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value * 2 * math.pi;
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D0014),
                    Color(0xFF1A0533),
                    Color(0xFF3D1280),
                    _kPrimary,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              top: -80 + math.sin(t) * 24.0,
              right: -60 + math.cos(t * 0.75) * 18.0,
              child: _GlowCircle(
                size: 280.0 + math.sin(t * 1.2) * 14.0,
                color: _kPrimary.withValues(
                  alpha: 0.22 + math.sin(t * 0.9) * 0.05,
                ),
              ),
            ),
            Positioned(
              bottom: 140 + math.cos(t * 0.6) * 22.0,
              left: -100 + math.sin(t * 0.7) * 20.0,
              child: _GlowCircle(
                size: 240.0 + math.cos(t * 1.1) * 12.0,
                color: Colors.white.withValues(
                  alpha: 0.04 + math.sin(t * 0.8) * 0.01,
                ),
              ),
            ),
            Positioned(
              top: 220 + math.sin(t * 1.1) * 18.0,
              left: -40 + math.cos(t * 0.85) * 14.0,
              child: _GlowCircle(
                size: 150.0 + math.sin(t * 0.7) * 10.0,
                color: _kGold.withValues(
                  alpha: 0.07 + math.cos(t * 1.1) * 0.02,
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: _kGold,
                  size: 44,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Mapce',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Explorez Paris comme jamais.\nBars, restos, hôtels — en vidéo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 18,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Feature Slide shell
// ══════════════════════════════════════════════════════════════════════════════

class _FeatureSlide extends StatelessWidget {
  const _FeatureSlide({
    required this.title,
    required this.description,
    required this.gradient,
    required this.mockup,
  });

  final String title;
  final String description;
  final List<Color> gradient;
  final Widget mockup;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradient,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: h * 0.38,
          child: Center(child: mockup),
        ),
        Positioned(
          bottom: 116,
          left: 24,
          right: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.13),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mockup 1 : Carte — pins flottants
// ══════════════════════════════════════════════════════════════════════════════

class _MapMockup extends StatefulWidget {
  const _MapMockup();

  @override
  State<_MapMockup> createState() => _MapMockupState();
}

class _MapMockupState extends State<_MapMockup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  static const _pinX = [0.28, 0.56, 0.72, 0.40, 0.18];
  static const _pinY = [0.38, 0.44, 0.28, 0.60, 0.55];
  static const _pinColors = [
    Color(0xFF8C7CFF),
    Color(0xFFE17055),
    Color(0xFF4BA3F0),
    Color(0xFFFD9644),
    Color(0xFF26C281),
  ];
  static const _phases = [0.0, 1.3, 2.6, 0.8, 2.0];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _pin(int i, double t) {
    final dy = math.sin(t + _phases[i]) * 7.0;
    final scale = 1.0 + math.sin(t * 0.8 + _phases[i]) * 0.06;
    return Positioned(
      left: 300 * _pinX[i] - 14,
      top: 330 * _pinY[i] - 14 + dy,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _pinColors[i],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _pinColors[i].withValues(alpha: 0.55),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.place_rounded, color: Colors.white, size: 15),
        ),
      ),
    );
  }

  Widget _filterChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF1A2744),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final t = _ctrl.value * 2 * math.pi;
            return Stack(
              children: [
                CustomPaint(
                  painter: _GridPainter(),
                  size: const Size(300, 330),
                ),
                for (int i = 0; i < 5; i++) _pin(i, t),
                child!,
              ],
            );
          },
          child: Stack(
            children: [
              Positioned(
                top: 14,
                left: 12,
                right: 12,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.search,
                        color: Colors.white.withValues(alpha: 0.55),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rechercher un lieu…',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 62,
                left: 12,
                child: Row(
                  children: [
                    _filterChip('Bar', const Color(0xFF8C7CFF)),
                    const SizedBox(width: 6),
                    _filterChip('Resto', const Color(0xFFE17055)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// Mockup 2 : Vidéo — défilement de cartes de haut en bas
// ══════════════════════════════════════════════════════════════════════════════

class _VideoEntry {
  const _VideoEntry(this.title, this.bg, this.accent, this.type, this.rating, this.price);
  final String title, type, rating;
  final Color bg, accent;
  final int price;
}

class _VideoMockup extends StatefulWidget {
  const _VideoMockup();

  @override
  State<_VideoMockup> createState() => _VideoMockupState();
}

class _VideoMockupState extends State<_VideoMockup>
    with SingleTickerProviderStateMixin {
  // 3 transitions × 4 s = 12 s, puis loop sans glitch (4e carte = copie de la 1re)
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  static const _kCardH = 330.0;

  static const _entries = [
    _VideoEntry('Café de Flore · Saint-Germain', Color(0xFF2D0B5B), Color(0xFF6C5CE7), 'Bar', '4.7', 2),
    _VideoEntry('Septime · Bastille', Color(0xFF0B2D12), Color(0xFF27AE60), 'Restaurant', '4.9', 3),
    _VideoEntry('Hôtel Costes · 1er arr.', Color(0xFF2D1A0B), Color(0xFFE17055), 'Hôtel', '4.5', 4),
    // duplicate pour la boucle invisible
    _VideoEntry('Café de Flore · Saint-Germain', Color(0xFF2D0B5B), Color(0xFF6C5CE7), 'Bar', '4.7', 2),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _card(_VideoEntry e) {
    return SizedBox(
      width: 270,
      height: _kCardH,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [e.bg, e.accent.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Text(
                    e.title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF1A0A2E),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: e.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        e.type,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF1C40F),
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        e.rating,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < 4; i++)
                        Icon(
                          Icons.euro_rounded,
                          color: i < e.price
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.18),
                          size: 13,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: e.accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Voir la fiche →',
                        style: TextStyle(
                          color: e.accent.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: _kCardH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF1A0A2E),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            // 3 transitions sur 12 s — easeInOut par carte
            final progress = _ctrl.value * 3;
            final idx = progress.floor();
            final t = Curves.easeInOut.transform(progress - idx);
            final offset = -(idx + t) * _kCardH;
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [for (final e in _entries) _card(e)],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mockup 3 : Collections — clic interactif → liste des lieux
// ══════════════════════════════════════════════════════════════════════════════

typedef _Place = ({String name, String type, String rating, int price});
typedef _Collection = ({
  String name,
  String count,
  Color color,
  List<_Place> places,
});

class _CollectionMockup extends StatefulWidget {
  const _CollectionMockup();

  @override
  State<_CollectionMockup> createState() => _CollectionMockupState();
}

class _CollectionMockupState extends State<_CollectionMockup> {
  int? _openIndex;

  static final _collections = <_Collection>[
    (
      name: 'Soirée Terrasses',
      count: '8 lieux',
      color: const Color(0xFFFD9644),
      places: <_Place>[
        (name: 'Bar Hemingway', type: 'Bar', rating: '4.9', price: 3),
        (name: 'Le Perchoir', type: 'Bar', rating: '4.7', price: 2),
        (name: 'Café Marly', type: 'Restaurant', rating: '4.6', price: 3),
        (name: 'La Terrasse', type: 'Bar', rating: '4.5', price: 2),
      ],
    ),
    (
      name: 'Brunch du Dimanche',
      count: '5 lieux',
      color: const Color(0xFF26C281),
      places: <_Place>[
        (name: 'Holybelly', type: 'Restaurant', rating: '4.8', price: 2),
        (name: 'Eggs & Co.', type: 'Restaurant', rating: '4.7', price: 1),
        (name: "Bob's Kitchen", type: 'Restaurant', rating: '4.6', price: 1),
        (name: 'Café Oberkampf', type: 'Bar', rating: '4.5', price: 2),
      ],
    ),
    (
      name: 'Paris by Night',
      count: '12 lieux',
      color: const Color(0xFF8C7CFF),
      places: <_Place>[
        (name: 'Silencio', type: 'Bar', rating: '4.8', price: 4),
        (name: 'La Fée Verte', type: 'Bar', rating: '4.7', price: 2),
        (name: 'Rex Club', type: 'Bar', rating: '4.6', price: 3),
        (name: 'Concrete', type: 'Bar', rating: '4.5', price: 2),
      ],
    ),
  ];

  void _toggle(int i) => setState(() => _openIndex = _openIndex == i ? null : i);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF0D1A0D),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          child: _openIndex == null ? _buildList() : _buildDetail(_openIndex!),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Padding(
      key: const ValueKey('list'),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mes Collections',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _collections.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _collectionRow(i),
          ],
        ],
      ),
    );
  }

  Widget _collectionRow(int i) {
    final c = _collections[i];
    return GestureDetector(
      onTap: () => _toggle(i),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.collections_bookmark_rounded, color: c.color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(c.count, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.28), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(int i) {
    final c = _collections[i];
    return Padding(
      key: ValueKey('detail_$i'),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec retour
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggle(i),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: c.color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: c.color, size: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: TextStyle(color: c.color, fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(c.count, style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Liste des lieux
          for (final p in c.places) ...[
            _placeRow(p, c.color),
            const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }

  Widget _placeRow(_Place p, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(Icons.place_rounded, color: accent, size: 14),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
                Text(p.type, style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 9)),
              ],
            ),
          ),
          const Icon(Icons.star_rounded, color: Color(0xFFF1C40F), size: 11),
          const SizedBox(width: 2),
          Text(p.rating, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(width: 7),
          Text('€' * p.price, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mockup 4 : Autour de Moi — pins qui flottent/orbitent
// ══════════════════════════════════════════════════════════════════════════════

class _AroundMockup extends StatefulWidget {
  const _AroundMockup();

  @override
  State<_AroundMockup> createState() => _AroundMockupState();
}

class _AroundMockupState extends State<_AroundMockup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  // Positions originales (dx, dy) depuis le centre (140,140)
  static const _origDx = [0.0, 84.0, 82.0, -82.0, -78.0];
  static const _origDy = [-92.0, -44.0, 48.0, 48.0, -60.0];
  static const _colors = [
    Color(0xFF8C7CFF),
    Color(0xFFE17055),
    Color(0xFF4BA3F0),
    Color(0xFFFD9644),
    Color(0xFF26C281),
  ];
  static const _icons = [
    Icons.local_bar_rounded,
    Icons.restaurant_rounded,
    Icons.hotel_rounded,
    Icons.roofing_rounded,
    Icons.park_rounded,
  ];
  static const _phases = [0.0, 1.2, 2.5, 3.7, 5.0];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _pin(int i, double t) {
    final dx = _origDx[i] + math.sin(t + _phases[i]) * 9.0;
    final dy = _origDy[i] + math.cos(t * 0.85 + _phases[i]) * 8.0;
    final scale = 1.0 + math.sin(t * 0.6 + _phases[i]) * 0.09;
    return Positioned(
      left: 140 + dx - 19,
      top: 140 + dy - 19,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _colors[i],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _colors[i].withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(_icons[i], color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _ring(double scale, double t, double phaseOffset) {
    final pulse = 1.0 + math.sin(t * 0.5 + phaseOffset) * 0.02;
    final baseAlpha = 0.06 + (1 - scale) * 0.06;
    return Transform.scale(
      scale: pulse,
      child: Container(
        width: 280 * scale,
        height: 280 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(
              alpha: baseAlpha + math.sin(t * 0.5 + phaseOffset) * 0.015,
            ),
            width: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value * 2 * math.pi;
        return SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(0.95, t, 0.0),
              _ring(0.68, t, 1.0),
              _ring(0.42, t, 2.0),
              // Pin central (fixe)
              child!,
              // Pins flottants
              for (int i = 0; i < 5; i++) _pin(i, t),
            ],
          ),
        );
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF4BA3F0),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4BA3F0).withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Page Profil "Bienvenue !" — cercles de fond animés
// ══════════════════════════════════════════════════════════════════════════════

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({required this.onDone});
  final void Function(String name, String email) onDone;

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _canSubmit = false;

  late final AnimationController _bgCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_validate);
    _emailCtrl.addListener(_validate);
  }

  void _validate() {
    final ok = _nameCtrl.text.trim().isNotEmpty &&
        _emailCtrl.text.contains('@') &&
        _emailCtrl.text.contains('.');
    if (ok != _canSubmit) setState(() => _canSubmit = ok);
  }

  String get _initials {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E), Color(0xFF160B3A)],
            ),
          ),
        ),
        // Cercles de fond animés
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (context, _) {
            final t = _bgCtrl.value * 2 * math.pi;
            return Stack(
              children: [
                Positioned(
                  top: -70 + math.sin(t) * 22.0,
                  right: -70 + math.cos(t * 0.75) * 16.0,
                  child: _GlowCircle(
                    size: 260.0 + math.sin(t * 1.1) * 12.0,
                    color: _kPrimary.withValues(
                      alpha: 0.14 + math.sin(t * 0.8) * 0.04,
                    ),
                  ),
                ),
                Positioned(
                  bottom: math.cos(t * 0.6) * 18.0,
                  left: -80 + math.sin(t * 0.7) * 16.0,
                  child: _GlowCircle(
                    size: 200.0 + math.cos(t * 0.9) * 10.0,
                    color: _kGold.withValues(
                      alpha: 0.06 + math.cos(t * 1.2) * 0.02,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Contenu
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenue !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Dites-nous qui vous êtes pour\npersonnaliser votre expérience.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 36),
                Center(
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kPrimary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _kGold,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0D0D1A),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                _InputField(
                  label: 'Prénom',
                  controller: _nameCtrl,
                  icon: Icons.person_outline_rounded,
                  hint: 'Votre prénom',
                ),
                const SizedBox(height: 18),
                _InputField(
                  label: 'Email',
                  controller: _emailCtrl,
                  icon: Icons.mail_outline_rounded,
                  hint: 'votre@email.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: _kGold.withValues(alpha: 0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Newsletter gratuite · une sélection de lieux chaque semaine',
                      style: TextStyle(
                        color: _kGold.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canSubmit
                        ? () => widget.onDone(
                              _nameCtrl.text.trim(),
                              _emailCtrl.text.trim(),
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canSubmit ? _kPrimary : Colors.white.withValues(alpha: 0.07),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.07),
                      elevation: _canSubmit ? 10 : 0,
                      shadowColor: _kPrimary.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Découvrir Mapce',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white.withValues(
                            alpha: _canSubmit ? 1.0 : 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () => widget.onDone('', ''),
                    child: Text(
                      'Continuer sans compte',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Input field
// ══════════════════════════════════════════════════════════════════════════════

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.22),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.38),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Bottom navigation bar (dots + bouton suivant)
// ══════════════════════════════════════════════════════════════════════════════

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.page,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final int page;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  bool get _isLast => page == total - 1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == page ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == page
                        ? _kGold
                        : Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                if (page > 0)
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 72),
                const Spacer(),
                GestureDetector(
                  onTap: onNext,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: _isLast ? _kGold : _kPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isLast ? _kGold : _kPrimary).withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isLast ? Icons.person_rounded : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Utilitaire
// ══════════════════════════════════════════════════════════════════════════════

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
