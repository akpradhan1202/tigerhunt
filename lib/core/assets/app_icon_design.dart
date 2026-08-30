import 'package:flutter/material.dart';

/// App icon design with traditional Indian art motifs
/// Use flutter_launcher_icons to generate actual icons from these designs

class AppIconDesign {
  /// Main app icon colors
  static const Color primaryOrange = Color(0xFFE86A17);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color backgroundCream = Color(0xFFF5E6D3);
  static const Color borderHenna = Color(0xFF8B4513);

  /// Icon design specifications:
  /// - 1024x1024 for iOS
  /// - 512x512 for Android adaptive icon
  /// - Madhubani-style decorative border
  /// - Tiger face in center
  /// - Traditional Indian motifs
}

/// Preview widget showing the app icon design
class AppIconPreview extends StatelessWidget {
  final double size;

  const AppIconPreview({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppIconDesign.backgroundCream,
        borderRadius: BorderRadius.circular(size * 0.22), // iOS icon radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: CustomPaint(
          size: Size(size, size),
          painter: _AppIconPainter(),
        ),
      ),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background gradient
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          AppIconDesign.backgroundCream,
          Color(0xFFE8D5B5),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw Madhubani-style decorative border
    _drawDecorativeBorder(canvas, size);

    // Draw tiger face
    _drawTigerFace(canvas, center, size.width * 0.35);

