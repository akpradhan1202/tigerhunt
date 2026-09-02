package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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
    onSelectPuzzle: (Puzzle) -> Unit,
    onNavigateBack: () -> Unit,
    prefs: GamePreferences,
    modifier: Modifier = Modifier
) {
    var selectedDifficulty by remember { mutableStateOf<ChallengeDifficulty?>(null) }
    val puzzles = remember { PuzzleLibrary.allPuzzles }

    val filteredPuzzles = remember(selectedDifficulty) {
        if (selectedDifficulty == null) puzzles else puzzles.filter { it.difficulty == selectedDifficulty }
    }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Tactical Puzzles",
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("challenges_back_button")) {
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
                .padding(horizontal = 16.dp)
        ) {
            // Difficulty Chips
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = selectedDifficulty == null,
                    onClick = { selectedDifficulty = null },
                    label = { Text("All", fontSize = 12.sp) }
                )
                ChallengeDifficulty.values().forEach { diff ->
                    FilterChip(
                        selected = selectedDifficulty == diff,
                        onClick = { selectedDifficulty = diff },
                        label = { Text(diff.displayName, fontSize = 12.sp) }
                    )
                }
            }

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                contentPadding = PaddingValues(bottom = 24.dp)
            ) {
                items(filteredPuzzles) { puzzle ->
                    val isSolved = prefs.isSolvedPuzzle(puzzle.id)
                    Card(
                        shape = RoundedCornerShape(18.dp),
                        colors = CardDefaults.cardColors(containerColor = DarkSurface),
                        modifier = Modifier
                            .fillMaxWidth()
                            .border(1.dp, if (isSolved) ValidGreen.copy(alpha = 0.5f) else DarkSurfaceVariant, RoundedCornerShape(18.dp))
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
                                    .background(if (puzzle.playerRole == PieceType.TIGER) AmberTigerDark else DarkSurfaceVariant),
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
                                        fontSize = 16.sp,
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
                                    color = GoatIvoryDark
                                )

                                Spacer(modifier = Modifier.height(4.dp))

                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Surface(
                                        shape = RoundedCornerShape(6.dp),
                                        color = DarkSurfaceVariant
                                    ) {
                                        Text(
                                            text = puzzle.difficulty.displayName,
                                            fontSize = 10.sp,
                                            color = when (puzzle.difficulty) {
                                                ChallengeDifficulty.EASY -> ValidGreen
                                                ChallengeDifficulty.MEDIUM -> HighlightGold
                                                ChallengeDifficulty.HARD -> AmberTiger
                                                ChallengeDifficulty.EXPERT -> NepalRed
                                            },
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                    Text(
                                        text = "+${puzzle.difficulty.baseReward} Rating",
                                        fontSize = 11.sp,
                                        color = HighlightGold
                                    )
                                }
                            }

                            IconButton(onClick = { onSelectPuzzle(puzzle) }) {
                                Icon(
                                    imageVector = Icons.Default.PlayArrow,
                                    contentDescription = "Play",
                                    tint = AmberTiger
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
