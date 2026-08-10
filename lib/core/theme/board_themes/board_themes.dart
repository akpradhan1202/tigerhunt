import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Available board themes
enum BoardTheme {
  traditional('Traditional', 'Classic warm earth tones'),
  night('Night Mode', 'Dark theme for night play'),
  diwali('Diwali', 'Festival of lights theme'),
  holi('Holi', 'Festival of colors theme'),
  royal('Royal', 'Elegant gold and purple'),
  nature('Nature', 'Fresh greens and browns'),
  ocean('Ocean', 'Cool blue tones');

  final String name;
  final String description;

  const BoardTheme(this.name, this.description);
}

/// Theme colors for board and pieces
class BoardThemeColors {
  final Color boardBackground;
  final Color boardLine;
  final Color boardDot;
  final Color tigerPrimary;
  final Color tigerSecondary;
  final Color goatPrimary;
  final Color goatSecondary;
  final Color highlightMove;
  final Color highlightCapture;
  final Color highlightSelected;
  final Color borderPrimary;
  final Color borderSecondary;

  const BoardThemeColors({
    required this.boardBackground,
    required this.boardLine,
    required this.boardDot,
    required this.tigerPrimary,
    required this.tigerSecondary,
    required this.goatPrimary,
    required this.goatSecondary,
    required this.highlightMove,
    required this.highlightCapture,
    required this.highlightSelected,
    required this.borderPrimary,
    required this.borderSecondary,
  });

  /// Get theme colors by type
  static BoardThemeColors forTheme(BoardTheme theme) {
    switch (theme) {
      case BoardTheme.traditional:
        return traditional;
      case BoardTheme.night:
        return night;
      case BoardTheme.diwali:
        return diwali;
      case BoardTheme.holi:
        return holi;
      case BoardTheme.royal:
        return royal;
      case BoardTheme.nature:
        return nature;
      case BoardTheme.ocean:
        return ocean;
    }
  }

  /// Traditional theme (default)
  static const traditional = BoardThemeColors(
    boardBackground: Color(0xFFF5E6D3),      // Parchment
    boardLine: Color(0xFF5D4037),            // Brown
    boardDot: Color(0xFF8D6E63),             // Light brown
    tigerPrimary: Color(0xFFE86A17),         // Orange
    tigerSecondary: Color(0xFF1A1A1A),       // Black stripes
    goatPrimary: Color(0xFFF5F5F0),          // Off-white
    goatSecondary: Color(0xFF8B8B8B),        // Gray
    highlightMove: Color(0x6039B54A),        // Green
    highlightCapture: Color(0x60D32F2F),     // Red
    highlightSelected: Color(0x601976D2),   // Blue
    borderPrimary: Color(0xFF8B4513),        // Henna
    borderSecondary: Color(0xFFD4533A),      // Terracotta
  );

  /// Night/Dark theme
  static const night = BoardThemeColors(
    boardBackground: Color(0xFF1E1E1E),      // Dark gray
    boardLine: Color(0xFF4A4A4A),            // Medium gray
    boardDot: Color(0xFF6B6B6B),             // Light gray
    tigerPrimary: Color(0xFFFF8C00),         // Bright orange
    tigerSecondary: Color(0xFF2D2D2D),       // Dark
    goatPrimary: Color(0xFFE0E0E0),          // Light gray
    goatSecondary: Color(0xFF757575),        // Medium gray
    highlightMove: Color(0x6000E676),        // Bright green
    highlightCapture: Color(0x60FF5252),     // Bright red
    highlightSelected: Color(0x6040C4FF),   // Bright blue
    borderPrimary: Color(0xFF424242),        // Gray
    borderSecondary: Color(0xFFFF6D00),      // Amber
  );

  /// Diwali festival theme
  static const diwali = BoardThemeColors(
    boardBackground: Color(0xFF2C1810),      // Deep maroon
    boardLine: Color(0xFFFFD700),            // Gold
    boardDot: Color(0xFFFFE082),             // Light gold
    tigerPrimary: Color(0xFFFF6F00),         // Flame orange
    tigerSecondary: Color(0xFFFFD700),       // Gold
    goatPrimary: Color(0xFFFFF8E1),          // Cream
    goatSecondary: Color(0xFFFFD700),        // Gold
    highlightMove: Color(0x60FFD700),        // Gold
    highlightCapture: Color(0x60FF1744),     // Red
    highlightSelected: Color(0x60E040FB),   // Purple
    borderPrimary: Color(0xFFFFD700),        // Gold
    borderSecondary: Color(0xFFFF6F00),      // Orange
  );

