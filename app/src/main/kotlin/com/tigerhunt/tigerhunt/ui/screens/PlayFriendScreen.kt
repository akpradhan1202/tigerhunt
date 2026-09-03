package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.model.*
import com.tigerhunt.tigerhunt.ui.components.PlayerAvatar
import com.tigerhunt.tigerhunt.ui.theme.*
import kotlin.random.Random

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlayFriendScreen(
    userProfile: UserProfile,
    friends: List<Friend>,
    onAddFriend: (String) -> Boolean,
    onRemoveFriend: (String) -> Unit,
    onToggleFavoriteFriend: (String) -> Unit,
    onStartFriendGame: (mode: GameMode, level: BoardLevel, timer: GameTimer, playerSide: PieceType, friendName: String, roomCode: String?) -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedMainTab by remember { mutableStateOf(0) } // 0: Friends List, 1: Online Room, 2: Pass & Play
    val clipboardManager = LocalClipboardManager.current

    // Dialog state for challenging a friend
    var friendToChallenge by remember { mutableStateOf<Friend?>(null) }
    var challengeLevel by remember { mutableStateOf(BoardLevel.SQUARE) }
    var challengeTimer by remember { mutableStateOf(GameTimer.CLASSIC) }
    var challengeSide by remember { mutableStateOf(PieceType.GOAT) }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("👥", fontSize = 22.sp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Play with Friends",
                            fontWeight = FontWeight.Bold,
                            color = HighlightGold
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("play_friend_back_button")) {
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
                .padding(horizontal = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // MAIN 3 TABS
            TabRow(
                selectedTabIndex = selectedMainTab,
                containerColor = DarkSurface,
                contentColor = HighlightGold,
                modifier = Modifier
                    .clip(RoundedCornerShape(14.dp))
                    .border(1.dp, DarkSurfaceVariant, RoundedCornerShape(14.dp))
            ) {
                Tab(
                    selected = selectedMainTab == 0,
                    onClick = { selectedMainTab = 0 },
                    text = {
                        Text("👥 Friends (${friends.size})", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                    },
                    modifier = Modifier.testTag("tab_friends_list")
                )
                Tab(
                    selected = selectedMainTab == 1,
                    onClick = { selectedMainTab = 1 },
                    text = {
                        Text("🌐 Room Code", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                    },
                    modifier = Modifier.testTag("tab_online_room")
                )
                Tab(
                    selected = selectedMainTab == 2,
                    onClick = { selectedMainTab = 2 },
                    text = {
                        Text("📱 Pass & Play", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                    },
                    modifier = Modifier.testTag("tab_pass_play")
                )
            }

            Spacer(modifier = Modifier.height(14.dp))

            when (selectedMainTab) {
                0 -> FriendsTabContent(
                    userProfile = userProfile,
                    friends = friends,
                    onAddFriend = onAddFriend,
                    onRemoveFriend = onRemoveFriend,
                    onToggleFavoriteFriend = onToggleFavoriteFriend,
                    onChallengeFriend = { friend ->
                        friendToChallenge = friend
                    }
                )
                1 -> OnlineRoomTabContent(
                    userProfile = userProfile,
                    onStartGame = { level, timer, side, friendName, roomCode ->
                        onStartFriendGame(GameMode.PLAY_FRIEND, level, timer, side, friendName, roomCode)
                    }
                )
                2 -> PassAndPlayTabContent(
                    userProfile = userProfile,
                    onStartPassAndPlay = { level, p1Name, p2Name ->
                        onStartFriendGame(GameMode.PASS_AND_PLAY, level, GameTimer.CLASSIC, PieceType.GOAT, p2Name, null)
                    }
                )
            }
        }
    }

    // CHALLENGE FRIEND MODAL DIALOG
    friendToChallenge?.let { friend ->
        AlertDialog(
            onDismissRequest = { friendToChallenge = null },
            containerColor = DarkSurface,
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    PlayerAvatar(
                        avatarId = friend.avatar,
                        size = 32.dp,
                        fontSize = 18.sp,
                        borderColor = HighlightGold,
                        borderWidth = 1.dp
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text("Challenge ${friend.name}", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 16.sp)
                        Text("${friend.countryFlag} ${friend.rating} ELO • ${friend.rank}", fontSize = 12.sp, color = HighlightGold)
                    }
                }
            },
            text = {
                Column {
                    Text("BOARD LEVEL", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = HighlightGold, letterSpacing = 1.sp)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        BoardLevel.values().forEach { level ->
                            val isSelected = challengeLevel == level
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isSelected) AmberTiger else DarkSurfaceVariant,
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable { challengeLevel = level }
                            ) {
                                Text(
                                    text = level.displayName,
                                    fontSize = 10.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) Color.Black else Color.White,
                                    textAlign = TextAlign.Center,
                                    modifier = Modifier.padding(vertical = 6.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Text("MATCH CLOCK", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = HighlightGold, letterSpacing = 1.sp)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        listOf(GameTimer.RAPID to "5m", GameTimer.CLASSIC to "10m", GameTimer.STANDARD to "30m", GameTimer.LONG_MATCH to "1h", GameTimer.UNLIMITED to "∞").forEach { (timer, label) ->
                            val isSelected = challengeTimer == timer
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isSelected) AmberTiger else DarkSurfaceVariant,
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable { challengeTimer = timer }
                            ) {
                                Text(
                                    text = label,
                                    fontSize = 11.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) Color.Black else Color.White,
                                    textAlign = TextAlign.Center,
                                    modifier = Modifier.padding(vertical = 6.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Text("YOUR PIECE", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = HighlightGold, letterSpacing = 1.sp)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        listOf(PieceType.GOAT to "🐐 Goats", PieceType.TIGER to "🐅 Tigers").forEach { (side, label) ->
                            val isSelected = challengeSide == side
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isSelected) AmberTiger else DarkSurfaceVariant,
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable { challengeSide = side }
                            ) {
                                Text(
                                    text = label,
                                    fontSize = 11.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) Color.Black else Color.White,
                                    textAlign = TextAlign.Center,
                                    modifier = Modifier.padding(vertical = 8.dp)
                                )
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val challenged = friendToChallenge!!
                        friendToChallenge = null
                        onStartFriendGame(
                            GameMode.PLAY_FRIEND,
                            challengeLevel,
                            challengeTimer,
                            challengeSide,
                            challenged.name,
                            challenged.friendCode
                        )
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AmberTiger)
                ) {
                    Text("⚔️ Send Challenge & Play", color = Color.Black, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { friendToChallenge = null }) {
                    Text("Cancel", color = GoatIvoryDark)
                }
            }
        )
    }
}

@Composable
private fun FriendsTabContent(
    userProfile: UserProfile,
    friends: List<Friend>,
    onAddFriend: (String) -> Boolean,
    onRemoveFriend: (String) -> Unit,
    onToggleFavoriteFriend: (String) -> Unit,
    onChallengeFriend: (Friend) -> Unit
) {
    var friendInput by remember { mutableStateOf("") }
    var addFriendMessage by remember { mutableStateOf<String?>(null) }
    var addFriendSuccess by remember { mutableStateOf(false) }
    var selectedFilter by remember { mutableStateOf(0) } // 0: All, 1: Online, 2: Favorites
    val clipboardManager = LocalClipboardManager.current
    var copiedMyCode by remember { mutableStateOf(false) }

    val suggestedRivals = listOf(
        "Rohan KC" to "🇳🇵",
        "Maya Gurung" to "🇳🇵",
        "Ankit Verma" to "🇮🇳",
        "Sonam Dorji" to "🇧🇹"
    )

    val filteredFriends = when (selectedFilter) {
        1 -> friends.filter { it.status == FriendStatus.ONLINE }
        2 -> friends.filter { it.isFavorite }
        else -> friends
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // MY FRIEND CODE BANNER
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BoardWoodLight, RoundedCornerShape(16.dp))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        PlayerAvatar(
                            avatarId = userProfile.avatarId,
                            customAvatarUri = userProfile.customAvatarUri,
                            size = 40.dp,
                            fontSize = 20.sp,
                            borderColor = HighlightGold,
                            borderWidth = 1.dp
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text("MY FRIEND CODE", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = HighlightGold, letterSpacing = 1.sp)
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = userProfile.friendCode,
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = Color.White
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "(${userProfile.username})",
                                    fontSize = 12.sp,
                                    color = GoatIvoryDark
                                )
                            }
                        }
                    }

                    Button(
                        onClick = {
                            clipboardManager.setText(AnnotatedString(userProfile.friendCode))
                            copiedMyCode = true
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = if (copiedMyCode) ValidGreen else DarkSurfaceVariant),
                        shape = RoundedCornerShape(10.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                        Icon(
                            imageVector = if (copiedMyCode) Icons.Default.Check else Icons.Default.ContentCopy,
                            contentDescription = null,
                            tint = if (copiedMyCode) Color.Black else HighlightGold,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = if (copiedMyCode) "Copied!" else "Copy",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (copiedMyCode) Color.Black else Color.White
                        )
                    }
                }
            }
        }

        // ADD FRIEND SECTION
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BoardWoodLight, RoundedCornerShape(16.dp))
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.PersonAdd, contentDescription = null, tint = AmberTiger, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Add New Friend", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 14.sp)
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = friendInput,
                            onValueChange = {
                                friendInput = it
                                addFriendMessage = null
                            },
                            label = { Text("Friend Code (BH-XXXX) or Name") },
                            singleLine = true,
                            shape = RoundedCornerShape(10.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = HighlightGold,
                                unfocusedBorderColor = DarkSurfaceVariant,
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White
                            ),
                            modifier = Modifier
                                .weight(1f)
                                .testTag("add_friend_input")
                        )

                        Spacer(modifier = Modifier.width(8.dp))

                        Button(
                            onClick = {
                                if (friendInput.isNotBlank()) {
                                    val success = onAddFriend(friendInput)
                                    addFriendSuccess = success
                                    if (success) {
                                        addFriendMessage = "Added ${friendInput.trim()} to friends list!"
                                        friendInput = ""
                                    } else {
                                        addFriendMessage = "Friend is already in your list or invalid code."
                                    }
                                }
                            },
                            enabled = friendInput.trim().length >= 2,
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                            contentPadding = PaddingValues(horizontal = 14.dp, vertical = 14.dp),
                            modifier = Modifier.testTag("add_friend_button")
                        ) {
                            Text("Add", color = Color.Black, fontWeight = FontWeight.Bold)
                        }
                    }

                    addFriendMessage?.let { msg ->
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = msg,
                            color = if (addFriendSuccess) ValidGreen else Color(0xFFFF8A80),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Suggested Rivals quick chips
                    Text("Suggested Himalayan Rivals:", fontSize = 11.sp, color = GoatIvoryDark)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        suggestedRivals.forEach { (name, flag) ->
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = DarkSurfaceVariant,
                                modifier = Modifier
                                    .clickable {
                                        val ok = onAddFriend(name)
                                        addFriendSuccess = ok
                                        addFriendMessage = if (ok) "Added $name!" else "$name is already your friend."
                                    }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("+ $flag $name", fontSize = 11.sp, color = HighlightGold)
                                }
                            }
                        }
                    }
                }
            }
        }

        // FILTER TABS (ALL / ONLINE / FAVORITES)
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf(
                    "All (${friends.size})",
                    "🟢 Online (${friends.count { it.status == FriendStatus.ONLINE }})",
                    "⭐ Favorites (${friends.count { it.isFavorite }})"
                ).forEachIndexed { index, label ->
                    val isSelected = selectedFilter == index
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = if (isSelected) AmberTiger else DarkSurface,
                        border = androidx.compose.foundation.BorderStroke(1.dp, if (isSelected) AmberTiger else DarkSurfaceVariant),
                        modifier = Modifier
                            .weight(1f)
                            .clickable { selectedFilter = index }
                    ) {
                        Text(
                            text = label,
                            fontSize = 11.sp,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                            color = if (isSelected) Color.Black else Color.White,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(vertical = 8.dp, horizontal = 4.dp)
                        )
                    }
                }
            }
        }

        // EMPTY STATE
        if (filteredFriends.isEmpty()) {
            item {
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = DarkSurface,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(28.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("🏔️", fontSize = 36.sp)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("No friends found", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 14.sp)
                        Text(
                            text = "Add friends using their Friend Code or add from suggested rivals above.",
                            fontSize = 12.sp,
                            color = GoatIvoryDark,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }

        // FRIENDS LIST ITEMS
        items(filteredFriends, key = { it.id }) { friend ->
            FriendListItemCard(
                friend = friend,
                onChallenge = { onChallengeFriend(friend) },
                onToggleFavorite = { onToggleFavoriteFriend(friend.id) },
                onRemove = { onRemoveFriend(friend.id) }
            )
        }

        item {
            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
private fun FriendListItemCard(
    friend: Friend,
    onChallenge: () -> Unit,
    onToggleFavorite: () -> Unit,
    onRemove: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, if (friend.isFavorite) HighlightGold.copy(alpha = 0.6f) else BoardWoodLight, RoundedCornerShape(16.dp))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // AVATAR WITH ONLINE STATUS BADGE
            Box(contentAlignment = Alignment.BottomEnd) {
                PlayerAvatar(
                    avatarId = friend.avatar,
                    size = 48.dp,
                    fontSize = 24.sp,
                    borderColor = HighlightGold,
                    borderWidth = 1.5.dp
                )

                // Online indicator dot
                Box(
                    modifier = Modifier
                        .size(14.dp)
                        .clip(CircleShape)
                        .background(Color(friend.status.colorHex))
                        .border(2.dp, DarkSurface, CircleShape)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // INFO
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = friend.name,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(friend.countryFlag, fontSize = 14.sp)
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "${friend.rating} ELO",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = HighlightGold
                    )
                    Text(" • ", fontSize = 11.sp, color = GoatIvoryDark)
                    Text(
                        text = friend.friendCode,
                        fontSize = 11.sp,
                        color = GoatIvoryDark
                    )
                }

                Text(
                    text = when (friend.status) {
                        FriendStatus.ONLINE -> "🟢 Online Now"
                        FriendStatus.IN_GAME -> "🟡 In Match"
                        FriendStatus.OFFLINE -> "⚪ ${friend.lastSeen}"
                    },
                    fontSize = 11.sp,
                    color = Color(friend.status.colorHex)
                )
            }

            // ACTIONS
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onToggleFavorite, modifier = Modifier.size(36.dp)) {
                    Icon(
                        imageVector = if (friend.isFavorite) Icons.Default.Star else Icons.Outlined.StarBorder,
                        contentDescription = "Favorite",
                        tint = if (friend.isFavorite) HighlightGold else GoatIvoryDark,
                        modifier = Modifier.size(20.dp)
                    )
                }

                Button(
                    onClick = onChallenge,
                    colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                    modifier = Modifier.testTag("challenge_friend_${friend.id}")
                ) {
                    Text("⚔️ Play", color = Color.Black, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                }

                IconButton(onClick = onRemove, modifier = Modifier.size(32.dp)) {
                    Icon(
                        imageVector = Icons.Default.DeleteOutline,
                        contentDescription = "Remove",
                        tint = GoatIvoryDark,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun OnlineRoomTabContent(
    userProfile: UserProfile,
    onStartGame: (level: BoardLevel, timer: GameTimer, side: PieceType, friendName: String, roomCode: String?) -> Unit
) {
    var createdRoomCode by remember { mutableStateOf<String?>(null) }
    var joinRoomInput by remember { mutableStateOf("") }
    var selectedLevel by remember { mutableStateOf(BoardLevel.SQUARE) }
    var selectedTimer by remember { mutableStateOf(GameTimer.CLASSIC) }
    var selectedSide by remember { mutableStateOf(PieceType.GOAT) }
    var copiedRoomNotice by remember { mutableStateOf(false) }
    val clipboardManager = LocalClipboardManager.current

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        if (createdRoomCode == null) {
            // CREATE ROOM CARD
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BoardWoodLight, RoundedCornerShape(18.dp))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(AmberTigerDark),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null, tint = HighlightGold)
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text("Create Private Room", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 15.sp)
                            Text("Host a custom match and invite any friend", fontSize = 12.sp, color = GoatIvoryDark)
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Text("BOARD LEVEL", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = HighlightGold, letterSpacing = 1.sp)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        BoardLevel.values().forEach { level ->
                            val isSelected = selectedLevel == level
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isSelected) AmberTiger else DarkSurfaceVariant,
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable { selectedLevel = level }
                            ) {
                                Text(
                                    text = level.displayName,
                                    fontSize = 11.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) Color.Black else Color.White,
                                    textAlign = TextAlign.Center,
                                    modifier = Modifier.padding(vertical = 8.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Text("MATCH CLOCK", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = HighlightGold, letterSpacing = 1.sp)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        listOf(GameTimer.RAPID to "5m", GameTimer.CLASSIC to "10m", GameTimer.STANDARD to "30m", GameTimer.LONG_MATCH to "1h", GameTimer.UNLIMITED to "∞").forEach { (timer, label) ->
                            val isSelected = selectedTimer == timer
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isSelected) AmberTiger else DarkSurfaceVariant,
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable { selectedTimer = timer }
                            ) {
                                Text(
                                    text = label,
                                    fontSize = 11.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) Color.Black else Color.White,
                                    textAlign = TextAlign.Center,
                                    modifier = Modifier.padding(vertical = 8.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Text("YOUR PIECE", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = HighlightGold, letterSpacing = 1.sp)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        listOf(PieceType.GOAT to "🐐 Goats", PieceType.TIGER to "🐅 Tigers").forEach { (side, label) ->
                            val isSelected = selectedSide == side
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isSelected) AmberTiger else DarkSurfaceVariant,
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable { selectedSide = side }
                            ) {
                                Text(
                                    text = label,
                                    fontSize = 11.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) Color.Black else Color.White,
                                    textAlign = TextAlign.Center,
                                    modifier = Modifier.padding(vertical = 8.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    Button(
                        onClick = {
                            createdRoomCode = "TIGER" + Random.nextInt(100, 999)
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp)
                            .testTag("create_room_button")
                    ) {
                        Text("Generate Room Code", fontWeight = FontWeight.Bold, color = Color.Black)
                    }
                }
            }

            // JOIN ROOM CARD
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BoardWoodLight, RoundedCornerShape(18.dp))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(DarkSurfaceVariant),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Login, contentDescription = null, tint = HighlightGold)
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text("Join Friend's Room", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 15.sp)
                            Text("Enter 6-digit game room code from your friend", fontSize = 12.sp, color = GoatIvoryDark)
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    OutlinedTextField(
                        value = joinRoomInput,
                        onValueChange = { if (it.length <= 8) joinRoomInput = it.uppercase() },
                        label = { Text("Room Code (e.g. TIGER789)") },
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = HighlightGold,
                            unfocusedBorderColor = DarkSurfaceVariant,
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("join_room_input")
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Button(
                        onClick = {
                            if (joinRoomInput.isNotBlank()) {
                                onStartGame(
                                    selectedLevel,
                                    selectedTimer,
                                    if (selectedSide == PieceType.GOAT) PieceType.TIGER else PieceType.GOAT,
                                    "Friend ($joinRoomInput)",
                                    joinRoomInput
                                )
                            }
                        },
                        enabled = joinRoomInput.length >= 4,
                        colors = ButtonDefaults.buttonColors(containerColor = ValidGreen),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp)
                            .testTag("join_room_button")
                    ) {
                        Text("Join Room & Play", fontWeight = FontWeight.Bold, color = Color.Black)
                    }
                }
            }
        } else {
            // WAITING ROOM
            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.5.dp, HighlightGold, RoundedCornerShape(20.dp))
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text("ROOM READY", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = ValidGreen, letterSpacing = 1.sp)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Share this code with your friend:", fontSize = 13.sp, color = GoatIvoryDark)

                    Spacer(modifier = Modifier.height(14.dp))

                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = DarkSurfaceVariant,
                        modifier = Modifier.border(1.dp, HighlightGold, RoundedCornerShape(12.dp))
                    ) {
                        Text(
                            text = createdRoomCode!!,
                            fontSize = 28.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color = HighlightGold,
                            letterSpacing = 4.sp,
                            modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = {
                                clipboardManager.setText(AnnotatedString(createdRoomCode!!))
                                copiedRoomNotice = true
                            },
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = HighlightGold),
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Copy Code", fontSize = 12.sp)
                        }

                        Button(
                            onClick = {
                                onStartGame(
                                    selectedLevel,
                                    selectedTimer,
                                    selectedSide,
                                    "Online Friend",
                                    createdRoomCode
                                )
                            },
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Start Game", fontWeight = FontWeight.Bold, color = Color.Black, fontSize = 12.sp)
                        }
                    }

                    if (copiedRoomNotice) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("Room Code copied to clipboard!", color = ValidGreen, fontSize = 11.sp)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
    }
}

