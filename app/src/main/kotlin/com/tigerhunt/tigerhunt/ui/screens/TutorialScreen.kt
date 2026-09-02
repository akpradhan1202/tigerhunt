package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
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
import com.tigerhunt.tigerhunt.ui.theme.*

data class TutorialStep(
    val title: String,
    val icon: String,
    val headline: String,
    val explanation: String,
    val keyTakeaway: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TutorialScreen(
    onNavigateBack: () -> Unit,
    onStartPracticeGame: () -> Unit,
    modifier: Modifier = Modifier
) {
    val steps = remember {
        listOf(
            TutorialStep(
                title = "1. Introduction to Bagh-Chal",
                icon = "🏔️",
                headline = "The Himalayan Royal Game",
                explanation = "Bagh-Chal ('Moving Tigers') is an asymmetric strategic two-player board game originating in Nepal. One player commands 4 or 5 hungry Tigers, while the other commands a herd of 20 clever Goats.",
                keyTakeaway = "Tigers aim to capture 5 Goats. Goats aim to trap all Tigers so they have no legal moves."
            ),
            TutorialStep(
                title = "2. Goat Placement Phase",
                icon = "🐐",
                headline = "Drop Goats One by One",
                explanation = "The game starts with all Tigers stationed at the board corners (and center). The Goats go first! In the initial phase, Goats are placed one at a time on any empty intersection of the board.",
                keyTakeaway = "Goats cannot move across lines until all 20 goats have been deployed onto the board."
            ),
            TutorialStep(
                title = "3. Tiger Movement & Leaps",
                icon = "🐅",
                headline = "Pounce Over Goats",
                explanation = "Tigers can move one step along any connected line to an adjacent empty node. If an adjacent node holds a Goat and the node directly beyond it along the same line is empty, the Tiger leaps over and captures it!",
                keyTakeaway = "Tigers cannot jump over other tigers or empty spaces. Captures remove goats permanently."
            ),
            TutorialStep(
                title = "4. Goat Movement Phase",
                icon = "🛡️",
                headline = "Coordinate the Herd",
                explanation = "Once all 20 goats are placed, surviving goats can step one position along connected lines to adjacent empty nodes. Goats cannot capture or jump.",
                keyTakeaway = "Goats win by building tight clusters that box in every tiger with zero escape moves."
            ),
            TutorialStep(
                title = "5. Winning & Draw Rules",
                icon = "👑",
                headline = "Mastering Victory",
                explanation = "Tigers win when they capture 5 goats. Goats win when all tigers are trapped. If the same position repeats 3 times or 40 moves pass without capture, a draw is declared.",
                keyTakeaway = "Keep goats protected in pairs so tigers cannot jump without landing on occupied spots!"
            )
        )
    }

    var currentStep by remember { mutableStateOf(0) }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Interactive Tutorial",
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("tutorial_back_button")) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DarkBackground)
            )
        }
    ) { innerPadding ->
        val step = steps[currentStep]

        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                // Progress Indicator
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    steps.indices.forEach { index ->
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(4.dp)
                                .clip(RoundedCornerShape(2.dp))
                                .background(if (index <= currentStep) HighlightGold else DarkSurfaceVariant)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(DarkSurfaceVariant)
                        .border(2.dp, HighlightGold, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(step.icon, fontSize = 40.sp)
                }

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = step.title,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = AmberTiger
                )

                Text(
                    text = step.headline,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )

                Spacer(modifier = Modifier.height(16.dp))

                Card(
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(20.dp)) {
                        Text(
                            text = step.explanation,
                            fontSize = 15.sp,
                            color = GoatIvory,
                            lineHeight = 22.sp
                        )

                        Spacer(modifier = Modifier.height(14.dp))

                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = DarkSurfaceVariant,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("💡", fontSize = 18.sp)
                                Spacer(modifier = Modifier.width(10.dp))
                                Text(
                                    text = step.keyTakeaway,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = HighlightGold
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // BOTTOM NAVIGATION
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (currentStep > 0) {
                    OutlinedButton(
                        onClick = { currentStep-- },
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("Previous")
                    }
                } else {
                    Spacer(modifier = Modifier.width(1.dp))
                }

                if (currentStep < steps.size - 1) {
                    Button(
                        onClick = { currentStep++ },
                        colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.testTag("tutorial_next_button")
                    ) {
                        Text("Next Lesson", color = Color.Black, fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.width(6.dp))
                        Icon(Icons.Default.ArrowForward, contentDescription = null, tint = Color.Black)
                    }
                } else {
                    Button(
                        onClick = onStartPracticeGame,
                        colors = ButtonDefaults.buttonColors(containerColor = ValidGreen),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.testTag("tutorial_play_button")
                    ) {
                        Text("Play Practice Game", color = Color.Black, fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.width(6.dp))
                        Icon(Icons.Default.Check, contentDescription = null, tint = Color.Black)
                    }
                }
            }
        }
    }
}