  /// Holi festival theme
  static const holi = BoardThemeColors(
    boardBackground: Color(0xFFFFF9C4),      // Light yellow
    boardLine: Color(0xFF7B1FA2),            // Purple
    boardDot: Color(0xFFE91E63),             // Pink
    tigerPrimary: Color(0xFFFF5722),         // Deep orange
    tigerSecondary: Color(0xFFE91E63),       // Pink
    goatPrimary: Color(0xFF00BCD4),          // Cyan
    goatSecondary: Color(0xFF4CAF50),        // Green
    highlightMove: Color(0x6000E676),        // Green
    highlightCapture: Color(0x60FF5252),     // Red
    highlightSelected: Color(0x60FFEB3B),   // Yellow
    borderPrimary: Color(0xFF9C27B0),        // Purple
    borderSecondary: Color(0xFF4CAF50),      // Green
  );

  /// Royal/Elegant theme
  static const royal = BoardThemeColors(
    boardBackground: Color(0xFF1A1A2E),      // Deep navy
    boardLine: Color(0xFFD4AF37),            // Gold
    boardDot: Color(0xFFFFD700),             // Bright gold
    tigerPrimary: Color(0xFFB8860B),         // Dark gold
    tigerSecondary: Color(0xFF2D2D2D),       // Dark
    goatPrimary: Color(0xFFF5F5F5),          // White
    goatSecondary: Color(0xFF9C27B0),        // Purple
    highlightMove: Color(0x609C27B0),        // Purple
    highlightCapture: Color(0x60F44336),     // Red
    highlightSelected: Color(0x60FFD700),   // Gold
    borderPrimary: Color(0xFFD4AF37),        // Gold
    borderSecondary: Color(0xFF9C27B0),      // Purple
  );

  /// Nature/Forest theme
  static const nature = BoardThemeColors(
    boardBackground: Color(0xFFE8F5E9),      // Light green
    boardLine: Color(0xFF5D4037),            // Brown
    boardDot: Color(0xFF8D6E63),             // Light brown
    tigerPrimary: Color(0xFFFF8F00),         // Amber
    tigerSecondary: Color(0xFF3E2723),       // Dark brown
    goatPrimary: Color(0xFFEFEBE9),          // Light cream
    goatSecondary: Color(0xFF6D4C41),        // Brown
    highlightMove: Color(0x604CAF50),        // Green
    highlightCapture: Color(0x60FF5722),     // Orange
    highlightSelected: Color(0x602196F3),   // Blue
    borderPrimary: Color(0xFF2E7D32),        // Dark green
    borderSecondary: Color(0xFF5D4037),      // Brown
  );

  /// Ocean/Beach theme
  static const ocean = BoardThemeColors(
    boardBackground: Color(0xFFE3F2FD),      // Light blue
    boardLine: Color(0xFF0277BD),            // Ocean blue
    boardDot: Color(0xFF4FC3F7),             // Light cyan
    tigerPrimary: Color(0xFFFF7043),         // Coral
    tigerSecondary: Color(0xFFBF360C),       // Deep coral
    goatPrimary: Color(0xFFF5F5F5),          // White
    goatSecondary: Color(0xFF90A4AE),        // Blue gray
    highlightMove: Color(0x6000BCD4),        // Cyan
    highlightCapture: Color(0x60F44336),     // Red
    highlightSelected: Color(0x60FFAB00),   // Amber
    borderPrimary: Color(0xFF01579B),        // Dark blue
    borderSecondary: Color(0xFF00ACC1),      // Teal
  );
}

/// Board theme preview widget
class BoardThemePreview extends StatelessWidget {
  final BoardTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const BoardThemePreview({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BoardThemeColors.forTheme(theme);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.terracotta : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          children: [
            // Preview board
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: colors.boardBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              child: Stack(
                children: [
                  // Grid lines
                  CustomPaint(
                    size: const Size(100, 70),
                    painter: _PreviewGridPainter(colors),
                  ),
                  // Sample pieces
                  Positioned(
                    left: 15,
                    top: 15,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.tigerPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.tigerSecondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 15,
                    bottom: 15,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: colors.goatPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.goatSecondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Theme name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.terracotta.withOpacity(0.1)
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: Text(
                theme.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.terracotta : AppTheme.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewGridPainter extends CustomPainter {
  final BoardThemeColors colors;

  _PreviewGridPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.boardLine
      ..strokeWidth = 1;

    // Draw simple grid
    for (int i = 0; i < 3; i++) {
      final y = 15 + (i * 20.0);
      canvas.drawLine(Offset(15, y), Offset(size.width - 15, y), paint);
    }
    for (int i = 0; i < 4; i++) {
      final x = 15 + (i * 23.0);
      canvas.drawLine(Offset(x, 15), Offset(x, size.height - 15), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
