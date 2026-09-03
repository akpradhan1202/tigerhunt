package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.model.*
import com.tigerhunt.tigerhunt.ui.components.PlayerAvatar
import com.tigerhunt.tigerhunt.ui.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.random.Random

val LIVE_OPPONENTS_POOL = listOf(
    OnlineOpponent("p1", "GorkhaTiger", 1240, "Nepal", "🇳🇵", "🐅", "Mountain Master", 28),
    OnlineOpponent("p2", "HimalayanHunter", 1310, "Nepal", "🇳🇵", "🏹", "Apex Predator", 35),
    OnlineOpponent("p3", "KathmanduTactics", 1180, "Nepal", "🇳🇵", "🐐", "Goat Shepherd", 22),
    OnlineOpponent("p4", "VedicStrategist", 1260, "India", "🇮🇳", "👑", "Grand Tactician", 45),
    OnlineOpponent("p5", "SherpaClimber", 1420, "Nepal", "🇳🇵", "🏔️", "Peak Champion", 31),
    OnlineOpponent("p6", "BengalHunter", 1290, "India", "🇮🇳", "🐅", "Forest King", 52),
    OnlineOpponent("p7", "TokyoSensei", 1350, "Japan", "🇯🇵", "⚡", "Speed Master", 88),
    OnlineOpponent("p8", "NordicWolf", 1210, "Norway", "🇳🇴", "🛡️", "Iron Defender", 95),
    OnlineOpponent("p9", "AlpineGoat", 1150, "Switzerland", "🇨🇭", "🐐", "Highland Guard", 110)
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlayLiveScreen(
    userProfile: UserProfile,
    onStartLiveMatch: (level: BoardLevel, timer: GameTimer, opponent: OnlineOpponent, playerSide: PieceType) -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedTimer by remember { mutableStateOf(GameTimer.CLASSIC) }
    var selectedLevel by remember { mutableStateOf(BoardLevel.SQUARE) }
    var selectedSideChoice by remember { mutableStateOf("RANDOM") } // "RANDOM", "TIGER", "GOAT"
    var isSearching by remember { mutableStateOf(false) }
    var searchSeconds by remember { mutableStateOf(0) }
    var matchedOpponent by remember { mutableStateOf<OnlineOpponent?>(null) }
    val coroutineScope = rememberCoroutineScope()

    // Radar pulse animation
    val infiniteTransition = rememberInfiniteTransition(label = "radar")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.6f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "pulse_scale"
    )
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 0.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "pulse_alpha"
    )

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Play Live", fontWeight = FontWeight.Bold, color = HighlightGold)
                        Spacer(modifier = Modifier.width(8.dp))
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = ValidGreen.copy(alpha = 0.2f)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(6.dp)
                                        .clip(CircleShape)
                                        .background(ValidGreen)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("1,428 ONLINE", color = ValidGreen, fontSize = 9.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("play_live_back_button")) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.White)
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
            if (!isSearching && matchedOpponent == null) {
                // RANKED STATUS CARD
                Card(
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, BoardWoodLight, RoundedCornerShape(20.dp))
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(18.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        PlayerAvatar(
                            avatarId = userProfile.avatarId,
                            customAvatarUri = userProfile.customAvatarUri,
                            size = 56.dp,
                            fontSize = 28.sp,
                            borderColor = HighlightGold,
                            borderWidth = 2.dp
                        )

                        Spacer(modifier = Modifier.width(14.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = userProfile.username,
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                color = Color.White
                            )
                            Text(
                                text = "${userProfile.rating} ELO • ${userProfile.currentRank}",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = HighlightGold
                            )
                            Text(
                                text = "Ranked Matchmaking Active",
                                fontSize = 11.sp,
                                color = ValidGreen
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = DarkSurfaceVariant
                        ) {
                            Column(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text("WIN RATE", fontSize = 9.sp, color = GoatIvoryDark, fontWeight = FontWeight.Bold)
                                Text("${userProfile.winRate}%", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.White)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // TIME CONTROL SELECTION
                Text(
                    text = "SELECT TIME CONTROL",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = HighlightGold,
                    letterSpacing = 1.sp,
                    modifier = Modifier.align(Alignment.Start)
                )

                Spacer(modifier = Modifier.height(10.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    listOf(
                        GameTimer.RAPID to ("⏱️ 5m" to "+3s"),
                        GameTimer.CLASSIC to ("⌛ 10m" to "+5s"),
                        GameTimer.STANDARD to ("🏆 30m" to "+10s"),
                        GameTimer.LONG_MATCH to ("🏛️ 1h" to "+15s"),
                        GameTimer.UNLIMITED to ("∞ Casual" to "No Limit")
                    ).forEach { (timer, info) ->
                        val (title, sub) = info
                        val isSelected = selectedTimer == timer
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (isSelected) AmberTiger else DarkSurface,
                            modifier = Modifier
                                .weight(1f)
                                .clickable { selectedTimer = timer }
                                .border(
                                    1.dp,
                                    if (isSelected) HighlightGold else DarkSurfaceVariant,
                                    RoundedCornerShape(12.dp)
                                )
                                .testTag("timer_${timer.name.lowercase()}")
                        ) {
                            Column(
                                modifier = Modifier.padding(vertical = 8.dp, horizontal = 1.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = title,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 10.sp,
                                    color = if (isSelected) Color.Black else Color.White
                                )
                                Text(
                                    text = sub,
                                    fontSize = 8.sp,
                                    color = if (isSelected) Color.Black.copy(alpha = 0.8f) else GoatIvoryDark
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // BOARD LEVEL SELECTION
                Text(
                    text = "SELECT BOARD FORMAT",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = HighlightGold,
                    letterSpacing = 1.sp,
                    modifier = Modifier.align(Alignment.Start)
                )

                Spacer(modifier = Modifier.height(10.dp))

                BoardLevel.values().forEach { level ->
                    val isSelected = selectedLevel == level
                    Surface(
                        shape = RoundedCornerShape(14.dp),
                        color = if (isSelected) DarkSurfaceVariant else DarkSurface,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp)
                            .clickable { selectedLevel = level }
                            .border(
                                1.5.dp,
                                if (isSelected) HighlightGold else Color.Transparent,
                                RoundedCornerShape(14.dp)
                            )
                            .testTag("level_${level.name.lowercase()}")
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = when (level) {
                                    BoardLevel.TRADITIONAL -> "🏔️"
                                    BoardLevel.SQUARE -> "⬛"
                                    BoardLevel.PYRAMID -> "🔺"
                                },
                                fontSize = 24.sp
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = level.displayName + if (level == BoardLevel.TRADITIONAL) " (Official Standard)" else "",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    color = Color.White
                                )
                                Text(
                                    text = "${level.tigerCount} Tigers vs ${level.goatCount} Goats",
                                    fontSize = 11.sp,
                                    color = HighlightGold
                                )
                            }
                            if (isSelected) {
                                Icon(Icons.Default.CheckCircle, contentDescription = null, tint = HighlightGold)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // ROLE PREFERENCE
                Text(
                    text = "SIDE PREFERENCE",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = HighlightGold,
                    letterSpacing = 1.sp,
                    modifier = Modifier.align(Alignment.Start)
                )

                Spacer(modifier = Modifier.height(10.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf(
                        "RANDOM" to "🎲 Random Side",
                        "GOAT" to "🐐 Play as Goats",
                        "TIGER" to "🐅 Play as Tigers"
                    ).forEach { (side, label) ->
                        val isSelected = selectedSideChoice == side
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (isSelected) AmberTiger else DarkSurface,
                            modifier = Modifier
                                .weight(1f)
                                .clickable { selectedSideChoice = side }
                                .border(
                                    1.dp,
                                    if (isSelected) HighlightGold else DarkSurfaceVariant,
                                    RoundedCornerShape(12.dp)
                                )
                        ) {
                            Text(
                                text = label,
                                fontSize = 11.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                color = if (isSelected) Color.Black else Color.White,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(vertical = 12.dp, horizontal = 4.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(28.dp))

                // FIND MATCH BUTTON
                Button(
                    onClick = {
                        isSearching = true
                        searchSeconds = 0
                        coroutineScope.launch {
                            for (i in 1..4) {
                                delay(1000)
                                searchSeconds = i
                            }
                            // Select matching opponent
                            val eligible = LIVE_OPPONENTS_POOL.shuffled().first()
                            matchedOpponent = eligible
                            delay(1200)
                            val finalSide = when (selectedSideChoice) {
                                "TIGER" -> PieceType.TIGER
                                "GOAT" -> PieceType.GOAT
                                else -> if (Random.nextBoolean()) PieceType.GOAT else PieceType.TIGER
                            }
                            onStartLiveMatch(selectedLevel, selectedTimer, eligible, finalSide)
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp)
                        .testTag("find_live_match_button")
                ) {
                    Icon(Icons.Default.Wifi, contentDescription = null, tint = Color.Black)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Find Live Match (${selectedTimer.minutes}m)",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                }
            } else if (isSearching && matchedOpponent == null) {
                // RADAR MATCHMAKING SEARCHING VIEW
                Spacer(modifier = Modifier.height(40.dp))

                Box(
                    modifier = Modifier.size(200.dp),
                    contentAlignment = Alignment.Center
                ) {
                    // Outer pulse rings
                    Box(
                        modifier = Modifier
                            .size(180.dp)
                            .scale(pulseScale)
                            .clip(CircleShape)
                            .background(HighlightGold.copy(alpha = pulseAlpha * 0.4f))
                    )
                    PlayerAvatar(
                        avatarId = userProfile.avatarId,
                        customAvatarUri = userProfile.customAvatarUri,
                        size = 130.dp,
                        fontSize = 48.sp,
                        borderColor = HighlightGold,
                        borderWidth = 2.dp
                    )
                }

                Spacer(modifier = Modifier.height(30.dp))

                Text(
                    text = "Searching for Live Opponent...",
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp,
                    color = Color.White
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "Matching ~${userProfile.rating} ELO • ${selectedTimer.label} • ${selectedLevel.displayName} Board",
                    fontSize = 13.sp,
                    color = HighlightGold
                )

                Spacer(modifier = Modifier.height(6.dp))

                Text(
                    text = "Elapsed Time: 00:0${searchSeconds}s",
                    fontSize = 12.sp,
                    color = GoatIvoryDark
                )

                Spacer(modifier = Modifier.height(40.dp))

                OutlinedButton(
                    onClick = {
                        isSearching = false
                        searchSeconds = 0
                    },
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = NepalRed),
                    modifier = Modifier.testTag("cancel_search_button")
                ) {
                    Icon(Icons.Default.Close, contentDescription = null)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Cancel Search")
                }
            } else if (matchedOpponent != null) {
                // MATCH FOUND SCREEN
                Spacer(modifier = Modifier.height(20.dp))

                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = ValidGreen.copy(alpha = 0.2f),
                    modifier = Modifier.padding(bottom = 20.dp)
                ) {
                    Text(
                        text = "MATCH FOUND! CONNECTING...",
                        color = ValidGreen,
                        fontWeight = FontWeight.Bold,
                        fontSize = 12.sp,
                        letterSpacing = 1.sp,
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp)
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // USER
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        PlayerAvatar(
                            avatarId = userProfile.avatarId,
                            customAvatarUri = userProfile.customAvatarUri,
                            size = 70.dp,
                            fontSize = 36.sp,
                            borderColor = ValidGreen,
                            borderWidth = 2.dp
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(userProfile.username, fontWeight = FontWeight.Bold, color = Color.White, fontSize = 14.sp)
                        Text("${userProfile.rating} ELO", fontSize = 12.sp, color = HighlightGold)
                    }

                    Text("VS", fontWeight = FontWeight.ExtraBold, fontSize = 24.sp, color = HighlightGold)

                    // OPPONENT
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        PlayerAvatar(
                            avatarId = matchedOpponent!!.avatar,
                            size = 70.dp,
                            fontSize = 36.sp,
                            borderColor = AmberTiger,
                            borderWidth = 2.dp
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            "${matchedOpponent!!.countryFlag} ${matchedOpponent!!.name}",
                            fontWeight = FontWeight.Bold,
                            color = Color.White,
                            fontSize = 14.sp
                        )
                        Text("${matchedOpponent!!.rating} ELO", fontSize = 12.sp, color = HighlightGold)
                    }
                }

                Spacer(modifier = Modifier.height(30.dp))

                CircularProgressIndicator(color = HighlightGold, modifier = Modifier.size(24.dp))
                Spacer(modifier = Modifier.height(10.dp))
                Text("Entering Himalayan Arena...", fontSize = 12.sp, color = GoatIvoryDark)
            }
        }
    }
}
