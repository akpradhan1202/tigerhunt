import 'package:flutter/material.dart';

/// Overlay that highlights a specific area during tutorial
class TutorialOverlay extends StatelessWidget {
  final Rect highlightArea;
  final Animation<double> animation;

  const TutorialOverlay({
    super.key,
    required this.highlightArea,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _OverlayPainter(highlightArea: highlightArea),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect highlightArea;

  _OverlayPainter({required this.highlightArea});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    // Create path with hole for highlight
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          highlightArea.inflate(8),
          const Radius.circular(12),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw highlight border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        highlightArea.inflate(8),
        const Radius.circular(12),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
