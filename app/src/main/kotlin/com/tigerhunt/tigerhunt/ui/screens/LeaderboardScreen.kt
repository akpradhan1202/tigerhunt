package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.model.LeaderboardFilter
import com.tigerhunt.tigerhunt.model.LeaderboardPlayer
import com.tigerhunt.tigerhunt.model.UserProfile
import com.tigerhunt.tigerhunt.ui.components.PlayerAvatar
import com.tigerhunt.tigerhunt.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LeaderboardScreen(
    players: List<LeaderboardPlayer>,
    userProfile: UserProfile,
    currentFilter: LeaderboardFilter,
    isLoading: Boolean,
    error: String?,
    isScoreSyncing: Boolean,
    syncSuccessMessage: String?,
    searchQuery: String,
    onFilterChanged: (LeaderboardFilter) -> Unit,
    onSearchQueryChanged: (String) -> Unit,
    onRefresh: () -> Unit,
    onSyncScore: () -> Unit,
    onDismissSyncMessage: () -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val filteredPlayers = remember(players, searchQuery) {
        if (searchQuery.isBlank()) {
            players
        } else {
            players.filter {
                it.username.contains(searchQuery, ignoreCase = true) ||
                        it.country.contains(searchQuery, ignoreCase = true) ||
                        it.title.contains(searchQuery, ignoreCase = true)
            }
        }
    }

    val topThree = remember(filteredPlayers, searchQuery) {
        if (searchQuery.isBlank() && filteredPlayers.size >= 3) {
            listOf(filteredPlayers[0], filteredPlayers[1], filteredPlayers[2])
        } else {
            emptyList()
        }
    }

    val restOfPlayers = remember(filteredPlayers, topThree) {
        if (topThree.isNotEmpty()) {
            filteredPlayers.drop(3)
        } else {
            filteredPlayers
        }
    }

    val currentUserEntry = remember(players, userProfile) {
        players.firstOrNull { it.isCurrentUser }
    }

    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(syncSuccessMessage) {
        if (syncSuccessMessage != null) {
            snackbarHostState.showSnackbar(syncSuccessMessage)
            onDismissSyncMessage()
        }
    }

    Scaffold(
        containerColor = DarkBackground,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("🏆", fontSize = 22.sp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Column {
                            Text(
                                text = "Global Leaderboard",
                                fontWeight = FontWeight.Bold,
                                color = HighlightGold,
                                fontSize = 18.sp
                            )
                            Text(
                                text = "Powered by Cloud Firestore",
                                fontSize = 10.sp,
                                color = GoatIvoryDark
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(
                        onClick = onNavigateBack,
                        modifier = Modifier.testTag("leaderboard_back_button")
                    ) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = Color.White
                        )
                    }
                },
                actions = {
                    IconButton(
                        onClick = onRefresh,
                        enabled = !isLoading,
                        modifier = Modifier.testTag("leaderboard_refresh_button")
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                color = HighlightGold,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Icon(
                                Icons.Default.Refresh,
                                contentDescription = "Refresh Leaderboard",
                                tint = HighlightGold
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DarkBackground)
            )
        },
        bottomBar = {
            // Pinned current user position bar
            Surface(
                color = DarkSurface,
                border = BorderStroke(1.dp, BoardWoodLight),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.weight(1f)
                    ) {
                        // User rank pill
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(AmberTigerDark)
                                .border(1.5.dp, HighlightGold, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = currentUserEntry?.let { "#${it.rank}" } ?: "--",
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp,
                                color = HighlightGold
                            )
                        }

                        Spacer(modifier = Modifier.width(10.dp))

                        PlayerAvatar(
                            avatarId = userProfile.avatarId,
                            customAvatarUri = userProfile.customAvatarUri,
                            size = 36.dp,
                            fontSize = 18.sp,
                            borderColor = ValidGreen,
                            borderWidth = 1.dp
                        )

                        Spacer(modifier = Modifier.width(10.dp))

                        Column {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = userProfile.username,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    color = Color.White,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Surface(
                                    shape = RoundedCornerShape(4.dp),
                                    color = ValidGreen.copy(alpha = 0.2f)
                                ) {
                                    Text(
                                        text = "YOU",
                                        color = ValidGreen,
                                        fontSize = 9.sp,
                                        fontWeight = FontWeight.Bold,
                                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                                    )
                                }
                            }
                            Text(
                                text = "${userProfile.totalWins} Wins (${userProfile.winsAsTiger}🐅 / ${userProfile.winsAsGoat}🐐) • ${userProfile.rating} ELO",
                                fontSize = 11.sp,
                                color = GoatIvoryDark
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(8.dp))

                    Button(
                        onClick = onSyncScore,
                        enabled = !isScoreSyncing,
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp),
                        modifier = Modifier.testTag("leaderboard_sync_button")
                    ) {
                        if (isScoreSyncing) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(14.dp),
                                color = Color.Black,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Icon(
                                Icons.Default.CloudUpload,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = Color.Black
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "Sync",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.Black
                            )
                        }
                    }
                }
            }
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            // Live status & info header
            item {
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = ValidGreen.copy(alpha = 0.15f)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(6.dp)
                                    .clip(CircleShape)
                                    .background(ValidGreen)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "FIRESTORE LIVE SYNC",
                                color = ValidGreen,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }

                    Text(
                        text = "${filteredPlayers.size} Hunters Ranked",
                        fontSize = 11.sp,
                        color = GoatIvoryDark,
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            // Filter Tabs
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    LeaderboardFilter.values().forEach { filter ->
                        val isSelected = currentFilter == filter
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (isSelected) AmberTiger else DarkSurface,
                            border = BorderStroke(
                                1.dp,
                                if (isSelected) HighlightGold else DarkSurfaceVariant
                            ),
                            modifier = Modifier
                                .weight(1f)
                                .clickable { onFilterChanged(filter) }
                                .testTag("filter_${filter.name.lowercase()}")
                        ) {
                            Column(
                                modifier = Modifier.padding(vertical = 8.dp, horizontal = 2.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(filter.icon, fontSize = 16.sp)
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = filter.displayName,
                                    fontSize = 10.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) Color.Black else Color.White,
                                    textAlign = TextAlign.Center,
                                    maxLines = 1
                                )
                            }
                        }
                    }
                }
            }

            // Search Bar
            item {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = onSearchQueryChanged,
                    placeholder = { Text("Search hunters by name...", color = GoatIvoryDark, fontSize = 13.sp) },
                    leadingIcon = {
                        Icon(Icons.Default.Search, contentDescription = "Search", tint = HighlightGold)
                    },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { onSearchQueryChanged("") }) {
                                Icon(Icons.Default.Close, contentDescription = "Clear", tint = Color.LightGray)
                            }
                        }
                    },
                    shape = RoundedCornerShape(14.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedContainerColor = DarkSurface,
                        unfocusedContainerColor = DarkSurface,
                        focusedBorderColor = HighlightGold,
                        unfocusedBorderColor = DarkSurfaceVariant,
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    ),
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("leaderboard_search_input")
                )
            }

            // Podium Card for Top 3 (if not searching)
            if (topThree.isNotEmpty()) {
                item {
                    PodiumView(
                        first = topThree[0],
                        second = topThree[1],
                        third = topThree[2],
                        activeFilter = currentFilter
                    )
                }
            }

            // Section Header
            item {
                Text(
                    text = if (topThree.isNotEmpty()) "GLOBAL RANKINGS" else "SEARCH RESULTS",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = HighlightGold,
                    letterSpacing = 1.sp,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }

            // Empty state
            if (filteredPlayers.isEmpty() && !isLoading) {
                item {
                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = DarkSurface),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 20.dp)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text("🔍", fontSize = 36.sp)
                            Spacer(modifier = Modifier.height(10.dp))
                            Text(
                                text = "No Hunters Found",
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                color = Color.White
                            )
                            Text(
                                text = "Try adjusting your search query or refresh live data",
                                fontSize = 12.sp,
                                color = GoatIvoryDark,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }

            // List of Players
            items(restOfPlayers, key = { it.id }) { player ->
                PlayerLeaderboardRow(
                    player = player,
                    activeFilter = currentFilter
                )
            }

            item {
                Spacer(modifier = Modifier.height(16.dp))
            }
        }
    }
}

