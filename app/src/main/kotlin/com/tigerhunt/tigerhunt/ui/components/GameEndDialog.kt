package com.tigerhunt.tigerhunt.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Home
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.model.DrawReason
import com.tigerhunt.tigerhunt.model.GameWinner
import com.tigerhunt.tigerhunt.ui.theme.*

@Composable
fun GameEndDialog(
    winner: GameWinner,
    drawReason: DrawReason,
    onRematchClick: () -> Unit,
    onHomeClick: () -> Unit,
    onDismiss: () -> Unit,
    isPuzzle: Boolean = false,
    puzzleTitle: String? = null,
    isDaily: Boolean = false,
    coinsEarned: Int? = null,
    dailyStreak: Int? = null
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            Button(
                onClick = onRematchClick,
                colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.testTag("rematch_dialog_button")
            ) {
                Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text(if (isPuzzle) "Play Again" else "Play Rematch", color = Color.Black, fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            OutlinedButton(
                onClick = onHomeClick,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.testTag("home_dialog_button")
            ) {
                Icon(Icons.Default.Home, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text("Home Menu")
            }
        },
        containerColor = DarkSurface,
        shape = RoundedCornerShape(24.dp),
        title = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(CircleShape)
                        .background(
                            if (isPuzzle) ValidGreen.copy(alpha = 0.25f)
                            else if (winner == GameWinner.TIGERS) AmberTigerDark
                            else if (winner == GameWinner.GOATS) ValidGreen
                            else DarkSurfaceVariant
                        )
                        .border(
                            2.dp,
                            if (isPuzzle) ValidGreen else HighlightGold,
                            CircleShape
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = if (isPuzzle) (if (isDaily) "🔥" else "🧩")
                        else if (winner == GameWinner.TIGERS) "🐅"
                        else if (winner == GameWinner.GOATS) "🐐"
                        else "🤝",
                        fontSize = 32.sp
                    )
                }
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = when {
                        isDaily -> "Daily Challenge Complete!"
                        isPuzzle -> "Puzzle Solved!"
                        winner == GameWinner.TIGERS -> "Tigers Victorious!"
                        winner == GameWinner.GOATS -> "Goats Trapped the Tigers!"
                        winner == GameWinner.DRAW -> "Match Drawn!"
                        else -> "Game Over"
                    },
                    fontWeight = FontWeight.Bold,
                    fontSize = 22.sp,
                    color = Color.White,
                    textAlign = TextAlign.Center
                )
            }
        },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                val description = when {
                    isPuzzle -> "Fantastic! You found the winning tactical sequence for $puzzleTitle!"
                    winner == GameWinner.TIGERS -> "The fierce tigers captured 5 goats and conquered the board."
                    winner == GameWinner.GOATS -> "The goats formed an impenetrable encirclement and immobilized all tigers!"
                    drawReason == DrawReason.THREEFOLD_REPETITION -> "The exact same board position was reached 3 times."
                    drawReason == DrawReason.STAGNATION -> "40 consecutive moves occurred without a capture."
                    drawReason == DrawReason.TIMEOUT -> "One of the hunters ran out of clock time."
                    else -> "A thrilling clash in the high Himalayas!"
                }

                Text(
                    text = description,
                    color = GoatIvoryDark,
                    fontSize = 14.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )

                if (isPuzzle) {
                    Surface(
                        shape = RoundedCornerShape(16.dp),
                        color = DarkSurfaceVariant,
                        border = androidx.compose.foundation.BorderStroke(1.dp, HighlightGold.copy(alpha = 0.4f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.SpaceEvenly,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text("🪙", fontSize = 16.sp)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = "+${coinsEarned ?: 150}",
                                        fontSize = 16.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = HighlightGold
                                    )
                                }
                                Text("Bagh Coins", fontSize = 11.sp, color = GoatIvoryDark)
                            }

                            if (isDaily && dailyStreak != null) {
                                Divider(
                                    modifier = Modifier
                                        .height(28.dp)
                                        .width(1.dp),
                                    color = DarkBackground
                                )

                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text("🔥", fontSize = 16.sp)
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text(
                                            text = "$dailyStreak Days",
                                            fontSize = 16.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = AmberTigerLight
                                        )
                                    }
                                    Text("Daily Streak", fontSize = 11.sp, color = GoatIvoryDark)
                                }
                            }
                        }
                    }
                }
            }
        }
    )
}
