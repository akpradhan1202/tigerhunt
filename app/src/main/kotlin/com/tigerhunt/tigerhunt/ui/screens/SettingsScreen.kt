package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.model.AIDifficulty
import com.tigerhunt.tigerhunt.model.BoardTheme
import com.tigerhunt.tigerhunt.ui.theme.*
import com.tigerhunt.tigerhunt.viewmodel.GameViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: GameViewModel,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Settings",
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("settings_back_button")) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DarkBackground)
            )
        }
    ) { innerPadding ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // AUDIO & HAPTICS
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "AUDIO & FEEDBACK",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold,
                        letterSpacing = 1.sp
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Sound Effects", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = Color.White)
                            Text("Authentic game piece and audio cues", fontSize = 12.sp, color = GoatIvoryDark)
                        }
                        Switch(
                            checked = uiState.soundEnabled,
                            onCheckedChange = { viewModel.toggleSound() },
                            modifier = Modifier.testTag("sound_effects_switch")
                        )
                    }

                    Divider(color = DarkSurfaceVariant, modifier = Modifier.padding(vertical = 10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Haptic Feedback", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = Color.White)
                            Text("Vibrate on moves and captures", fontSize = 12.sp, color = GoatIvoryDark)
                        }
                        Switch(
                            checked = uiState.hapticsEnabled,
                            onCheckedChange = { viewModel.toggleHaptics() },
                            modifier = Modifier.testTag("haptics_switch")
                        )
                    }
                }
            }

            // BOARD THEMES
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "BOARD THEME",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold,
                        letterSpacing = 1.sp
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    BoardTheme.values().forEach { theme ->
                        val isSelected = uiState.currentTheme == theme
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (isSelected) DarkSurfaceVariant else Color.Transparent,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { viewModel.setTheme(theme) }
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = theme.displayName,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isSelected) HighlightGold else Color.White
                                    )
                                    Text(
                                        text = theme.description,
                                        fontSize = 11.sp,
                                        color = GoatIvoryDark
                                    )
                                }
                                if (isSelected) {
                                    Text("✓", color = HighlightGold, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                                }
                            }
                        }
                    }
                }
            }

            // ABOUT
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Tiger Hunt - Bagh-Chal",
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        color = Color.White
                    )
                    Text(
                        text = "Version 1.0.0 • Modern Android & Jetpack Compose Edition",
                        fontSize = 12.sp,
                        color = GoatIvoryDark
                    )
                }
            }
        }
    }
}