@Composable
private fun PodiumView(
    first: LeaderboardPlayer,
    second: LeaderboardPlayer,
    third: LeaderboardPlayer,
    activeFilter: LeaderboardFilter
) {
    Card(
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(1.dp, BoardWoodLight),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "👑 TOP CHAMPIONS 👑",
                fontWeight = FontWeight.ExtraBold,
                fontSize = 13.sp,
                color = HighlightGold,
                letterSpacing = 1.sp
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.Bottom
            ) {
                // 2nd Place (Silver)
                PodiumColumn(
                    player = second,
                    rank = 2,
                    pedestalHeight = 85.dp,
                    color = Color(0xFFC0C0C0),
                    medal = "🥈",
                    avatarSize = 52.dp,
                    activeFilter = activeFilter
                )

                // 1st Place (Gold)
                PodiumColumn(
                    player = first,
                    rank = 1,
                    pedestalHeight = 115.dp,
                    color = HighlightGold,
                    medal = "👑",
                    avatarSize = 64.dp,
                    activeFilter = activeFilter
                )

                // 3rd Place (Bronze)
                PodiumColumn(
                    player = third,
                    rank = 3,
                    pedestalHeight = 70.dp,
                    color = Color(0xFFCD7F32),
                    medal = "🥉",
                    avatarSize = 48.dp,
                    activeFilter = activeFilter
                )
            }
        }
    }
}

