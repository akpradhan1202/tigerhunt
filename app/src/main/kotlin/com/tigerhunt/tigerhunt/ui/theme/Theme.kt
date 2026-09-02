package com.tigerhunt.tigerhunt.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = AmberTiger,
    onPrimary = Color.Black,
    primaryContainer = AmberTigerDark,
    onPrimaryContainer = AmberTigerLight,
    secondary = BoardLineGold,
    onSecondary = Color.Black,
    secondaryContainer = BoardWoodLight,
    onSecondaryContainer = HighlightGold,
    tertiary = NepalRed,
    onTertiary = Color.White,
    background = DarkBackground,
    onBackground = Color.White,
    surface = DarkSurface,
    onSurface = Color.White,
    surfaceVariant = DarkSurfaceVariant,
    onSurfaceVariant = GoatIvoryDark
)

@Composable
fun TigerHuntTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = Typography,
        content = content
    )
}
