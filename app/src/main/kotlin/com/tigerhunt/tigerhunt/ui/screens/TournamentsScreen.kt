package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.model.TournamentMatch
import com.tigerhunt.tigerhunt.model.TournamentStage
import com.tigerhunt.tigerhunt.model.TournamentState
import com.tigerhunt.tigerhunt.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TournamentsScreen(
    tournamentState: TournamentState?,
    onStartTournament: () -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Himalayan Championship",
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("tournament_back_button")) {
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
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // CHAMPIONSHIP TROPHY CARD
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
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(AmberTigerDark),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("🏆", fontSize = 28.sp)
                    }

                    Spacer(modifier = Modifier.width(14.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Kathmandu Cup Bracket",
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = Color.White
                        )
                        Text(
                            text = "8 Master Hunters • Single Elimination",
                            fontSize = 12.sp,
                            color = GoatIvoryDark
                        )
                    }

                    Button(
                        onClick = onStartTournament,
                        colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.testTag("start_tournament_button")
                    ) {
                        Text("Enter", color = Color.Black, fontWeight = FontWeight.Bold)
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "BRACKET CONTENDERS",
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                color = HighlightGold,
                letterSpacing = 1.sp,
                modifier = Modifier.align(Alignment.Start)
            )

            Spacer(modifier = Modifier.height(10.dp))

            val state = tournamentState ?: TournamentState.createDefault()
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(state.matches) { match ->
                    MatchCard(match = match)
                }
            }
        }
    }
}

@Composable
private fun MatchCard(match: TournamentMatch) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurfaceVariant),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = match.stage.displayName,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = HighlightGold
            )
            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(match.player1.avatar, fontSize = 20.sp)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = match.player1.name,
                        fontWeight = if (match.player1.isUser) FontWeight.Bold else FontWeight.Normal,
                        color = if (match.player1.isUser) AmberTiger else Color.White,
                        fontSize = 14.sp
                    )
                }
                Text("${match.player1.rating} ELO", fontSize = 11.sp, color = GoatIvoryDark)
            }

            Divider(color = DarkSurface, modifier = Modifier.padding(vertical = 6.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(match.player2.avatar, fontSize = 20.sp)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = match.player2.name,
                        fontWeight = if (match.player2.isUser) FontWeight.Bold else FontWeight.Normal,
                        color = if (match.player2.isUser) AmberTiger else Color.White,
                        fontSize = 14.sp
                    )
                }
                Text("${match.player2.rating} ELO", fontSize = 11.sp, color = GoatIvoryDark)
            }
        }
    }
}
