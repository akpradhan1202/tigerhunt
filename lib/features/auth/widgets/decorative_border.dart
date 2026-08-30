import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Decorative Indian-style border element
class DecorativeBorder extends StatelessWidget {
  final bool isBottom;

  const DecorativeBorder({
    super.key,
    this.isBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 40),
      painter: _BorderPainter(isBottom: isBottom),
    );
  }
}

class _BorderPainter extends CustomPainter {
  final bool isBottom;

  _BorderPainter({required this.isBottom});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.henna
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = size.width / 2;
    final y = isBottom ? 0.0 : size.height;

    // Draw horizontal lines
    canvas.drawLine(
      Offset(20, y * 0.4),
      Offset(center - 60, y * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(center + 60, y * 0.4),
      Offset(size.width - 20, y * 0.4),
      paint,
    );

    // Draw center decorative element (lotus-inspired)
    final path = Path();

    // Left petal
    path.moveTo(center - 50, y * 0.4);
    path.quadraticBezierTo(center - 30, y * 0.1, center - 15, y * 0.4);

    // Center petal (larger)
    path.moveTo(center - 20, y * 0.4);
    path.quadraticBezierTo(center, isBottom ? y * 0.8 : y * 0.0, center + 20, y * 0.4);

    // Right petal
    path.moveTo(center + 15, y * 0.4);
    path.quadraticBezierTo(center + 30, y * 0.1, center + 50, y * 0.4);

    canvas.drawPath(path, paint);

    // Draw small dots
    final dotPaint = Paint()
      ..color = AppTheme.terracotta
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center - 40, y * 0.4), 3, dotPaint);
    canvas.drawCircle(Offset(center + 40, y * 0.4), 3, dotPaint);
    canvas.drawCircle(Offset(center, y * 0.4), 4, dotPaint);

    // Corner decorations
    _drawCornerDecoration(canvas, 10, y * 0.4, paint, dotPaint);
    _drawCornerDecoration(canvas, size.width - 10, y * 0.4, paint, dotPaint, mirror: true);
  }

  void _drawCornerDecoration(
    Canvas canvas,
    double x,
    double y,
    Paint linePaint,
    Paint dotPaint, {
    bool mirror = false,
  }) {
    final dir = mirror ? -1.0 : 1.0;

    // Small curved element
    final path = Path();
    path.moveTo(x, y - 8);
    path.quadraticBezierTo(x + (15 * dir), y, x, y + 8);
    canvas.drawPath(path, linePaint);

    canvas.drawCircle(Offset(x + (5 * dir), y), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rangoli-style decorative pattern widget
class RangoliPattern extends StatelessWidget {
  final double size;
  final Color color;

  const RangoliPattern({
    super.key,
    this.size = 100,
    this.color = AppTheme.terracotta,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RangoliPainter(color: color),
    );
  }
}

class _RangoliPainter extends CustomPainter {
  final Color color;

  _RangoliPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw concentric circles
    for (var i = 0.3; i <= 1.0; i += 0.35) {
      canvas.drawCircle(center, radius * i, paint);
    }

    // Draw petals
    for (var i = 0; i < 8; i++) {
      final angle = (i * 45) * 3.14159 / 180;
      final path = Path();

      final startX = center.dx + radius * 0.3 * cos(angle);
      final startY = center.dy + radius * 0.3 * sin(angle);
      final endX = center.dx + radius * 0.95 * cos(angle);
      final endY = center.dy + radius * 0.95 * sin(angle);

      final controlX1 = center.dx + radius * 0.6 * cos(angle - 0.3);
      final controlY1 = center.dy + radius * 0.6 * sin(angle - 0.3);
      final controlX2 = center.dx + radius * 0.6 * cos(angle + 0.3);
      final controlY2 = center.dy + radius * 0.6 * sin(angle + 0.3);

      path.moveTo(startX, startY);
      path.quadraticBezierTo(controlX1, controlY1, endX, endY);
      path.quadraticBezierTo(controlX2, controlY2, startX, startY);

      canvas.drawPath(path, paint);
    }

    // Center dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);
  }

  double cos(double angle) => _cos(angle);
  double sin(double angle) => _sin(angle);

  double _cos(double x) {
    return 1 - (x * x) / 2 + (x * x * x * x) / 24 - (x * x * x * x * x * x) / 720;
  }

  double _sin(double x) {
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
