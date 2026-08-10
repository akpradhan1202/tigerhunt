import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Traditional Indian art inspired theme for TigerHunt
class AppTheme {
  // ========== BRAND COLORS ==========
  // Inspired by traditional Indian art - Madhubani, Warli, and temple art

  // Primary palette - Warm earth tones
  static const Color saffron = Color(0xFFFF6B35);        // Sacred saffron
  static const Color turmeric = Color(0xFFF7C548);       // Turmeric yellow
  static const Color terracotta = Color(0xFFD4533A);     // Terracotta red
  static const Color henna = Color(0xFF8B4513);          // Henna brown

  // Secondary palette - Nature inspired
  static const Color forestGreen = Color(0xFF2D5A27);    // Banyan leaf
  static const Color peacockBlue = Color(0xFF1E6091);    // Peacock feather
  static const Color lotusRose = Color(0xFFE8A0BF);      // Lotus pink
  static const Color skyBlue = Color(0xFF87CEEB);        // Summer sky

  // Neutrals - Natural materials
  static const Color cream = Color(0xFFFFF8E7);          // Unbleached cotton
  static const Color parchment = Color(0xFFF5E6D3);      // Aged paper
  static const Color sandalwood = Color(0xFFCEB89A);     // Sandalwood
  static const Color charcoal = Color(0xFF2C2C2C);       // Ink black
  static const Color inkBrown = Color(0xFF3D2914);       // Natural ink

  // Game-specific colors
  static const Color tigerOrange = Color(0xFFE86A17);    // Tiger piece
  static const Color tigerStripe = Color(0xFF1A1A1A);    // Tiger stripes
  static const Color goatWhite = Color(0xFFF5F5F0);      // Goat piece
  static const Color goatGray = Color(0xFF8B8B8B);       // Goat detail

  // Board colors
  static const Color boardLight = Color(0xFFF5E6D3);     // Board background
  static const Color boardLine = Color(0xFF5D4037);      // Board lines
  static const Color boardDot = Color(0xFF8D6E63);       // Intersection dots
  static const Color highlightMove = Color(0x6039B54A);  // Valid move highlight
  static const Color highlightCapture = Color(0x60D32F2F); // Capture highlight
  static const Color highlightSelected = Color(0x601976D2); // Selected piece

  // ========== LIGHT THEME ==========
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: terracotta,
        primaryContainer: Color(0xFFFFDBD0),
        secondary: forestGreen,
        secondaryContainer: Color(0xFFB8F0B0),
        tertiary: peacockBlue,
        tertiaryContainer: Color(0xFFD0E4FF),
        surface: cream,
        onSurface: charcoal,
        error: Color(0xFFBA1A1A),
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: charcoal,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 4,
        shadowColor: inkBrown.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: terracotta,
          side: const BorderSide(color: terracotta, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: _buildTextTheme(charcoal),
      iconTheme: const IconThemeData(
        color: charcoal,
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: sandalwood.withOpacity(0.5),
        thickness: 1,
      ),
    );
  }

  // ========== DARK THEME ==========
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: saffron,
        primaryContainer: Color(0xFF7D2B0B),
        secondary: Color(0xFF81C784),
        secondaryContainer: Color(0xFF1B5E20),
        tertiary: skyBlue,
        tertiaryContainer: Color(0xFF004B6F),
        surface: Color(0xFF1E1E1E),
        onSurface: parchment,
        error: Color(0xFFFFB4AB),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: parchment,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: parchment,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2C2C2C),
        elevation: 4,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: saffron,
          foregroundColor: charcoal,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: _buildTextTheme(parchment),
      iconTheme: const IconThemeData(
        color: parchment,
        size: 24,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

/// Game-specific styling constants
class GameStyles {
  // Board dimensions
  static const double boardPadding = 20.0;
  static const double lineWidth = 3.0;
  static const double dotRadius = 8.0;
  static const double pieceSize = 44.0;
  static const double pieceBorderWidth = 3.0;

  // Animation durations
  static const Duration moveDuration = Duration(milliseconds: 300);
  static const Duration captureDuration = Duration(milliseconds: 500);
  static const Duration highlightDuration = Duration(milliseconds: 200);

  // Piece shadows
  static List<BoxShadow> get pieceShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(2, 2),
        ),
      ];

  // Border decorations (inspired by Indian patterns)
  static BoxDecoration get boardDecoration => BoxDecoration(
        color: AppTheme.boardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.henna,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkBrown.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      );
}
