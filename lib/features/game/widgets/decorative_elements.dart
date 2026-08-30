import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';

/// Decorative border with traditional Indian patterns (Madhubani/Warli inspired)
class DecorativeGameBorder extends StatelessWidget {
  final Widget child;
  final double borderWidth;

  const DecorativeGameBorder({
    super.key,
    required this.child,
    this.borderWidth = 12,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IndianBorderPainter(borderWidth: borderWidth),
      child: Padding(
        padding: EdgeInsets.all(borderWidth + 4),
        child: child,
      ),
    );
  }
}

class _IndianBorderPainter extends CustomPainter {
  final double borderWidth;

  _IndianBorderPainter({required this.borderWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Outer border
    final outerPaint = Paint()
      ..color = AppTheme.henna
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      outerPaint,
    );

    // Inner border
    final innerRect = rect.deflate(borderWidth);
    final innerPaint = Paint()
      ..color = AppTheme.terracotta
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(12)),
      innerPaint,
    );

    // Draw decorative patterns between borders
    _drawTopBorder(canvas, size);
    _drawBottomBorder(canvas, size);
    _drawLeftBorder(canvas, size);
    _drawRightBorder(canvas, size);
    _drawCorners(canvas, size);
  }

  void _drawTopBorder(Canvas canvas, Size size) {
    final patternPaint = Paint()
      ..color = AppTheme.terracotta.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final y = borderWidth / 2;
    final startX = borderWidth * 2;
    final endX = size.width - borderWidth * 2;
    const spacing = 15.0;

    for (double x = startX; x < endX; x += spacing) {
      // Small triangles
      final path = Path();
      path.moveTo(x, y - 3);
      path.lineTo(x + 6, y + 3);
      path.lineTo(x - 6, y + 3);
      path.close();
      canvas.drawPath(path, patternPaint);
    }
  }

  void _drawBottomBorder(Canvas canvas, Size size) {
    final patternPaint = Paint()
      ..color = AppTheme.terracotta.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final y = size.height - borderWidth / 2;
    final startX = borderWidth * 2;
    final endX = size.width - borderWidth * 2;
    const spacing = 15.0;

    for (double x = startX; x < endX; x += spacing) {
      // Small triangles (inverted)
      final path = Path();
      path.moveTo(x, y + 3);
      path.lineTo(x + 6, y - 3);
      path.lineTo(x - 6, y - 3);
      path.close();
      canvas.drawPath(path, patternPaint);
    }
  }

  void _drawLeftBorder(Canvas canvas, Size size) {
    final patternPaint = Paint()
      ..color = AppTheme.terracotta.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final x = borderWidth / 2;
    final startY = borderWidth * 2;
    final endY = size.height - borderWidth * 2;
    const spacing = 15.0;

    for (double y = startY; y < endY; y += spacing) {
      // Small diamonds
      final path = Path();
      path.moveTo(x, y);
      path.lineTo(x + 4, y + 4);
      path.lineTo(x, y + 8);
      path.lineTo(x - 4, y + 4);
      path.close();
      canvas.drawPath(path, patternPaint);
    }
  }

  void _drawRightBorder(Canvas canvas, Size size) {
    final patternPaint = Paint()
      ..color = AppTheme.terracotta.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final x = size.width - borderWidth / 2;
    final startY = borderWidth * 2;
    final endY = size.height - borderWidth * 2;
    const spacing = 15.0;

    for (double y = startY; y < endY; y += spacing) {
      // Small diamonds
      final path = Path();
      path.moveTo(x, y);
      path.lineTo(x + 4, y + 4);
      path.lineTo(x, y + 8);
      path.lineTo(x - 4, y + 4);
      path.close();
      canvas.drawPath(path, patternPaint);
    }
  }

  void _drawCorners(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.terracotta
      ..style = PaintingStyle.fill;

    // Offset corners inward to prevent clipping
    final cornerOffset = borderWidth + 8;
    final cornerRadius = borderWidth * 0.5;

    // Top-left corner flower
    _drawLotusCorner(canvas, Offset(cornerOffset, cornerOffset), cornerRadius, paint);

    // Top-right corner flower
    _drawLotusCorner(
        canvas, Offset(size.width - cornerOffset, cornerOffset), cornerRadius, paint);

    // Bottom-left corner flower
    _drawLotusCorner(
        canvas, Offset(cornerOffset, size.height - cornerOffset), cornerRadius, paint);

    // Bottom-right corner flower
    _drawLotusCorner(
        canvas,
        Offset(size.width - cornerOffset, size.height - cornerOffset),
        cornerRadius,
        paint);
  }

  void _drawLotusCorner(Canvas canvas, Offset center, double radius, Paint paint) {
    // Draw lotus-like flower pattern
    const petalCount = 8;
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi) / petalCount;
      final path = Path();

      final startX = center.dx + radius * 0.3 * math.cos(angle);
      final startY = center.dy + radius * 0.3 * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);

      final control1X = center.dx + radius * 0.7 * math.cos(angle - 0.3);
      final control1Y = center.dy + radius * 0.7 * math.sin(angle - 0.3);
      final control2X = center.dx + radius * 0.7 * math.cos(angle + 0.3);
      final control2Y = center.dy + radius * 0.7 * math.sin(angle + 0.3);

      path.moveTo(startX, startY);
      path.quadraticBezierTo(control1X, control1Y, endX, endY);
      path.quadraticBezierTo(control2X, control2Y, startX, startY);

      canvas.drawPath(
          path,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    // Center dot
    canvas.drawCircle(center, radius * 0.2, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Warli-style dancing figures for decoration
class WarliDecoration extends StatelessWidget {
  final double size;
  final Color color;

  const WarliDecoration({
    super.key,
    this.size = 60,
    this.color = AppTheme.henna,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WarliPainter(color: color),
    );
  }
}

class _WarliPainter extends CustomPainter {
  final Color color;

  _WarliPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Head (triangle)
    final headPath = Path();
    headPath.moveTo(center.dx, center.dy - size.height * 0.3);
    headPath.lineTo(center.dx - size.width * 0.1, center.dy - size.height * 0.15);
    headPath.lineTo(center.dx + size.width * 0.1, center.dy - size.height * 0.15);
    headPath.close();
    canvas.drawPath(headPath, fillPaint);

    // Body (triangle)
    final bodyPath = Path();
    bodyPath.moveTo(center.dx, center.dy - size.height * 0.1);
    bodyPath.lineTo(center.dx - size.width * 0.2, center.dy + size.height * 0.15);
    bodyPath.lineTo(center.dx + size.width * 0.2, center.dy + size.height * 0.15);
    bodyPath.close();
    canvas.drawPath(bodyPath, fillPaint);

    // Arms (lines)
    canvas.drawLine(
      Offset(center.dx - size.width * 0.15, center.dy),
      Offset(center.dx - size.width * 0.35, center.dy - size.height * 0.15),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + size.width * 0.15, center.dy),
      Offset(center.dx + size.width * 0.35, center.dy - size.height * 0.15),
      paint,
    );

    // Legs (lines)
    canvas.drawLine(
      Offset(center.dx - size.width * 0.1, center.dy + size.height * 0.15),
      Offset(center.dx - size.width * 0.2, center.dy + size.height * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + size.width * 0.1, center.dy + size.height * 0.15),
      Offset(center.dx + size.width * 0.2, center.dy + size.height * 0.4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paisley pattern for decorations
class PaisleyDecoration extends StatelessWidget {
  final double size;
  final Color color;

  const PaisleyDecoration({
    super.key,
    this.size = 40,
    this.color = AppTheme.terracotta,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.5),
      painter: _PaisleyPainter(color: color),
    );
  }
}

class _PaisleyPainter extends CustomPainter {
  final Color color;

  _PaisleyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Paisley shape
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.cubicTo(
      size.width * 0.9,
      size.height * 0.2,
      size.width * 0.9,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.9,
    );
    path.cubicTo(
      size.width * 0.2,
      size.height * 0.7,
      size.width * 0.3,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.1,
    );

    canvas.drawPath(path, paint);

    // Inner decorations
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.35),
      size.width * 0.08,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.55),
      size.width * 0.06,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.7),
      size.width * 0.04,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mandala-style circular decoration
class MandalaDecoration extends StatelessWidget {
  final double size;
  final Color color;

  const MandalaDecoration({
    super.key,
    this.size = 80,
    this.color = AppTheme.terracotta,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MandalaPainter(color: color),
    );
  }
}

class _MandalaPainter extends CustomPainter {
  final Color color;

  _MandalaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Concentric circles
    for (double r = 0.2; r <= 1.0; r += 0.2) {
      canvas.drawCircle(center, radius * r, paint);
    }

    // Petals
    const petalCount = 12;
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi) / petalCount;
      final nextAngle = ((i + 1) * 2 * math.pi) / petalCount;
      final midAngle = (angle + nextAngle) / 2;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + radius * 0.8 * math.cos(angle),
        center.dy + radius * 0.8 * math.sin(angle),
      );
      path.quadraticBezierTo(
        center.dx + radius * 1.1 * math.cos(midAngle),
        center.dy + radius * 1.1 * math.sin(midAngle),
        center.dx + radius * 0.8 * math.cos(nextAngle),
        center.dy + radius * 0.8 * math.sin(nextAngle),
      );
      path.close();

      canvas.drawPath(path, paint);
      if (i % 2 == 0) {
        canvas.drawPath(path, fillPaint);
      }
    }

    // Center
    canvas.drawCircle(center, radius * 0.15, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