    // Draw corner decorations
    _drawCornerMotifs(canvas, size);
  }

  void _drawDecorativeBorder(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppIconDesign.borderHenna
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;

    final innerBorderPaint = Paint()
      ..color = AppIconDesign.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.01;

    final padding = size.width * 0.08;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(padding, padding, size.width - 2 * padding, size.height - 2 * padding),
      Radius.circular(size.width * 0.15),
    );

    canvas.drawRRect(rect, borderPaint);

    // Inner decorative line
    final innerPadding = size.width * 0.12;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(innerPadding, innerPadding, size.width - 2 * innerPadding, size.height - 2 * innerPadding),
      Radius.circular(size.width * 0.12),
    );
    canvas.drawRRect(innerRect, innerBorderPaint);
  }

  void _drawTigerFace(Canvas canvas, Offset center, double radius) {
    // Tiger head base (orange)
    final headPaint = Paint()
      ..color = AppIconDesign.primaryOrange
      ..style = PaintingStyle.fill;

    // Simplified stylized tiger face
    final headPath = Path();
    headPath.addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(headPath, headPaint);

    // Ears
    final earPaint = Paint()
      ..color = AppIconDesign.primaryOrange
      ..style = PaintingStyle.fill;

    // Left ear
    final leftEarPath = Path()
      ..moveTo(center.dx - radius * 0.7, center.dy - radius * 0.5)
      ..lineTo(center.dx - radius * 0.9, center.dy - radius * 1.1)
      ..lineTo(center.dx - radius * 0.3, center.dy - radius * 0.7)
      ..close();
    canvas.drawPath(leftEarPath, earPaint);

    // Right ear
    final rightEarPath = Path()
      ..moveTo(center.dx + radius * 0.7, center.dy - radius * 0.5)
      ..lineTo(center.dx + radius * 0.9, center.dy - radius * 1.1)
      ..lineTo(center.dx + radius * 0.3, center.dy - radius * 0.7)
      ..close();
    canvas.drawPath(rightEarPath, earPaint);

    // Tiger stripes
    final stripePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;

    // Forehead stripes
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.3),
      Offset(center.dx, center.dy - radius * 0.6),
      stripePaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.2),
      Offset(center.dx - radius * 0.5, center.dy - radius * 0.5),
      stripePaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.3, center.dy - radius * 0.2),
      Offset(center.dx + radius * 0.5, center.dy - radius * 0.5),
      stripePaint,
    );

    // Eyes
    final eyeWhitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final eyePupilPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.35, center.dy),
        width: radius * 0.35,
        height: radius * 0.25,
      ),
      eyeWhitePaint,
    );
    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy),
      radius * 0.08,
      eyePupilPaint,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.35, center.dy),
        width: radius * 0.35,
        height: radius * 0.25,
      ),
      eyeWhitePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.35, center.dy),
      radius * 0.08,
      eyePupilPaint,
    );

    // Nose
    final nosePaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;

    final nosePath = Path()
      ..moveTo(center.dx, center.dy + radius * 0.15)
      ..lineTo(center.dx - radius * 0.12, center.dy + radius * 0.35)
      ..quadraticBezierTo(
        center.dx, center.dy + radius * 0.45,
        center.dx + radius * 0.12, center.dy + radius * 0.35,
      )
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Mouth/whisker area (white)
    final muzzlePaint = Paint()
      ..color = const Color(0xFFF5F5F0)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.5),
        width: radius * 0.6,
        height: radius * 0.35,
      ),
      muzzlePaint,
    );

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.02;

    // Left whiskers
    canvas.drawLine(
      Offset(center.dx - radius * 0.15, center.dy + radius * 0.4),
      Offset(center.dx - radius * 0.6, center.dy + radius * 0.3),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.15, center.dy + radius * 0.45),
      Offset(center.dx - radius * 0.6, center.dy + radius * 0.45),
      whiskerPaint,
    );

    // Right whiskers
    canvas.drawLine(
      Offset(center.dx + radius * 0.15, center.dy + radius * 0.4),
      Offset(center.dx + radius * 0.6, center.dy + radius * 0.3),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.15, center.dy + radius * 0.45),
      Offset(center.dx + radius * 0.6, center.dy + radius * 0.45),
      whiskerPaint,
    );
  }

  void _drawCornerMotifs(Canvas canvas, Size size) {
    final motifPaint = Paint()
      ..color = AppIconDesign.accentGold
      ..style = PaintingStyle.fill;

    final motifSize = size.width * 0.06;
    final padding = size.width * 0.05;

    // Paisley-inspired dots in corners
    final corners = [
      Offset(padding + motifSize, padding + motifSize),
      Offset(size.width - padding - motifSize, padding + motifSize),
      Offset(padding + motifSize, size.height - padding - motifSize),
      Offset(size.width - padding - motifSize, size.height - padding - motifSize),
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, motifSize * 0.4, motifPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Splash screen design
class SplashScreenDesign extends StatelessWidget {
  const SplashScreenDesign({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF5E6D3), // Parchment
            Color(0xFFE8D5B5), // Darker cream
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          CustomPaint(
            size: Size.infinite,
            painter: _SplashBackgroundPainter(),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon
                const AppIconPreview(size: 150),
                const SizedBox(height: 32),

                // App name
                const Text(
                  'TigerHunt',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'बाघ चाल • The Ancient Game of Strategy',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF8B4513).withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFE86A17).withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom credits
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSmallIcon('🐯'),
                    _buildSmallIcon('🐐'),
                    _buildSmallIcon('🐐'),
                    _buildSmallIcon('🐐'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Inspired by Bagh-Chal',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF8B4513).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIcon(String emoji) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw subtle Warli-inspired patterns
    final spacing = size.width / 8;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Small triangular figures
        if ((x / spacing + y / spacing).toInt() % 3 == 0) {
          _drawWarliTriangle(canvas, Offset(x, y), spacing * 0.3, paint);
        }
      }
    }
  }

  void _drawWarliTriangle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size / 2)
      ..lineTo(center.dx - size / 2, center.dy + size / 2)
      ..lineTo(center.dx + size / 2, center.dy + size / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Adaptive icon foreground (Android)
class AdaptiveIconForeground extends StatelessWidget {
  final double size;

  const AdaptiveIconForeground({super.key, this.size = 108});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AdaptiveForegroundPainter(),
      ),
    );
  }
}

class _AdaptiveForegroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Tiger head (simplified for adaptive icon safe zone)
    final headPaint = Paint()
      ..color = AppIconDesign.primaryOrange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, headPaint);

    // Stripes
    final stripePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.2),
      Offset(center.dx, center.dy - radius * 0.5),
      stripePaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.1),
      Offset(center.dx - radius * 0.45, center.dy - radius * 0.35),
      stripePaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.25, center.dy - radius * 0.1),
      Offset(center.dx + radius * 0.45, center.dy - radius * 0.35),
      stripePaint,
    );

    // Eyes
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy), radius * 0.12, eyePaint);
    canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy), radius * 0.05, pupilPaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.3, center.dy), radius * 0.12, eyePaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.3, center.dy), radius * 0.05, pupilPaint);

    // Nose
    final nosePaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + radius * 0.25), radius * 0.1, nosePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
