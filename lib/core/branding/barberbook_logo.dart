import 'package:flutter/material.dart';

/// BarberBook mark: rounded tile + crossed blades (brand #1A1A2E / #E94560).
///
/// Use [showTile] false for a transparent-background mark on gradients.
class BarberBookLogo extends StatelessWidget {
  /// Creates the logo at [size]×[size] logical pixels.
  const BarberBookLogo({
    super.key,
    this.size = 96,
    this.showTile = true,
  });

  /// Shortest side of the square logo.
  final double size;

  /// When true, draws the dark rounded app-icon tile behind the mark.
  final bool showTile;

  static const Color _primary = Color(0xFF1A1A2E);
  static const Color _accent = Color(0xFFE94560);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BarberBookLogoPainter(
          showTile: showTile,
          primary: _primary,
          accent: _accent,
        ),
      ),
    );
  }
}

class _BarberBookLogoPainter extends CustomPainter {
  _BarberBookLogoPainter({
    required this.showTile,
    required this.primary,
    required this.accent,
  });

  final bool showTile;
  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.shortestSide;
    final c = size.center(Offset.zero);

    if (showTile) {
      final tileR = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(w * 0.219),
      );
      canvas.drawRRect(tileR, Paint()..color = primary);
    }

    canvas.save();
    canvas.translate(c.dx, c.dy);

    final bladeW = w * 0.0703;
    final bladeH = w * 0.547;
    final bladePaint = Paint()..color = accent;

    for (final turns in [0.5934, -0.5934]) {
      canvas.save();
      canvas.rotate(turns);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: bladeW,
          height: bladeH,
        ),
        Radius.circular(bladeW / 2),
      );
      canvas.drawRRect(rect, bladePaint);
      canvas.restore();
    }

    if (showTile) {
      canvas.drawCircle(Offset.zero, w * 0.043, Paint()..color = primary);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BarberBookLogoPainter oldDelegate) {
    return oldDelegate.showTile != showTile ||
        oldDelegate.primary != primary ||
        oldDelegate.accent != accent;
  }
}
