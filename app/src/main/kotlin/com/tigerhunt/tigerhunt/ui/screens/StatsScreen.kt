package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.material.icons.filled.EmojiEvents
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
import com.tigerhunt.tigerhunt.model.AuthMethod
import com.tigerhunt.tigerhunt.model.UserProfile
import com.tigerhunt.tigerhunt.ui.components.PlayerAvatar
import com.tigerhunt.tigerhunt.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatsScreen(
    userProfile: UserProfile,
    onNavigateBack: () -> Unit,
    onNavigateToAuth: () -> Unit = {},
    onNavigateToLeaderboard: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Hunter Profile & Stats",
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("stats_back_button")) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToLeaderboard, modifier = Modifier.testTag("stats_leaderboard_button")) {
                        Icon(Icons.Default.EmojiEvents, contentDescription = "Global Leaderboard", tint = HighlightGold)
                    }
                    TextButton(onClick = onNavigateToAuth, modifier = Modifier.testTag("stats_edit_profile_button")) {
                        Text("Account", color = HighlightGold, fontWeight = FontWeight.Bold)
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
            // GLOBAL LEADERBOARD BANNER
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurfaceVariant),
                border = BorderStroke(1.dp, HighlightGold),
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onNavigateToLeaderboard() }
                    .testTag("stats_view_leaderboard_banner")
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("🏆", fontSize = 28.sp)
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text(
                                text = "Global Leaderboard",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = HighlightGold
                            )
                            Text(
                                text = "See where you rank against top hunters",
                                fontSize = 11.sp,
                                color = GoatIvoryDark
                            )
                        }
                    }
                    Button(
                        onClick = onNavigateToLeaderboard,
                        colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text("View", fontSize = 12.sp, color = Color.Black, fontWeight = FontWeight.Bold)
                    }
                }
            }
            // RATING HEADER CARD
            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BoardWoodLight, RoundedCornerShape(20.dp))
                    .clickable { onNavigateToAuth() }
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    PlayerAvatar(
                        avatarId = userProfile.avatarId,
                        customAvatarUri = userProfile.customAvatarUri,
                        size = 64.dp,
                        fontSize = 32.sp,
                        borderColor = HighlightGold,
                        borderWidth = 2.dp
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = userProfile.username,
                            fontWeight = FontWeight.Bold,
                            fontSize = 20.sp,
                            color = Color.White
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = if (userProfile.isLoggedIn) ValidGreen.copy(alpha = 0.2f) else DarkSurfaceVariant
                        ) {
                            Text(
                                text = when (userProfile.authMethod) {
                                    AuthMethod.GMAIL -> "🇬 GMAIL"
                                    AuthMethod.PHONE -> "📱 PHONE"
                                    AuthMethod.GUEST -> "👤 GUEST"
                                },
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (userProfile.isLoggedIn) ValidGreen else GoatIvoryDark,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }

                    Text(
                        text = userProfile.currentRank,
                        fontSize = 13.sp,
                        color = HighlightGold
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        StatPill("Rating", "${userProfile.rating}")
                        StatPill("Win Rate", "${"%.1f".format(userProfile.winRate)}%")
                        StatPill("Total Matches", "${userProfile.totalGames}")
                    }
                }
            }

            // DETAILED BREAKDOWN
            Text(
                text = "PERFORMANCE BREAKDOWN",
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                color = HighlightGold,
                letterSpacing = 1.sp
            )

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatCard(
                    title = "As Tigers 🐅",
                    wins = userProfile.winsAsTiger,
                    losses = userProfile.lossesAsTiger,
                    modifier = Modifier.weight(1f)
                )

                StatCard(
                    title = "As Goats 🐐",
                    wins = userProfile.winsAsGoat,
                    losses = userProfile.lossesAsGoat,
                    modifier = Modifier.weight(1f)
                )
            }

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    modifier = Modifier.weight(1f)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("🧩 Puzzles Solved", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color.White)
                        Spacer(modifier = Modifier.height(6.dp))
                        Text("${userProfile.puzzlesSolved}", fontWeight = FontWeight.Bold, fontSize = 24.sp, color = HighlightGold)
                    }
                }

                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    modifier = Modifier.weight(1f)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("🏆 Tournaments", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color.White)
                        Spacer(modifier = Modifier.height(6.dp))
                        Text("${userProfile.tournamentsWon} Trophies", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = AmberTiger)
                    }
                }
            }
        }
    }
}

@Composable
private fun StatPill(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, fontWeight = FontWeight.Bold, fontSize = 20.sp, color = Color.White)
        Text(label, fontSize = 11.sp, color = GoatIvoryDark)
    }
}

@Composable
private fun StatCard(title: String, wins: Int, losses: Int, modifier: Modifier = Modifier) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        modifier = modifier
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, fontWeight = FontWeight.Bold, fontSize = 15.sp, color = Color.White)
            Spacer(modifier = Modifier.height(10.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Wins:", fontSize = 13.sp, color = ValidGreen)
                Text("$wins", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = Color.White)
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Losses:", fontSize = 13.sp, color = NepalRed)
                Text("$losses", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = Color.White)
            }
        }
    }
}
