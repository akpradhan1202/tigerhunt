package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.R
import com.tigerhunt.tigerhunt.model.*
import com.tigerhunt.tigerhunt.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    userProfile: UserProfile,
    onNavigateToGame: (GameMode, BoardLevel, PieceType, AIDifficulty, GameTimer) -> Unit,
    onNavigateToChallenges: () -> Unit,
    onNavigateToTournaments: () -> Unit,
    onNavigateToTutorial: () -> Unit,
    onNavigateToRules: () -> Unit,
    onNavigateToStats: () -> Unit,
    onNavigateToSettings: () -> Unit,
    modifier: Modifier = Modifier
) {
    var showQuickPlayModal by remember { mutableStateOf(false) }
    var selectedLevel by remember { mutableStateOf(BoardLevel.TRADITIONAL) }
    var selectedSide by remember { mutableStateOf(PieceType.GOAT) }
    var selectedDifficulty by remember { mutableStateOf(AIDifficulty.MEDIUM) }
    var selectedTimer by remember { mutableStateOf(GameTimer.UNLIMITED) }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("🐅", fontSize = 24.sp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Tiger Hunt",
                            fontWeight = FontWeight.Bold,
                            color = HighlightGold
                        )
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToStats, modifier = Modifier.testTag("home_stats_button")) {
                        Icon(Icons.Default.Leaderboard, contentDescription = "Stats", tint = Color.White)
                    }
                    IconButton(onClick = onNavigateToSettings, modifier = Modifier.testTag("home_settings_button")) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings", tint = Color.White)
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
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // HERO BANNER
            Card(
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BoardWoodLight, RoundedCornerShape(24.dp))
            ) {
                Box(modifier = Modifier.fillMaxWidth()) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(20.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Box(
                            modifier = Modifier
                                .size(90.dp)
                                .clip(CircleShape)
                                .background(AmberTigerDark)
                                .border(2.dp, HighlightGold, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Image(
                                painter = painterResource(id = R.drawable.ic_tiger_logo),
                                contentDescription = "Tiger Logo",
                                modifier = Modifier.fillMaxSize(),
                                contentScale = ContentScale.Crop
                            )
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Text(
                            text = "Bagh-Chal: The Royal Hunt",
                            fontWeight = FontWeight.Bold,
                            fontSize = 20.sp,
                            color = Color.White
                        )
                        Text(
                            text = "Ancient Himalayan Strategy Game of Nepal",
                            fontSize = 12.sp,
                            color = GoatIvoryDark
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        // User Stats Summary Badge
                        Surface(
                            shape = RoundedCornerShape(16.dp),
                            color = DarkSurfaceVariant,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text("⭐", fontSize = 16.sp)
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = "${userProfile.rating} ELO",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 14.sp,
                                        color = HighlightGold
                                    )
                                }
                                Text(
                                    text = userProfile.currentRank,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = AmberTigerLight
                                )
                                Text(
                                    text = "${userProfile.totalWins} Wins",
                                    fontSize = 12.sp,
                                    color = GoatIvory
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(18.dp))

                        Button(
                            onClick = { showQuickPlayModal = true },
                            colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                            shape = RoundedCornerShape(16.dp),
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(52.dp)
                                .testTag("quick_play_button")
                        ) {
                            Icon(Icons.Default.PlayArrow, contentDescription = null, tint = Color.Black)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Quick Play vs AI",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.Black
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = "GAME MODES",
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                color = HighlightGold,
                letterSpacing = 1.sp,
                modifier = Modifier.align(Alignment.Start)
            )

            Spacer(modifier = Modifier.height(12.dp))

            // MODE BUTTONS GRID
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                ModeCard(
                    title = "Pass & Play",
                    subtitle = "2 Player Local",
                    icon = "👥",
                    accent = ValidGreen,
                    modifier = Modifier.weight(1f),
                    onClick = {
                        onNavigateToGame(
                            GameMode.PASS_AND_PLAY,
                            BoardLevel.TRADITIONAL,
                            PieceType.GOAT,
                            AIDifficulty.MEDIUM,
                            GameTimer.UNLIMITED
                        )
                    }
                )

                ModeCard(
                    title = "Puzzles",
                    subtitle = "Tactical Challenges",
                    icon = "🧩",
                    accent = HighlightGold,
                    modifier = Modifier.weight(1f),
                    onClick = onNavigateToChallenges
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                ModeCard(
                    title = "Tournament",
                    subtitle = "Elimination Cup",
                    icon = "🏆",
                    accent = AmberTiger,
                    modifier = Modifier.weight(1f),
                    onClick = onNavigateToTournaments
                )

                ModeCard(
                    title = "Tutorial",
                    subtitle = "Learn the Rules",
                    icon = "📜",
                    accent = Color(0xFF00E5FF),
                    modifier = Modifier.weight(1f),
                    onClick = onNavigateToTutorial
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // RULES & LORE CARD
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onNavigateToRules() }
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(42.dp)
                            .clip(CircleShape)
                            .background(DarkSurfaceVariant),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("🏔️", fontSize = 22.sp)
                    }

                    Spacer(modifier = Modifier.width(14.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "History & Bagh-Chal Lore",
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.sp,
                            color = Color.White
                        )
                        Text(
                            text = "Discover the origins and master strategies",
                            fontSize = 12.sp,
                            color = GoatIvoryDark
                        )
                    }

                    Icon(
                        imageVector = Icons.Default.ChevronRight,
                        contentDescription = null,
                        tint = HighlightGold
                    )
                }
            }
        }
    }

    if (showQuickPlayModal) {
        AlertDialog(
            onDismissRequest = { showQuickPlayModal = false },
            containerColor = DarkSurface,
            title = {
                Text(
                    text = "Match Configuration",
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            },
            text = {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .verticalScroll(rememberScrollState())
                ) {
                    Text("Select Board Type", fontWeight = FontWeight.SemiBold, fontSize = 13.sp, color = HighlightGold)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        BoardLevel.values().forEach { level ->
                            FilterChip(
                                selected = selectedLevel == level,
                                onClick = { selectedLevel = level },
                                label = { Text(level.displayName, fontSize = 12.sp) }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Text("Play As Side", fontWeight = FontWeight.SemiBold, fontSize = 13.sp, color = HighlightGold)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        FilterChip(
                            selected = selectedSide == PieceType.GOAT,
                            onClick = { selectedSide = PieceType.GOAT },
                            label = { Text("🐐 Goats (20)", fontSize = 12.sp) }
                        )
                        FilterChip(
                            selected = selectedSide == PieceType.TIGER,
                            onClick = { selectedSide = PieceType.TIGER },
                            label = { Text("🐅 Tigers (4-5)", fontSize = 12.sp) }
                        )
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Text("AI Difficulty", fontWeight = FontWeight.SemiBold, fontSize = 13.sp, color = HighlightGold)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        AIDifficulty.values().forEach { diff ->
                            FilterChip(
                                selected = selectedDifficulty == diff,
                                onClick = { selectedDifficulty = diff },
                                label = { Text(diff.displayName, fontSize = 11.sp) }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Text("Timer Mode", fontWeight = FontWeight.SemiBold, fontSize = 13.sp, color = HighlightGold)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        listOf(GameTimer.UNLIMITED, GameTimer.BLITZ, GameTimer.RAPID).forEach { t ->
                            FilterChip(
                                selected = selectedTimer == t,
                                onClick = { selectedTimer = t },
                                label = { Text(t.label, fontSize = 11.sp) }
                            )
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        showQuickPlayModal = false
                        onNavigateToGame(
                            GameMode.VS_AI,
                            selectedLevel,
                            selectedSide,
                            selectedDifficulty,
                            selectedTimer
                        )
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AmberTiger)
                ) {
                    Text("Start Game", color = Color.Black, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showQuickPlayModal = false }) {
                    Text("Cancel", color = Color.LightGray)
                }
            }
        )
    }
}

@Composable
private fun ModeCard(
    title: String,
    subtitle: String,
    icon: String,
    accent: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        modifier = modifier
            .height(115.dp)
            .border(1.dp, DarkSurfaceVariant, RoundedCornerShape(18.dp))
            .clickable { onClick() }
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(14.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(icon, fontSize = 26.sp)
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(accent)
                )
            }

            Column {
                Text(
                    text = title,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = Color.White
                )
                Text(
                    text = subtitle,
                    fontSize = 11.sp,
                    color = GoatIvoryDark
                )
            }
        }
    }
}
