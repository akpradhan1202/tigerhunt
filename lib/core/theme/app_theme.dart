import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern theme for TigerHunt - inspired by Chess.com's clean design
class AppTheme {
  // ========== BRAND COLORS ==========

  // Primary palette - Dark sidebar style
  static const Color darkBg = Color(0xFF312E2B);           // Main dark background
  static const Color darkerBg = Color(0xFF272522);         // Darker variant
  static const Color darkestBg = Color(0xFF1E1C1A);        // Darkest (sidebar)
  static const Color cardDark = Color(0xFF3D3A36);         // Card on dark

  // Accent colors
  static const Color greenAccent = Color(0xFF81B64C);      // Primary green (like chess.com)
  static const Color greenDark = Color(0xFF629924);        // Darker green
  static const Color greenLight = Color(0xFFA3D160);       // Lighter green

  // Traditional Indian accent colors
  static const Color saffron = Color(0xFFFF6B35);          // Tiger/warm accent
  static const Color turmeric = Color(0xFFF7C548);         // Gold/yellow accent
  static const Color terracotta = Color(0xFFD4533A);       // Red accent
  static const Color peacockBlue = Color(0xFF1E88E5);      // Blue accent

  // Nature colors
  static const Color forestGreen = Color(0xFF2D5A27);
  static const Color henna = Color(0xFF8B4513);

  // Neutrals
  static const Color cream = Color(0xFFFFF8E7);
  static const Color parchment = Color(0xFFF5E6D3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFE5E5E5);
  static const Color gray = Color(0xFF9E9E9E);
  static const Color darkGray = Color(0xFF757575);
  static const Color charcoal = Color(0xFF2C2C2C);
  static const Color inkBrown = Color(0xFF3D2914);
  static const Color sandalwood = Color(0xFFCEB89A);

  // Game-specific colors
  static const Color tigerOrange = Color(0xFFE86A17);
  static const Color tigerStripe = Color(0xFF1A1A1A);
  static const Color goatWhite = Color(0xFFFFFFFF);        // Pure white for visibility
  static const Color goatGray = Color(0xFF4A4A4A);         // Darker border for contrast

  // Board colors - modern style with visible grid
  static const Color boardLight = Color(0xFFEBECD0);       // Light board background
  static const Color boardDark = Color(0xFF739552);        // Dark squares (green)
  static const Color boardLine = Color(0xFF2D2D2D);        // Dark visible grid lines
  static const Color boardDot = Color(0xFF1A1A1A);         // Dark intersection dots
  static const Color highlightMove = Color(0x8081B64C);
  static const Color highlightCapture = Color(0x80D32F2F);
  static const Color highlightSelected = Color(0x80F7C548);
  static const Color highlightLast = Color(0x60FFFF00);

  // ========== LIGHT THEME ==========
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: greenAccent,
        primaryContainer: greenLight,
        secondary: peacockBlue,
        secondaryContainer: Color(0xFFD0E4FF),
        tertiary: saffron,
        tertiaryContainer: Color(0xFFFFDBD0),
        surface: white,
        onSurface: charcoal,
        error: Color(0xFFBA1A1A),
      ),
      scaffoldBackgroundColor: white,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: greenAccent,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: charcoal,
          side: const BorderSide(color: lightGray, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: _buildTextTheme(charcoal),
      iconTheme: const IconThemeData(color: charcoal, size: 24),
      dividerTheme: const DividerThemeData(color: lightGray, thickness: 1),
    );
  }

  // ========== DARK THEME (Main theme - like Chess.com) ==========
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: greenAccent,
        primaryContainer: greenDark,
        secondary: peacockBlue,
        secondaryContainer: Color(0xFF004B6F),
        tertiary: saffron,
        tertiaryContainer: Color(0xFF7D2B0B),
        surface: darkBg,
        onSurface: white,
        error: Color(0xFFFFB4AB),
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: darkerBg,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: greenAccent,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: white,
          backgroundColor: cardDark,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: _buildTextTheme(white),
      iconTheme: const IconThemeData(color: white, size: 24),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkerBg,
        selectedItemColor: greenAccent,
        unselectedItemColor: gray,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(fontSize: 57, fontWeight: FontWeight.w400, color: color),
      displayMedium: GoogleFonts.poppins(fontSize: 45, fontWeight: FontWeight.w400, color: color),
      displaySmall: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w400, color: color),
      headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w600, color: color),
      headlineMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w500, color: color),
      headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w500, color: color),
      titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500, color: color),
      titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: color),
      titleSmall: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: color),
      labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      labelMedium: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      labelSmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: color),
    );
  }
}

/// Game-specific styling constants
class GameStyles {
  static const double boardPadding = 24.0;   // Increased padding for Level 3 triangles
  static const double lineWidth = 3.0;       // Thicker lines for visibility
  static const double dotRadius = 7.0;       // Larger dots for visibility
  static const double pieceSize = 44.0;      // Slightly larger pieces
  static const double pieceBorderWidth = 3.0; // Thicker border for goat visibility

  static const Duration moveDuration = Duration(milliseconds: 250);
  static const Duration captureDuration = Duration(milliseconds: 400);
  static const Duration highlightDuration = Duration(milliseconds: 150);

  static List<BoxShadow> get pieceShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 4,
      offset: const Offset(1, 2),
    ),
  ];

  static BoxDecoration get boardDecoration => BoxDecoration(
    color: AppTheme.boardLight,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: AppTheme.darkBg, width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
