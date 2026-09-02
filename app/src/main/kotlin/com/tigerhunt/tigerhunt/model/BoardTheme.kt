package com.tigerhunt.tigerhunt.model

import androidx.compose.ui.graphics.Color

enum class BoardTheme(
    val displayName: String,
    val description: String,
    val boardBackground: Color,
    val surfaceColor: Color,
    val linePrimary: Color,
    val lineSecondary: Color,
    val nodeColor: Color,
    val tigerColor: Color,
    val goatColor: Color,
    val accentHighlight: Color,
    val validMoveColor: Color
) {
    CLASSIC_NEPAL(
        displayName = "Classic Nepal",
        description = "Authentic carved wood & copper tones of the Kathmandu Valley",
        boardBackground = Color(0xFF231810),
        surfaceColor = Color(0xFF332318),
        linePrimary = Color(0xFFC98A4B),
        lineSecondary = Color(0xFF8B5E34),
        nodeColor = Color(0xFFE5AA70),
        tigerColor = Color(0xFFFF7A00),
        goatColor = Color(0xFFEFEFEF),
        accentHighlight = Color(0xFFFFD54F),
        validMoveColor = Color(0xFF66BB6A)
    ),
    GOLDEN_ROYAL(
        displayName = "Golden Royal",
        description = "Gilded brass inlays with royal velvet crimson accents",
        boardBackground = Color(0xFF1A1528),
        surfaceColor = Color(0xFF261E3B),
        linePrimary = Color(0xFFFFD700),
        lineSecondary = Color(0xFF998100),
        nodeColor = Color(0xFFFFE066),
        tigerColor = Color(0xFFFF5252),
        goatColor = Color(0xFFEDE7F6),
        accentHighlight = Color(0xFFFFE57F),
        validMoveColor = Color(0xFF00E676)
    ),
    FOREST_JUNGLE(
        displayName = "Terai Jungle",
        description = "Emerald canopy and bamboo lines of the Bengal Tiger preserve",
        boardBackground = Color(0xFF0E1F12),
        surfaceColor = Color(0xFF162F1D),
        linePrimary = Color(0xFF81C784),
        lineSecondary = Color(0xFF388E3C),
        nodeColor = Color(0xFFA5D6A7),
        tigerColor = Color(0xFFFF9800),
        goatColor = Color(0xFFF1F8E9),
        accentHighlight = Color(0xFFEEFF41),
        validMoveColor = Color(0xFF00E5FF)
    ),
    SLATE_MODERN(
        displayName = "Slate Minimal",
        description = "Crisp obsidian stone and neon amber precision geometry",
        boardBackground = Color(0xFF121417),
        surfaceColor = Color(0xFF1F242B),
        linePrimary = Color(0xFF90A4AE),
        lineSecondary = Color(0xFF455A64),
        nodeColor = Color(0xFFCFD8DC),
        tigerColor = Color(0xFFFF6D00),
        goatColor = Color(0xFFE0E0E0),
        accentHighlight = Color(0xFF40C4FF),
        validMoveColor = Color(0xFF69F0AE)
    ),
    CRIMSON_EMBER(
        displayName = "Crimson Flame",
        description = "Volcanic red clay and molten gold highlights",
        boardBackground = Color(0xFF240E0E),
        surfaceColor = Color(0xFF3B1717),
        linePrimary = Color(0xFFFF6F61),
        lineSecondary = Color(0xFF8E2828),
        nodeColor = Color(0xFFFFAB91),
        tigerColor = Color(0xFFFF3D00),
        goatColor = Color(0xFFFFF3E0),
        accentHighlight = Color(0xFFFFAB00),
        validMoveColor = Color(0xFF76FF03)
    )
}
