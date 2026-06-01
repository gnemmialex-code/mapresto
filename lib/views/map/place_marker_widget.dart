import 'package:flutter/material.dart';

import '../../models/place.dart';
import '../../theme/place_visuals.dart';

/// Pin affiche sur la carte pour un lieu.
/// [locked] = lieu Premium non debloque : pin grise avec un cadenas.
class PlaceMarkerWidget extends StatelessWidget {
  const PlaceMarkerWidget({
    super.key,
    required this.place,
    this.locked = false,
    this.onTap,
  });

  final Place place;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = locked ? Colors.grey : PlaceVisuals.color(place.type);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Icon(
              locked ? Icons.lock : PlaceVisuals.icon(place.type),
              color: Colors.white,
              size: 16,
            ),
          ),
          // Petite pointe sous le pin.
          CustomPaint(
            size: const Size(10, 6),
            painter: _PinTipPainter(color),
          ),
        ],
      ),
    );
  }
}

class _PinTipPainter extends CustomPainter {
  _PinTipPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTipPainter oldDelegate) => oldDelegate.color != color;
}
