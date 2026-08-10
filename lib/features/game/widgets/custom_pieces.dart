import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../models/game_models.dart';

/// Beautiful custom-painted tiger piece with traditional Indian art style
class TigerPiece extends StatelessWidget {
  final double size;
  final bool isSelected;
  final bool isHighlighted;

  const TigerPiece({
    super.key,
    this.size = 44,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppTheme.peacockBlue.withOpacity(0.5)
                : Colors.black.withOpacity(0.3),
            blurRadius: isSelected ? 12 : 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _TigerPainter(
          isSelected: isSelected,
          isHighlighted: isHighlighted,
        ),
      ),
    );
  }
}

class _TigerPainter extends CustomPainter {
  final bool isSelected;
  final bool isHighlighted;

  _TigerPainter({
    required this.isSelected,
    required this.isHighlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = AppTheme.tigerOrange
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Tiger stripes (traditional pattern)
    final stripePaint = Paint()
      ..color = AppTheme.tigerStripe
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Vertical stripes
    for (int i = -2; i <= 2; i++) {
      final x = center.dx + i * (radius * 0.25);
      final startY = center.dy - radius * 0.5;
      final endY = center.dy + radius * 0.5;

      final path = Path();
      path.moveTo(x - 3, startY);
      path.quadraticBezierTo(x + 2, center.dy, x - 3, endY);
      canvas.drawPath(path, stripePaint);
    }

    // Face details
    // Eyes
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.25, center.dy - radius * 0.1),
        width: radius * 0.25,
        height: radius * 0.2,
      ),
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.1),
      radius * 0.08,
      pupilPaint,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.25, center.dy - radius * 0.1),
        width: radius * 0.25,
        height: radius * 0.2,
      ),
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.25, center.dy - radius * 0.1),
      radius * 0.08,
      pupilPaint,
    );

    // Nose
    final nosePath = Path();
    nosePath.moveTo(center.dx, center.dy + radius * 0.1);
    nosePath.lineTo(center.dx - radius * 0.1, center.dy + radius * 0.25);
    nosePath.lineTo(center.dx + radius * 0.1, center.dy + radius * 0.25);
    nosePath.close();
    canvas.drawPath(nosePath, pupilPaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Left whiskers
    canvas.drawLine(
      Offset(center.dx - radius * 0.15, center.dy + radius * 0.2),
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.1),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.15, center.dy + radius * 0.25),
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.3),
      whiskerPaint,
    );

    // Right whiskers
    canvas.drawLine(
      Offset(center.dx + radius * 0.15, center.dy + radius * 0.2),
      Offset(center.dx + radius * 0.5, center.dy + radius * 0.1),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.15, center.dy + radius * 0.25),
      Offset(center.dx + radius * 0.5, center.dy + radius * 0.3),
      whiskerPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = isSelected ? AppTheme.peacockBlue : AppTheme.terracotta
      ..strokeWidth = isSelected ? 4 : 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 1.5, borderPaint);

    // Highlight glow
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = AppTheme.turmeric.withOpacity(0.5)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, radius + 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TigerPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected ||
        oldDelegate.isHighlighted != isHighlighted;
  }
}

/// Beautiful custom-painted goat piece with traditional Indian art style
class GoatPiece extends StatelessWidget {
  final double size;
  final bool isSelected;
  final bool isHighlighted;

  const GoatPiece({
    super.key,
    this.size = 44,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppTheme.peacockBlue.withOpacity(0.5)
                : Colors.black.withOpacity(0.3),
            blurRadius: isSelected ? 12 : 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoatPainter(
          isSelected: isSelected,
          isHighlighted: isHighlighted,
        ),
      ),
    );
  }
}

class _GoatPainter extends CustomPainter {
  final bool isSelected;
  final bool isHighlighted;

  _GoatPainter({
    required this.isSelected,
    required this.isHighlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle (cream color)
    final bgPaint = Paint()
      ..color = AppTheme.goatWhite
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Wool texture pattern (dots)
    final woolPaint = Paint()
      ..color = AppTheme.goatGray.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = random.nextDouble() * radius * 0.6;
      final dotRadius = 1.5 + random.nextDouble() * 1.5;

      canvas.drawCircle(
        Offset(
          center.dx + dist * math.cos(angle),
          center.dy + dist * math.sin(angle),
        ),
        dotRadius,
        woolPaint,
      );
    }

    // Horns (curved traditional style)
    final hornPaint = Paint()
      ..color = AppTheme.henna
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Left horn
    final leftHornPath = Path();
    leftHornPath.moveTo(center.dx - radius * 0.2, center.dy - radius * 0.3);
    leftHornPath.quadraticBezierTo(
      center.dx - radius * 0.6,
      center.dy - radius * 0.8,
      center.dx - radius * 0.3,
      center.dy - radius * 0.7,
    );
    canvas.drawPath(leftHornPath, hornPaint);

    // Right horn
    final rightHornPath = Path();
    rightHornPath.moveTo(center.dx + radius * 0.2, center.dy - radius * 0.3);
    rightHornPath.quadraticBezierTo(
      center.dx + radius * 0.6,
      center.dy - radius * 0.8,
      center.dx + radius * 0.3,
      center.dy - radius * 0.7,
    );
    canvas.drawPath(rightHornPath, hornPaint);

    // Face details
    final facePaint = Paint()
      ..color = AppTheme.charcoal
      ..style = PaintingStyle.fill;

    // Eyes
    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy),
      radius * 0.08,
      facePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.2, center.dy),
      radius * 0.08,
      facePaint,
    );

    // Nose
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.25),
        width: radius * 0.2,
        height: radius * 0.15,
      ),
      facePaint,
    );

    // Ears
    final earPaint = Paint()
      ..color = AppTheme.goatGray
      ..style = PaintingStyle.fill;

    // Left ear
    final leftEarPath = Path();
    leftEarPath.moveTo(center.dx - radius * 0.3, center.dy - radius * 0.2);
    leftEarPath.quadraticBezierTo(
      center.dx - radius * 0.7,
      center.dy - radius * 0.2,
      center.dx - radius * 0.5,
      center.dy + radius * 0.1,
    );
    leftEarPath.close();
    canvas.drawPath(leftEarPath, earPaint);

    // Right ear
    final rightEarPath = Path();
    rightEarPath.moveTo(center.dx + radius * 0.3, center.dy - radius * 0.2);
    rightEarPath.quadraticBezierTo(
      center.dx + radius * 0.7,
      center.dy - radius * 0.2,
      center.dx + radius * 0.5,
      center.dy + radius * 0.1,
    );
    rightEarPath.close();
    canvas.drawPath(rightEarPath, earPaint);

    // Border
    final borderPaint = Paint()
      ..color = isSelected ? AppTheme.peacockBlue : AppTheme.forestGreen
      ..strokeWidth = isSelected ? 4 : 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 1.5, borderPaint);

    // Highlight glow
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = AppTheme.turmeric.withOpacity(0.5)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, radius + 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoatPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected ||
        oldDelegate.isHighlighted != isHighlighted;
  }
}

/// Factory method to get the right piece widget
Widget buildPiece(PieceType type, {double size = 44, bool isSelected = false}) {
  switch (type) {
    case PieceType.tiger:
      return TigerPiece(size: size, isSelected: isSelected);
    case PieceType.goat:
      return GoatPiece(size: size, isSelected: isSelected);
  }
}
