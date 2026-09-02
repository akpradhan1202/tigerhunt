package com.tigerhunt.tigerhunt.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.model.GameState
import com.tigerhunt.tigerhunt.model.PieceType
import com.tigerhunt.tigerhunt.model.PlayerTurn
import com.tigerhunt.tigerhunt.ui.theme.*

@Composable
fun PlayerInfoBar(
    gameState: GameState,
    isTigerPlayer: Boolean,
    isAiThinking: Boolean,
    modifier: Modifier = Modifier
) {
    val isGoatActive = gameState.currentTurn == PlayerTurn.GOAT
    val isTigerActive = gameState.currentTurn == PlayerTurn.TIGER

    val goatBg by animateColorAsState(
        if (isGoatActive) DarkSurfaceVariant else DarkSurface,
        label = "goat_bg"
    )
    val tigerBg by animateColorAsState(
        if (isTigerActive) DarkSurfaceVariant else DarkSurface,
        label = "tiger_bg"
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // GOAT CARD
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = goatBg),
            modifier = Modifier
                .weight(1f)
                .border(
                    width = if (isGoatActive) 2.dp else 1.dp,
                    color = if (isGoatActive) HighlightGold else Color.Transparent,
                    shape = RoundedCornerShape(16.dp)
                )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(38.dp)
                        .clip(CircleShape)
                        .background(Color(0xFFE0E0E0)),
                    contentAlignment = Alignment.Center
                ) {
                    Text("🐐", fontSize = 20.sp)
                }

                Spacer(modifier = Modifier.width(8.dp))

                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "Goats",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = Color.White
                        )
                        if (isGoatActive) {
                            Spacer(modifier = Modifier.width(4.dp))
                            Box(
                                modifier = Modifier
                                    .size(6.dp)
                                    .clip(CircleShape)
                                    .background(ValidGreen)
                            )
                        }
                    }

                    Text(
                        text = "Placed: ${gameState.goatsPlaced}/${gameState.level.goatCount}",
                        fontSize = 11.sp,
                        color = GoatIvoryDark
                    )

                    gameState.goatTimeRemainingMillis?.let { millis ->
                        val seconds = (millis / 1000) % 60
                        val minutes = (millis / 1000) / 60
                        Text(
                            text = String.format("%02d:%02d", minutes, seconds),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (millis < 15000) NepalRed else HighlightGold
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.width(12.dp))

        // CENTER CAPTURED RACK
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 4.dp)
        ) {
            Text(
                text = "Captured",
                fontSize = 10.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.Gray
            )
            Row(
                horizontalArrangement = Arrangement.spacedBy(3.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                for (i in 0 until gameState.level.goatsToWin) {
                    val isCaptured = i < gameState.goatsCaptured
                    Box(
                        modifier = Modifier
                            .size(10.dp)
                            .clip(CircleShape)
                            .background(if (isCaptured) NepalRed else Color.DarkGray)
                            .border(
                                1.dp,
                                if (isCaptured) NepalRedDark else Color.Gray,
                                CircleShape
                            )
                    )
                }
            }
            Text(
                text = "${gameState.goatsCaptured}/${gameState.level.goatsToWin}",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = if (gameState.goatsCaptured >= 4) NepalRed else Color.White
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        // TIGER CARD
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = tigerBg),
            modifier = Modifier
                .weight(1f)
                .border(
                    width = if (isTigerActive) 2.dp else 1.dp,
                    color = if (isTigerActive) AmberTiger else Color.Transparent,
                    shape = RoundedCornerShape(16.dp)
                )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.End
            ) {
                Column(horizontalAlignment = Alignment.End) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (isTigerActive) {
                            Box(
                                modifier = Modifier
                                    .size(6.dp)
                                    .clip(CircleShape)
                                    .background(AmberTiger)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                        }
                        Text(
                            text = "Tigers",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = AmberTiger
                        )
                    }

                    Text(
                        text = if (isAiThinking && isTigerActive) "Thinking..." else "Count: ${gameState.tigers.size}",
                        fontSize = 11.sp,
                        color = if (isAiThinking && isTigerActive) HighlightGold else AmberTigerLight
                    )

                    gameState.tigerTimeRemainingMillis?.let { millis ->
                        val seconds = (millis / 1000) % 60
                        val minutes = (millis / 1000) / 60
                        Text(
                            text = String.format("%02d:%02d", minutes, seconds),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (millis < 15000) NepalRed else HighlightGold
                        )
                    }
                }

                Spacer(modifier = Modifier.width(8.dp))

                Box(
                    modifier = Modifier
                        .size(38.dp)
                        .clip(CircleShape)
                        .background(AmberTigerDark),
                    contentAlignment = Alignment.Center
                ) {
                    Text("🐅", fontSize = 20.sp)
                }
            }
        }
    }
}