@Composable
private fun PassAndPlayTabContent(
    userProfile: UserProfile,
    onStartPassAndPlay: (level: BoardLevel, p1Name: String, p2Name: String) -> Unit
) {
    var p1Name by remember { mutableStateOf(userProfile.username) }
    var p2Name by remember { mutableStateOf("Player 2") }
    var selectedLevel by remember { mutableStateOf(BoardLevel.SQUARE) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Card(
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = DarkSurface),
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, BoardWoodLight, RoundedCornerShape(18.dp))
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("2-PLAYER SAME DEVICE", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = HighlightGold, letterSpacing = 1.sp)
                Text("Pass the phone between turns for face-to-face tactical play", fontSize = 12.sp, color = GoatIvoryDark)

                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = p1Name,
                    onValueChange = { p1Name = it },
                    label = { Text("Player 1 (Goats 🐐)") },
                    singleLine = true,
                    shape = RoundedCornerShape(10.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = HighlightGold,
                        unfocusedBorderColor = DarkSurfaceVariant,
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("player1_name_input")
                )

                Spacer(modifier = Modifier.height(10.dp))

                OutlinedTextField(
                    value = p2Name,
                    onValueChange = { p2Name = it },
                    label = { Text("Player 2 (Tigers 🐅)") },
                    singleLine = true,
                    shape = RoundedCornerShape(10.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = AmberTiger,
                        unfocusedBorderColor = DarkSurfaceVariant,
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("player2_name_input")
                )

                Spacer(modifier = Modifier.height(16.dp))

                Text("BOARD LEVEL", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = HighlightGold, letterSpacing = 1.sp)
                Spacer(modifier = Modifier.height(6.dp))
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    BoardLevel.values().forEach { level ->
                        val isSelected = selectedLevel == level
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (isSelected) AmberTiger else DarkSurfaceVariant,
                            modifier = Modifier
                                .weight(1f)
                                .clickable { selectedLevel = level }
                        ) {
                            Text(
                                text = level.displayName,
                                fontSize = 11.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                color = if (isSelected) Color.Black else Color.White,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(vertical = 8.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(18.dp))

                Button(
                    onClick = {
                        onStartPassAndPlay(selectedLevel, p1Name, p2Name)
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                        .testTag("start_pass_and_play_button")
                ) {
                    Icon(Icons.Default.People, contentDescription = null, tint = Color.Black)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Start Pass & Play Match",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
    }
}
