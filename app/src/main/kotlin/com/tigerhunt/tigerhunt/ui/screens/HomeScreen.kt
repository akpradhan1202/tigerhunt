package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.R
import com.tigerhunt.tigerhunt.model.*
import com.tigerhunt.tigerhunt.ui.components.PlayerAvatar
import com.tigerhunt.tigerhunt.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    userProfile: UserProfile,
    onNavigateToGame: (GameMode, BoardLevel, PieceType, AIDifficulty, GameTimer) -> Unit,
    onNavigateToPlayLive: () -> Unit,
    onNavigateToPlayFriend: () -> Unit,
    onNavigateToChallenges: () -> Unit,
    onNavigateToTournaments: () -> Unit,
    onNavigateToTutorial: () -> Unit,
    onNavigateToRules: () -> Unit,
    onNavigateToStats: () -> Unit,
    onNavigateToLeaderboard: () -> Unit = {},
    onNavigateToSettings: () -> Unit,
    onNavigateToAuth: () -> Unit,
    modifier: Modifier = Modifier
) {
    var showQuickPlayModal by remember { mutableStateOf(false) }
    var isModesMenuExpanded by remember { mutableStateOf(false) }

    var selectedLevel by remember { mutableStateOf(BoardLevel.SQUARE) }
    var selectedSide by remember { mutableStateOf(PieceType.GOAT) }
    var selectedDifficulty by remember { mutableStateOf(AIDifficulty.MEDIUM) }
    var selectedTimer by remember { mutableStateOf(GameTimer.CLASSIC) }

    val chevronRotation by animateFloatAsState(
        targetValue = if (isModesMenuExpanded) 180f else 0f,
        animationSpec = tween(durationMillis = 250),
        label = "chevron_rotation"
    )

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
                    IconButton(onClick = onNavigateToAuth, modifier = Modifier.testTag("home_auth_button")) {
                        PlayerAvatar(
                            avatarId = userProfile.avatarId,
                            customAvatarUri = userProfile.customAvatarUri,
                            size = 34.dp,
                            fontSize = 16.sp,
                            borderColor = if (userProfile.isLoggedIn) ValidGreen else HighlightGold,
                            borderWidth = 1.5.dp
                        )
                    }
                    IconButton(onClick = onNavigateToLeaderboard, modifier = Modifier.testTag("home_leaderboard_button")) {
                        Icon(Icons.Default.EmojiEvents, contentDescription = "Global Leaderboard", tint = HighlightGold)
                    }
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
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // HERO PROFILE & APP BANNER
            Card(
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BoardWoodLight.copy(alpha = 0.5f), RoundedCornerShape(24.dp))
            ) {
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
                        text = "Ancient Himalayan Strategy Game",
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
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("⭐", fontSize = 14.sp)
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "${userProfile.rating}",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    color = HighlightGold
                                )
                            }
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("🪙", fontSize = 14.sp)
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "${userProfile.coins}",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    color = HighlightGold
                                )
                            }
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("🔥", fontSize = 14.sp)
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "${userProfile.dailyStreak}d",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    color = AmberTigerLight
                                )
                            }
                            Text(
                                text = "${userProfile.totalWins}W",
                                fontSize = 12.sp,
                                color = GoatIvory
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Account status / Login banner
                    Surface(
                        shape = RoundedCornerShape(14.dp),
                        color = if (userProfile.isLoggedIn) DarkSurfaceVariant.copy(alpha = 0.8f) else HighlightGold.copy(alpha = 0.12f),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onNavigateToAuth() }
                            .testTag("home_auth_banner")
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    when (userProfile.authMethod) {
                                        AuthMethod.GMAIL -> "🇬"
                                        AuthMethod.PHONE -> "📱"
                                        AuthMethod.GUEST -> "👤"
                                    },
                                    fontSize = 16.sp
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Column {
                                    Text(
                                        text = if (userProfile.isLoggedIn) userProfile.username else "Playing as Guest",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 13.sp,
                                        color = Color.White
                                    )
                                    Text(
                                        text = if (userProfile.isLoggedIn) "Cloud Synced • Tap to manage" else "Tap to Sign In with Gmail or Mobile",
                                        fontSize = 10.sp,
                                        color = if (userProfile.isLoggedIn) ValidGreen else HighlightGold
                                    )
                                }
                            }

                            Text(
                                text = if (userProfile.isLoggedIn) "Account >" else "Sign In >",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = HighlightGold
                            )
                        }
                    }
                }
            }

            // ==========================================================
            // CHESS.COM STYLE PRIMARY PLAY & COLLAPSIBLE GAME MODES MENU
            // ==========================================================
            Card(
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BoardWoodLight.copy(alpha = 0.6f), RoundedCornerShape(22.dp))
                    .testTag("play_section_card")
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Big Primary Play Button (Chess.com Green / Amber Signature Play Button)
                    Button(
                        onClick = {
                            selectedLevel = BoardLevel.SQUARE
                            showQuickPlayModal = true
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = AmberTiger
                        ),
                        shape = RoundedCornerShape(16.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp)
                            .testTag("quick_play_button")
                    ) {
                        Icon(
                            imageVector = Icons.Default.PlayArrow,
                            contentDescription = null,
                            tint = Color.Black,
                            modifier = Modifier.size(26.dp)
                        )
                        Spacer(modifier = Modifier.width(10.dp))
                        Column(horizontalAlignment = Alignment.Start) {
                            Text(
                                text = "Play Bagh-Chal",
                                fontSize = 17.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = Color.Black
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // Collapsible Header (Toggle all game modes like Chess.com)
                    Surface(
                        shape = RoundedCornerShape(14.dp),
                        color = DarkSurfaceVariant,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .clickable { isModesMenuExpanded = !isModesMenuExpanded }
                            .testTag("game_modes_collapse_toggle")
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 14.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(32.dp)
                                        .clip(CircleShape)
                                        .background(AmberTiger.copy(alpha = 0.2f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Gamepad,
                                        contentDescription = null,
                                        tint = AmberTigerLight,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                                Spacer(modifier = Modifier.width(10.dp))
                                Column {
                                    Text(
                                        text = "Game Modes",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 14.sp,
                                        color = Color.White
                                    )
                                    Text(
                                        text = if (isModesMenuExpanded) "Tap to collapse modes" else "Online, Friends, AI, Tournaments",
                                        fontSize = 11.sp,
                                        color = GoatIvoryDark
                                    )
                                }
                            }

                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = if (isModesMenuExpanded) "Hide" else "Choose",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = HighlightGold
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Icon(
                                    imageVector = Icons.Default.KeyboardArrowDown,
                                    contentDescription = "Toggle Game Modes",
                                    tint = HighlightGold,
                                    modifier = Modifier
                                        .size(20.dp)
                                        .rotate(chevronRotation)
                                )
                            }
                        }
                    }

                    // Collapsible Content List (Chess.com styled expandable menu)
                    AnimatedVisibility(
                        visible = isModesMenuExpanded,
                        enter = fadeIn(animationSpec = tween(200)) + expandVertically(animationSpec = tween(250)),
                        exit = fadeOut(animationSpec = tween(150)) + shrinkVertically(animationSpec = tween(200))
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(top = 12.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            ChessModeItem(
                                title = "Play Online",
                                subtitle = "Live 1v1 matchmaking with players worldwide",
                                icon = "🌐",
                                badge = "LIVE",
                                badgeColor = Color(0xFF00E5FF),
                                onClick = onNavigateToPlayLive,
                                testTag = "mode_item_play_live"
                            )

                            ChessModeItem(
                                title = "Play a Friend",
                                subtitle = "Invite via room code, challenge friends, or Pass & Play",
                                icon = "👥",
                                badge = "MULTIPLAYER",
                                badgeColor = ValidGreen,
                                onClick = onNavigateToPlayFriend,
                                testTag = "mode_item_play_friend"
                            )

                            ChessModeItem(
                                title = "Play vs Computer",
                                subtitle = "Custom AI bots with adaptive difficulties & sides",
                                icon = "🤖",
                                badge = "BOTS",
                                badgeColor = AmberTigerLight,
                                onClick = {
                                    selectedLevel = BoardLevel.SQUARE
                                    showQuickPlayModal = true
                                },
                                testTag = "mode_item_play_ai"
                            )

                            ChessModeItem(
                                title = "Championship Tournaments",
                                subtitle = "Compete in single elimination bracket cups",
                                icon = "👑",
                                badge = "CUPS",
                                badgeColor = HighlightGold,
                                onClick = onNavigateToTournaments,
                                testTag = "mode_item_tournaments"
                            )

                            ChessModeItem(
                                title = "Hunting Puzzles",
                                subtitle = "Solve tactical tiger trap & goat escape scenarios",
                                icon = "🧩",
                                badge = "TACTICS",
                                badgeColor = ValidGreen,
                                onClick = onNavigateToChallenges,
                                testTag = "mode_item_puzzles"
                            )

                            ChessModeItem(
                                title = "Interactive Tutorial",
                                subtitle = "Learn rules, movement mechanics, and traps",
                                icon = "📜",
                                badge = "LEARN",
                                badgeColor = GoatIvory,
                                onClick = onNavigateToTutorial,
                                testTag = "mode_item_tutorial"
                            )
                        }
                    }
                }
            }

            // ==========================================================
            // CHESS.COM STYLE HIGHLIGHT CARDS: PUZZLE OF THE DAY
            // ==========================================================
            val todayDate = remember { DailyChallengeManager.getTodayDateString() }
            val dailyPuzzle = remember(todayDate) { DailyChallengeManager.getDailyPuzzle(todayDate) }
            val isDailySolved = remember(todayDate, userProfile.lastDailyPuzzleDate) {
                userProfile.lastDailyPuzzleDate == todayDate
            }

            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(
                        1.dp,
                        if (isDailySolved) ValidGreen.copy(alpha = 0.6f) else AmberTiger.copy(alpha = 0.5f),
                        RoundedCornerShape(20.dp)
                    )
                    .clickable { onNavigateToChallenges() }
                    .testTag("daily_puzzle_card")
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(52.dp)
                            .clip(RoundedCornerShape(14.dp))
                            .background(
                                if (isDailySolved) ValidGreen.copy(alpha = 0.2f) else AmberTigerDark.copy(alpha = 0.35f)
                            )
                            .border(
                                1.dp,
                                if (isDailySolved) ValidGreen.copy(alpha = 0.6f) else HighlightGold.copy(alpha = 0.6f),
                                RoundedCornerShape(14.dp)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(if (isDailySolved) "✅" else "🔥", fontSize = 26.sp)
                    }

                    Spacer(modifier = Modifier.width(14.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "Daily Tactical Challenge",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = Color.White
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Surface(
                                shape = RoundedCornerShape(6.dp),
                                color = HighlightGold.copy(alpha = 0.18f)
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("🪙", fontSize = 9.sp)
                                    Spacer(modifier = Modifier.width(2.dp))
                                    Text(
                                        text = "+${dailyPuzzle.coinReward}",
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = HighlightGold
                                    )
                                }
                            }
                        }
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = if (isDailySolved) "Solved today! Tap to replay or practice" else "${dailyPuzzle.title} • ${dailyPuzzle.sequenceLength} Move Sequence",
                            fontSize = 12.sp,
                            color = GoatIvoryDark,
                            maxLines = 1
                        )
                    }

                    Icon(
                        imageVector = Icons.Default.ChevronRight,
                        contentDescription = "Solve Puzzle",
                        tint = HighlightGold
                    )
                }
            }

            // ==========================================================
            // CHESS.COM STYLE LEARN & LORE HIGHLIGHT
            // ==========================================================
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Interactive Lessons Card
                Card(
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    modifier = Modifier
                        .weight(1f)
                        .border(1.dp, DarkSurfaceVariant, RoundedCornerShape(18.dp))
                        .clickable { onNavigateToTutorial() }
                        .testTag("learn_lessons_card")
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp)
                    ) {
                        Text("📜", fontSize = 24.sp)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Masterclass",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = Color.White
                        )
                        Text(
                            text = "Learn winning strategies",
                            fontSize = 11.sp,
                            color = GoatIvoryDark
                        )
                    }
                }

                // Himalayan Lore Card
                Card(
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    modifier = Modifier
                        .weight(1f)
                        .border(1.dp, DarkSurfaceVariant, RoundedCornerShape(18.dp))
                        .clickable { onNavigateToRules() }
                        .testTag("history_lore_card")
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp)
                    ) {
                        Text("🏔️", fontSize = 24.sp)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Rules & Lore",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = Color.White
                        )
                        Text(
                            text = "Ancient origins & history",
                            fontSize = 11.sp,
                            color = GoatIvoryDark
                        )
                    }
                }
            }

            // Global Leaderboard Banner Preview
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, DarkSurfaceVariant, RoundedCornerShape(18.dp))
                    .clickable { onNavigateToLeaderboard() }
                    .testTag("leaderboard_banner_card")
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("🏆", fontSize = 24.sp)
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text(
                                text = "Global Leaderboard",
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp,
                                color = Color.White
                            )
                            Text(
                                text = "Top Himalayan Grandmasters",
                                fontSize = 11.sp,
                                color = GoatIvoryDark
                            )
                        }
                    }

                    Text(
                        text = "View All >",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold
                    )
                }
            }
        }
    }

    // MATCH CONFIGURATION DIALOG
    if (showQuickPlayModal) {
        key(showQuickPlayModal) {
            AlertDialog(
                onDismissRequest = { showQuickPlayModal = false },
                containerColor = DarkSurface,
                title = {
                    Text(
                        text = "Quick Match Setup",
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
                        listOf(BoardLevel.SQUARE, BoardLevel.TRADITIONAL, BoardLevel.PYRAMID).forEach { level ->
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
                            label = { Text("🐐 Goats", fontSize = 12.sp) }
                        )
                        FilterChip(
                            selected = selectedSide == PieceType.TIGER,
                            onClick = { selectedSide = PieceType.TIGER },
                            label = { Text("🐅 Tigers", fontSize = 12.sp) }
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
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        items(GameTimer.values().toList()) { t ->
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
}

@Composable
private fun ChessModeItem(
    title: String,
    subtitle: String,
    icon: String,
    badge: String,
    badgeColor: Color,
    onClick: () -> Unit,
    testTag: String
) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = DarkSurfaceVariant.copy(alpha = 0.7f),
        border = BorderStroke(1.dp, BoardWoodLight.copy(alpha = 0.25f)),
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .clickable { onClick() }
            .testTag(testTag)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(DarkSurface),
                contentAlignment = Alignment.Center
            ) {
                Text(icon, fontSize = 20.sp)
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = title,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Surface(
                        shape = RoundedCornerShape(4.dp),
                        color = badgeColor.copy(alpha = 0.2f)
                    ) {
                        Text(
                            text = badge,
                            fontSize = 8.sp,
                            fontWeight = FontWeight.Bold,
                            color = badgeColor,
                            modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                        )
                    }
                }
                Text(
                    text = subtitle,
                    fontSize = 11.sp,
                    color = GoatIvoryDark,
                    maxLines = 1
                )
            }

            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = GoatIvoryDark,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}

