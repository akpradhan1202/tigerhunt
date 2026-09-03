package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.data.GamePreferences
import com.tigerhunt.tigerhunt.model.*
import com.tigerhunt.tigerhunt.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChallengesScreen(
    userProfile: UserProfile,
    onSelectPuzzle: (Puzzle) -> Unit,
    onNavigateBack: () -> Unit,
    prefs: GamePreferences,
    modifier: Modifier = Modifier
) {
    var selectedFilter by remember { mutableStateOf("All") }
    val todayDate = remember { DailyChallengeManager.getTodayDateString() }
    val dailyPuzzle = remember(todayDate) { DailyChallengeManager.getDailyPuzzle(todayDate) }
    val isDailySolvedToday = remember(todayDate, userProfile.lastDailyPuzzleDate) {
        prefs.isDailyPuzzleSolvedForDate(todayDate) || userProfile.lastDailyPuzzleDate == todayDate
    }

    val allPuzzles = remember { PuzzleLibrary.allPuzzles }

    val filteredPuzzles = remember(selectedFilter, allPuzzles) {
        when (selectedFilter) {
            "All" -> allPuzzles
            "Sequences" -> allPuzzles.filter { it.sequenceLength >= 2 }
            "Easy" -> allPuzzles.filter { it.difficulty == ChallengeDifficulty.EASY }
            "Medium" -> allPuzzles.filter { it.difficulty == ChallengeDifficulty.MEDIUM }
            "Hard" -> allPuzzles.filter { it.difficulty == ChallengeDifficulty.HARD }
            "Expert" -> allPuzzles.filter { it.difficulty == ChallengeDifficulty.EXPERT }
            else -> allPuzzles
        }
    }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Daily & Tactical Puzzles",
                            fontWeight = FontWeight.Bold,
                            color = HighlightGold,
                            fontSize = 18.sp
                        )

                        // Virtual Currency Balance Chip
                        Surface(
                            shape = RoundedCornerShape(16.dp),
                            color = DarkSurfaceVariant,
                            border = BorderStroke(1.dp, HighlightGold.copy(alpha = 0.5f)),
                            modifier = Modifier.padding(end = 8.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("🪙", fontSize = 14.sp)
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "${userProfile.coins}",
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = HighlightGold
                                )
                            }
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("challenges_back_button")) {
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
                .padding(horizontal = 16.dp)
        ) {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.spacedBy(14.dp),
                contentPadding = PaddingValues(top = 8.dp, bottom = 24.dp)
            ) {
                // ==========================================
                // HERO DAILY MOVE-SEQUENCE CHALLENGE CARD
                // ==========================================
                item {
                    Card(
                        shape = RoundedCornerShape(22.dp),
                        colors = CardDefaults.cardColors(containerColor = DarkSurface),
                        modifier = Modifier
                            .fillMaxWidth()
                            .border(
                                BorderStroke(
                                    1.5.dp,
                                    Brush.horizontalGradient(listOf(HighlightGold, AmberTiger, ValidGreen))
                                ),
                                RoundedCornerShape(22.dp)
                            )
                            .clickable { onSelectPuzzle(dailyPuzzle) }
                            .testTag("daily_challenge_hero_card")
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(
                                    Brush.verticalGradient(
                                        listOf(AmberTigerDark.copy(alpha = 0.35f), DarkSurface)
                                    )
                                )
                                .padding(18.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = AmberTiger.copy(alpha = 0.2f),
                                    border = BorderStroke(1.dp, AmberTigerLight)
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            Icons.Default.LocalFireDepartment,
                                            contentDescription = null,
                                            tint = AmberTigerLight,
                                            modifier = Modifier.size(14.dp)
                                        )
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text(
                                            text = "DAILY MOVE SEQUENCE",
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = AmberTigerLight
                                        )
                                    }
                                }

                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text("🔥", fontSize = 14.sp)
                                    Spacer(modifier = Modifier.width(3.dp))
                                    Text(
                                        text = "${userProfile.dailyStreak} Day Streak",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            Text(
                                text = dailyPuzzle.title,
                                fontWeight = FontWeight.Bold,
                                fontSize = 18.sp,
                                color = Color.White
                            )

                            Spacer(modifier = Modifier.height(4.dp))

                            Text(
                                text = dailyPuzzle.description,
                                fontSize = 13.sp,
                                color = GoatIvoryDark,
                                lineHeight = 18.sp
                            )

                            Spacer(modifier = Modifier.height(14.dp))

                            // Rewards & Info Badges Row
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    // Coin Bounty Badge
                                    Surface(
                                        shape = RoundedCornerShape(10.dp),
                                        color = HighlightGold.copy(alpha = 0.15f),
                                        border = BorderStroke(1.dp, HighlightGold.copy(alpha = 0.5f))
                                    ) {
                                        Row(
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Text("🪙", fontSize = 12.sp)
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Text(
                                                text = "+${dailyPuzzle.coinReward} Coins",
                                                fontSize = 12.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = HighlightGold
                                            )
                                        }
                                    }

                                    // Sequence Steps Badge
                                    Surface(
                                        shape = RoundedCornerShape(10.dp),
                                        color = ValidGreen.copy(alpha = 0.15f),
                                        border = BorderStroke(1.dp, ValidGreen.copy(alpha = 0.4f))
                                    ) {
                                        Text(
                                            text = "⚡ ${dailyPuzzle.sequenceLength} Move${if (dailyPuzzle.sequenceLength > 1) "s" else ""}",
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = ValidGreen,
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                        )
                                    }
                                }

                                Button(
                                    onClick = { onSelectPuzzle(dailyPuzzle) },
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = if (isDailySolvedToday) ValidGreen else AmberTiger
                                    ),
                                    shape = RoundedCornerShape(12.dp),
                                    contentPadding = PaddingValues(horizontal = 14.dp, vertical = 6.dp)
                                ) {
                                    if (isDailySolvedToday) {
                                        Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(16.dp))
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text("Solved", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.White)
                                    } else {
                                        Icon(Icons.Default.PlayArrow, contentDescription = null, modifier = Modifier.size(16.dp))
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text("Solve & Claim", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                                    }
                                }
                            }
                        }
                    }
                }

                // ==========================================
                // CATEGORY & DIFFICULTY FILTER CHIPS
                // ==========================================
                item {
                    val filterOptions = listOf(
                        "All" to "All Puzzles",
                        "Sequences" to "Multi-Move Sequences",
                        "Easy" to "Easy",
                        "Medium" to "Medium",
                        "Hard" to "Hard",
                        "Expert" to "Expert"
                    )

                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(filterOptions) { (key, label) ->
                            FilterChip(
                                selected = selectedFilter == key,
                                onClick = { selectedFilter = key },
                                label = { Text(label, fontSize = 12.sp) },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = AmberTiger,
                                    selectedLabelColor = Color.Black
                                )
                            )
                        }
                    }
                }

                // ==========================================
                // PUZZLE LIST ITEMS
                // ==========================================
                items(filteredPuzzles) { puzzle ->
                    val isSolved = prefs.isSolvedPuzzle(puzzle.id)
                    Card(
                        shape = RoundedCornerShape(18.dp),
                        colors = CardDefaults.cardColors(containerColor = DarkSurface),
                        modifier = Modifier
                            .fillMaxWidth()
                            .border(
                                1.dp,
                                if (isSolved) ValidGreen.copy(alpha = 0.5f) else DarkSurfaceVariant,
                                RoundedCornerShape(18.dp)
                            )
                            .clickable { onSelectPuzzle(puzzle) }
                            .testTag("puzzle_card_${puzzle.id}")
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(46.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (puzzle.playerRole == PieceType.TIGER) AmberTigerDark else DarkSurfaceVariant
                                    )
                                    .border(
                                        1.dp,
                                        if (puzzle.playerRole == PieceType.TIGER) HighlightGold else GoatIvoryDark,
                                        CircleShape
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(if (puzzle.playerRole == PieceType.TIGER) "🐅" else "🐐", fontSize = 22.sp)
                            }

                            Spacer(modifier = Modifier.width(14.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = puzzle.title,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 15.sp,
                                        color = Color.White
                                    )
                                    if (isSolved) {
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Icon(
                                            Icons.Default.CheckCircle,
                                            contentDescription = "Solved",
                                            tint = ValidGreen,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                }

                                Text(
                                    text = puzzle.description,
                                    fontSize = 12.sp,
                                    color = GoatIvoryDark,
                                    maxLines = 2
                                )

                                Spacer(modifier = Modifier.height(6.dp))

                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    // Difficulty tag
                                    Surface(
                                        shape = RoundedCornerShape(6.dp),
                                        color = DarkSurfaceVariant
                                    ) {
                                        Text(
                                            text = puzzle.difficulty.displayName,
                                            fontSize = 10.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = when (puzzle.difficulty) {
                                                ChallengeDifficulty.EASY -> ValidGreen
                                                ChallengeDifficulty.MEDIUM -> HighlightGold
                                                ChallengeDifficulty.HARD -> AmberTiger
                                                ChallengeDifficulty.EXPERT -> NepalRed
                                            },
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }

                                    // Sequence badge
                                    Surface(
                                        shape = RoundedCornerShape(6.dp),
                                        color = ValidGreen.copy(alpha = 0.12f)
                                    ) {
                                        Text(
                                            text = "${puzzle.sequenceLength} Move${if (puzzle.sequenceLength > 1) "s" else ""}",
                                            fontSize = 10.sp,
                                            color = ValidGreen,
                                            fontWeight = FontWeight.Medium,
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }

                                    // Coin reward
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text("🪙", fontSize = 11.sp)
                                        Spacer(modifier = Modifier.width(2.dp))
                                        Text(
                                            text = "+${puzzle.coinReward}",
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = HighlightGold
                                        )
                                    }
                                }
                            }

                            IconButton(onClick = { onSelectPuzzle(puzzle) }) {
                                Icon(
                                    imageVector = Icons.Default.PlayArrow,
                                    contentDescription = "Play",
                                    tint = if (isSolved) ValidGreen else AmberTiger
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