@Composable
private fun PodiumColumn(
    player: LeaderboardPlayer,
    rank: Int,
    pedestalHeight: androidx.compose.ui.unit.Dp,
    color: Color,
    medal: String,
    avatarSize: androidx.compose.ui.unit.Dp,
    activeFilter: LeaderboardFilter
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(95.dp)
    ) {
        Text(medal, fontSize = if (rank == 1) 22.sp else 18.sp)
        Spacer(modifier = Modifier.height(2.dp))

        // Avatar
        PlayerAvatar(
            avatarId = player.avatar,
            customAvatarUri = player.customAvatarUri,
            size = avatarSize,
            fontSize = (avatarSize.value * 0.45).sp,
            borderColor = color,
            borderWidth = 2.dp
        )

        Spacer(modifier = Modifier.height(6.dp))

        Text(
            text = player.username,
            fontWeight = FontWeight.Bold,
            fontSize = 12.sp,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center
        )

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(player.countryFlag, fontSize = 11.sp)
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = when (activeFilter) {
                    LeaderboardFilter.TOTAL_WINS -> "${player.totalWins} Wins"
                    LeaderboardFilter.TIGER_WINS -> "${player.tigerWins} Wins"
                    LeaderboardFilter.GOAT_WINS -> "${player.goatWins} Wins"
                    LeaderboardFilter.ELO_RATING -> "${player.rating} ELO"
                },
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = color
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Pedestal block
        Surface(
            shape = RoundedCornerShape(topStart = 10.dp, topEnd = 10.dp),
            color = DarkSurfaceVariant,
            border = BorderStroke(1.dp, color.copy(alpha = 0.5f)),
            modifier = Modifier
                .fillMaxWidth()
                .height(pedestalHeight)
        ) {
            Column(
                modifier = Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "#$rank",
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 20.sp,
                    color = color
                )
                Text(
                    text = "${player.rating} ELO",
                    fontSize = 9.sp,
                    color = GoatIvoryDark
                )
            }
        }
    }
}

@Composable
private fun PlayerLeaderboardRow(
    player: LeaderboardPlayer,
    activeFilter: LeaderboardFilter
) {
    val isCurrentUser = player.isCurrentUser
    val rankBadgeColor = when (player.rank) {
        1 -> HighlightGold
        2 -> Color(0xFFC0C0C0)
        3 -> Color(0xFFCD7F32)
        in 4..10 -> AmberTigerLight
        else -> GoatIvoryDark
    }

    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isCurrentUser) DarkSurfaceVariant else DarkSurface
        ),
        border = BorderStroke(
            1.dp,
            if (isCurrentUser) HighlightGold else DarkSurfaceVariant
        ),
        modifier = Modifier
            .fillMaxWidth()
            .testTag("leaderboard_player_row_${player.rank}")
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Rank number badge
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(rankBadgeColor.copy(alpha = 0.18f))
                    .border(1.dp, rankBadgeColor.copy(alpha = 0.4f), RoundedCornerShape(8.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "#${player.rank}",
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp,
                    color = rankBadgeColor
                )
            }

            Spacer(modifier = Modifier.width(10.dp))

            // Avatar
            PlayerAvatar(
                avatarId = player.avatar,
                customAvatarUri = player.customAvatarUri,
                size = 38.dp,
                fontSize = 20.sp,
                borderColor = if (isCurrentUser) HighlightGold else DarkSurfaceVariant,
                borderWidth = 1.dp
            )

            Spacer(modifier = Modifier.width(10.dp))

            // Name + Country + Title
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = player.username,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(player.countryFlag, fontSize = 12.sp)
                    if (isCurrentUser) {
                        Spacer(modifier = Modifier.width(4.dp))
                        Surface(
                            shape = RoundedCornerShape(4.dp),
                            color = ValidGreen.copy(alpha = 0.2f)
                        ) {
                            Text(
                                text = "YOU",
                                color = ValidGreen,
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                            )
                        }
                    }
                }
                Text(
                    text = "${player.title} • ${player.rating} ELO",
                    fontSize = 11.sp,
                    color = GoatIvoryDark
                )
            }

            // Stats metric badge
            Column(
                horizontalAlignment = Alignment.End
            ) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = AmberTiger.copy(alpha = 0.15f),
                    border = BorderStroke(1.dp, AmberTiger.copy(alpha = 0.3f))
                ) {
                    Text(
                        text = when (activeFilter) {
                            LeaderboardFilter.TOTAL_WINS -> "${player.totalWins} Wins"
                            LeaderboardFilter.TIGER_WINS -> "${player.tigerWins} 🐅 Wins"
                            LeaderboardFilter.GOAT_WINS -> "${player.goatWins} 🐐 Wins"
                            LeaderboardFilter.ELO_RATING -> "${player.rating} ELO"
                        },
                        fontWeight = FontWeight.Bold,
                        fontSize = 12.sp,
                        color = HighlightGold,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                    )
                }

                Spacer(modifier = Modifier.height(2.dp))

                Text(
                    text = "${"%.0f".format(player.winRate)}% Win Rate",
                    fontSize = 10.sp,
                    color = GoatIvoryDark
                )
            }
        }
    }
}
