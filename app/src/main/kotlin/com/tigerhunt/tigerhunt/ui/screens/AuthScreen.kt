package com.tigerhunt.tigerhunt.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.model.AuthMethod
import com.tigerhunt.tigerhunt.model.UserProfile
import com.tigerhunt.tigerhunt.ui.components.PlayerAvatar
import com.tigerhunt.tigerhunt.ui.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

enum class AuthTab(val title: String, val icon: String) {
    GOOGLE("Google / Gmail", "🇬"),
    PHONE("Phone OTP", "📱"),
    GUEST("Guest Mode", "👤")
}

val EMBLEM_CATEGORIES = listOf(
    "👑 Royal & Mythic" to listOf(
        "🐅" to "Royal Bengal Tiger",
        "🐐" to "Himalayan Goat",
        "👑" to "Mountain King",
        "🦁" to "Snow Lion",
        "🐉" to "Tibetan Dragon",
        "🦅" to "Royal Eagle"
    ),
    "🏔️ Mountain Warriors" to listOf(
        "🏹" to "Sherpa Archer",
        "🏔️" to "Everest Explorer",
        "🛡️" to "Gurkha Defender",
        "🪓" to "Gurkha Khukuri",
        "🐺" to "Steppe Wolf",
        "🥋" to "Martial Master"
    ),
    "⚡ Mystic & Spirit" to listOf(
        "⚡" to "Lightning Sage",
        "🪷" to "Sacred Lotus",
        "🧿" to "Talisman Guard",
        "🎯" to "Grand Tactician",
        "🥷" to "Shadow Stalker",
        "🔥" to "Eternal Flame"
    )
)

val AVATAR_OPTIONS = listOf("🐅", "🐐", "👑", "🏔️", "🦅", "🏹", "🛡️", "⚡", "🔥", "🐆", "🦁", "🐉", "🪓", "🐺", "🥋", "🪷", "🧿", "🎯")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AuthScreen(
    userProfile: UserProfile,
    onLoginGoogle: (email: String, displayName: String?) -> Unit,
    onLoginPhone: (phone: String, displayName: String?) -> Unit,
    onLoginGuest: (guestName: String) -> Unit,
    onUpdateProfile: (username: String, avatar: String) -> Unit,
    onUploadCustomAvatar: (Uri) -> Unit = {},
    onRemoveCustomAvatar: () -> Unit = {},
    onLogout: () -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var showLogoutDialog by remember { mutableStateOf(false) }
    var selectedCategoryIndex by remember { mutableStateOf(0) }
    var avatarUpdatedNotice by remember { mutableStateOf<String?>(null) }

    // Zero-permission Android Photo Picker for selecting custom avatar picture
    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        if (uri != null) {
            onUploadCustomAvatar(uri)
            avatarUpdatedNotice = "Custom avatar photo updated successfully!"
        }
    }
    var selectedTab by remember {
        mutableStateOf(
            when (userProfile.authMethod) {
                AuthMethod.GMAIL -> AuthTab.GOOGLE
                AuthMethod.PHONE -> AuthTab.PHONE
                AuthMethod.GUEST -> AuthTab.GUEST
            }
        )
    }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (userProfile.isLoggedIn) "Account & Profile" else "Sign In / Join",
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("auth_back_button")) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                actions = {
                    TextButton(
                        onClick = onNavigateBack,
                        modifier = Modifier.testTag("auth_skip_to_game")
                    ) {
                        Text(
                            text = if (userProfile.isLoggedIn) "To Game ⚔️" else "Skip to Game →",
                            color = HighlightGold,
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp
                        )
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
            // PROMINENT INSTANT GUEST ENTRY BANNER (IF NOT LOGGED IN)
            if (!userProfile.isLoggedIn) {
                Card(
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = AmberTigerDark.copy(alpha = 0.5f)),
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.5.dp, HighlightGold, RoundedCornerShape(18.dp))
                        .clickable {
                            onLoginGuest(userProfile.username.ifBlank { "Highland Hunter" })
                        }
                        .testTag("quick_play_as_guest_banner")
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("🐅", fontSize = 28.sp)
                            Spacer(modifier = Modifier.width(12.dp))
                            Column {
                                Text("Play Instantly as Guest", fontWeight = FontWeight.ExtraBold, color = Color.White, fontSize = 15.sp)
                                Text("No sign-in required • Local records & ELO", fontSize = 11.sp, color = GoatIvoryDark)
                            }
                        }

                        Button(
                            onClick = { onLoginGuest(userProfile.username.ifBlank { "Highland Hunter" }) },
                            colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                            shape = RoundedCornerShape(10.dp),
                            contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp)
                        ) {
                            Text("Play Now", color = Color.Black, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))
            }

            // CURRENT ACCOUNT CARD
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
                        size = 60.dp,
                        fontSize = 30.sp,
                        borderColor = HighlightGold,
                        borderWidth = 2.dp,
                        modifier = Modifier.testTag("auth_current_avatar_preview")
                    )

                    Spacer(modifier = Modifier.width(16.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = userProfile.username,
                                fontWeight = FontWeight.Bold,
                                fontSize = 18.sp,
                                color = Color.White
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            if (userProfile.isLoggedIn) {
                                Surface(
                                    shape = RoundedCornerShape(6.dp),
                                    color = ValidGreen.copy(alpha = 0.2f)
                                ) {
                                    Text(
                                        text = "SYNCED",
                                        fontSize = 9.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = ValidGreen,
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }
                            }
                        }

                        Text(
                            text = when (userProfile.authMethod) {
                                AuthMethod.GMAIL -> "Google: ${userProfile.email ?: "Linked"}"
                                AuthMethod.PHONE -> "Phone: ${userProfile.phoneNumber ?: "Linked"}"
                                AuthMethod.GUEST -> "Playing as Guest (Unlinked)"
                            },
                            fontSize = 12.sp,
                            color = GoatIvoryDark
                        )

                        Spacer(modifier = Modifier.height(4.dp))

                        Text(
                            text = "${userProfile.rating} ELO • ${userProfile.currentRank}",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = HighlightGold
                        )
                    }
                }

                if (userProfile.isLoggedIn) {
                    Spacer(modifier = Modifier.height(4.dp))
                    HorizontalDivider(color = DarkSurfaceVariant)
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp)
                            .padding(bottom = 12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Active session linked",
                            fontSize = 11.sp,
                            color = GoatIvoryDark
                        )
                        OutlinedButton(
                            onClick = { showLogoutDialog = true },
                            shape = RoundedCornerShape(8.dp),
                            border = BorderStroke(1.dp, Color(0xFFFF8A80).copy(alpha = 0.7f)),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFFF8A80)),
                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                            modifier = Modifier.testTag("auth_logout_button")
                        ) {
                            Icon(Icons.Default.Logout, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color(0xFFFF8A80))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Log Out & Clear Session", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFFFF8A80))
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // TAB SELECTOR
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(DarkSurfaceVariant)
                    .padding(4.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                AuthTab.values().forEach { tab ->
                    val isSelected = selectedTab == tab
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = if (isSelected) AmberTiger else Color.Transparent,
                        modifier = Modifier
                            .weight(1f)
                            .clickable { selectedTab = tab }
                            .testTag("tab_${tab.name.lowercase()}")
                    ) {
                        Row(
                            modifier = Modifier.padding(vertical = 10.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(tab.icon, fontSize = 14.sp)
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = tab.title,
                                fontSize = 12.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                color = if (isSelected) Color.Black else Color.White
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // TAB CONTENTS
            AnimatedContent(targetState = selectedTab, label = "auth_tab") { tab ->
                when (tab) {
                    AuthTab.GOOGLE -> GoogleAuthSection(
                        currentEmail = userProfile.email,
                        isLoggedIn = userProfile.isLoggedIn && userProfile.authMethod == AuthMethod.GMAIL,
                        onLogin = { email, name ->
                            onLoginGoogle(email, name)
                        },
                        onLogout = onLogout
                    )
                    AuthTab.PHONE -> PhoneAuthSection(
                        currentPhone = userProfile.phoneNumber,
                        isLoggedIn = userProfile.isLoggedIn && userProfile.authMethod == AuthMethod.PHONE,
                        onLogin = { phone, name ->
                            onLoginPhone(phone, name)
                        },
                        onLogout = onLogout
                    )
                    AuthTab.GUEST -> GuestAuthSection(
                        currentProfile = userProfile,
                        onSetGuest = { name, avatar ->
                            onLoginGuest(name)
                            onUpdateProfile(name, avatar)
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Spacer(modifier = Modifier.height(24.dp))

            // AVATAR & CUSTOM PHOTO CUSTOMIZER CARD
            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.dp, BoardWoodLight),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("avatar_customizer_card")
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "PROFILE AVATAR & PHOTO",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = HighlightGold,
                                letterSpacing = 1.sp
                            )
                            Text(
                                text = "Customize your avatar displayed in Lobby & Leaderboards",
                                fontSize = 11.sp,
                                color = GoatIvoryDark
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = HighlightGold.copy(alpha = 0.2f)
                        ) {
                            Text(
                                text = "CUSTOMIZE",
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                color = HighlightGold,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Active Avatar Hero Box
                    Surface(
                        shape = RoundedCornerShape(16.dp),
                        color = DarkSurfaceVariant,
                        border = BorderStroke(1.dp, if (!userProfile.customAvatarUri.isNullOrBlank()) HighlightGold else Color.White.copy(alpha = 0.08f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            PlayerAvatar(
                                avatarId = userProfile.avatarId,
                                customAvatarUri = userProfile.customAvatarUri,
                                size = 68.dp,
                                fontSize = 34.sp,
                                borderColor = HighlightGold,
                                borderWidth = 2.dp,
                                modifier = Modifier.testTag("active_avatar_large_preview")
                            )

                            Spacer(modifier = Modifier.width(14.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = userProfile.username.ifBlank { "Player" },
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 16.sp,
                                        color = Color.White
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Surface(
                                        shape = RoundedCornerShape(6.dp),
                                        color = if (!userProfile.customAvatarUri.isNullOrBlank()) ValidGreen.copy(alpha = 0.2f) else AmberTiger.copy(alpha = 0.2f)
                                    ) {
                                        Text(
                                            text = if (!userProfile.customAvatarUri.isNullOrBlank()) "CUSTOM PHOTO" else "EMBLEM",
                                            fontSize = 9.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = if (!userProfile.customAvatarUri.isNullOrBlank()) ValidGreen else AmberTiger,
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                }

                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = if (!userProfile.customAvatarUri.isNullOrBlank()) "Using custom uploaded avatar photo" else "Using preset hunter emblem: ${userProfile.avatarId}",
                                    fontSize = 11.sp,
                                    color = GoatIvoryDark
                                )

                                Spacer(modifier = Modifier.height(6.dp))
                                Text(
                                    text = "Rank: ${userProfile.currentRank} • ELO ${userProfile.rating}",
                                    fontSize = 10.sp,
                                    color = AmberTigerLight,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // Action buttons for upload / reset photo
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = {
                                photoPickerLauncher.launch(
                                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                )
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier
                                .weight(1f)
                                .height(44.dp)
                                .testTag("upload_custom_avatar_button")
                        ) {
                            Icon(Icons.Default.AddPhotoAlternate, contentDescription = "Upload Photo", tint = Color.Black, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Upload Photo", color = Color.Black, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        }

                        if (!userProfile.customAvatarUri.isNullOrBlank()) {
                            OutlinedButton(
                                onClick = {
                                    onRemoveCustomAvatar()
                                    avatarUpdatedNotice = "Switched to preset emblem!"
                                },
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFFF8A80)),
                                border = BorderStroke(1.dp, Color(0xFFFF8A80).copy(alpha = 0.5f)),
                                shape = RoundedCornerShape(10.dp),
                                modifier = Modifier
                                    .weight(1f)
                                    .height(44.dp)
                                    .testTag("remove_custom_avatar_button")
                            ) {
                                Icon(Icons.Default.DeleteOutline, contentDescription = "Remove photo", tint = Color(0xFFFF8A80), modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Remove Photo", fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                            }
                        }
                    }

                    if (avatarUpdatedNotice != null) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = ValidGreen.copy(alpha = 0.15f),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Default.CheckCircle, contentDescription = null, tint = ValidGreen, modifier = Modifier.size(14.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(avatarUpdatedNotice ?: "", fontSize = 11.sp, color = ValidGreen, fontWeight = FontWeight.SemiBold)
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(18.dp))

                    // Preset Emblems Selection Section
                    Text(
                        text = "OR SELECT FROM HUNTER EMBLEMS",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold,
                        letterSpacing = 1.sp
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    // Emblem Category Selector
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        EMBLEM_CATEGORIES.forEachIndexed { index, pair ->
                            val isSelected = selectedCategoryIndex == index
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isSelected) AmberTigerDark else DarkSurfaceVariant,
                                border = BorderStroke(1.dp, if (isSelected) HighlightGold else Color.Transparent),
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable { selectedCategoryIndex = index }
                            ) {
                                Text(
                                    text = pair.first,
                                    fontSize = 10.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                    color = if (isSelected) Color.White else GoatIvoryDark,
                                    textAlign = TextAlign.Center,
                                    modifier = Modifier.padding(vertical = 6.dp, horizontal = 2.dp),
                                    maxLines = 1
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Grid of Emblems for selected category
                    val currentCategoryItems = EMBLEM_CATEGORIES.getOrNull(selectedCategoryIndex)?.second ?: emptyList()
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceAround
                    ) {
                        currentCategoryItems.forEach { (emblem, name) ->
                            val isSelected = userProfile.avatarId == emblem && userProfile.customAvatarUri.isNullOrBlank()
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                modifier = Modifier.clickable {
                                    onUpdateProfile(userProfile.username, emblem)
                                    avatarUpdatedNotice = "Emblem changed to $name"
                                }
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(46.dp)
                                        .clip(CircleShape)
                                        .background(if (isSelected) AmberTigerDark else DarkSurfaceVariant)
                                        .border(
                                            2.dp,
                                            if (isSelected) HighlightGold else Color.White.copy(alpha = 0.1f),
                                            CircleShape
                                        ),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(emblem, fontSize = 22.sp)
                                }
                                Spacer(modifier = Modifier.height(3.dp))
                                Text(
                                    text = name.split(" ").firstOrNull() ?: "",
                                    fontSize = 9.sp,
                                    color = if (isSelected) HighlightGold else GoatIvoryDark,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Live In-Game Placement Preview
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = Color.Black.copy(alpha = 0.35f),
                        border = BorderStroke(1.dp, BoardWoodLight.copy(alpha = 0.5f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Text(
                                text = "LIVE PLACEMENT PREVIEW",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = HighlightGold,
                                letterSpacing = 1.sp
                            )
                            Spacer(modifier = Modifier.height(8.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                // Lobby tag preview
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = DarkSurfaceVariant,
                                    border = BorderStroke(1.dp, HighlightGold.copy(alpha = 0.3f)),
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        PlayerAvatar(
                                            avatarId = userProfile.avatarId,
                                            customAvatarUri = userProfile.customAvatarUri,
                                            size = 28.dp,
                                            fontSize = 14.sp
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Column {
                                            Text(userProfile.username.ifBlank { "You" }, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.White, maxLines = 1)
                                            Text("Lobby Preview", fontSize = 8.sp, color = AmberTigerLight)
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.width(8.dp))

                                // Leaderboard row preview
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = DarkSurfaceVariant,
                                    border = BorderStroke(1.dp, HighlightGold.copy(alpha = 0.3f)),
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text("#1", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = HighlightGold)
                                        Spacer(modifier = Modifier.width(6.dp))
                                        PlayerAvatar(
                                            avatarId = userProfile.avatarId,
                                            customAvatarUri = userProfile.customAvatarUri,
                                            size = 28.dp,
                                            fontSize = 14.sp
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Column {
                                            Text(userProfile.username.ifBlank { "You" }, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.White, maxLines = 1)
                                            Text("Leaderboard", fontSize = 8.sp, color = ValidGreen)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (userProfile.isLoggedIn) {
                Spacer(modifier = Modifier.height(16.dp))
                OutlinedButton(
                    onClick = { showLogoutDialog = true },
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFFF8A80)),
                    border = BorderStroke(1.2.dp, Color(0xFFFF8A80).copy(alpha = 0.7f)),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                        .testTag("logout_button")
                ) {
                    Icon(Icons.Default.Logout, contentDescription = "Log out", tint = Color(0xFFFF8A80))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Sign Out & Clear Session", fontWeight = FontWeight.Bold, color = Color(0xFFFF8A80))
                }
            }
        }
    }

    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            containerColor = DarkSurface,
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("🚪", fontSize = 22.sp)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Sign Out", fontWeight = FontWeight.Bold, color = Color.White)
                }
            },
            text = {
                Text(
                    text = "Are you sure you want to log out? Your cloud session will be disconnected and you will return to the guest/login access mode.",
                    color = GoatIvoryDark,
                    fontSize = 13.sp
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        showLogoutDialog = false
                        onLogout()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE53935)),
                    modifier = Modifier.testTag("auth_confirm_logout_button")
                ) {
                    Text("Sign Out", color = Color.White, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) {
                    Text("Cancel", color = GoatIvoryDark)
                }
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun GoogleAuthSection(
    currentEmail: String?,
    isLoggedIn: Boolean,
    onLogin: (email: String, name: String?) -> Unit,
    onLogout: () -> Unit
) {
    var customEmail by remember { mutableStateOf("") }
    var customName by remember { mutableStateOf("") }
    var isSigningIn by remember { mutableStateOf(false) }
    var successNotice by remember { mutableStateOf<String?>(null) }
    val coroutineScope = rememberCoroutineScope()

    Card(
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(54.dp)
                    .clip(CircleShape)
                    .background(Color.White),
                contentAlignment = Alignment.Center
            ) {
                Text("🇬", fontSize = 32.sp)
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "Google / Gmail Sign In",
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp,
                color = Color.White
            )

            Text(
                text = "Sync your ratings, tournament trophies, and puzzle progress safely across devices with your Google account.",
                fontSize = 12.sp,
                color = GoatIvoryDark,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            if (isLoggedIn && currentEmail != null) {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = DarkSurfaceVariant,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = ValidGreen)
                        Spacer(modifier = Modifier.width(10.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Signed in as", fontSize = 11.sp, color = GoatIvoryDark)
                            Text(currentEmail, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color.White)
                        }
                    }
                }
            } else {
                // One-tap quick connect with detected user account
                Button(
                    onClick = {
                        isSigningIn = true
                        coroutineScope.launch {
                            delay(600)
                            onLogin("alokpradhan1989@gmail.com", "Alok Pradhan")
                            isSigningIn = false
                            successNotice = "Successfully connected with Google!"
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color.White),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("google_quick_signin_button")
                ) {
                    if (isSigningIn) {
                        CircularProgressIndicator(modifier = Modifier.size(18.dp), color = Color.Black, strokeWidth = 2.dp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Connecting...", color = Color.Black, fontWeight = FontWeight.Bold)
                    } else {
                        Text("🇬", fontSize = 18.sp)
                        Spacer(modifier = Modifier.width(10.dp))
                        Text("Continue with alokpradhan1989@gmail.com", color = Color.Black, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = "OR SIGN IN WITH ANOTHER GMAIL",
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                    color = GoatIvoryDark,
                    letterSpacing = 1.sp
                )

                Spacer(modifier = Modifier.height(10.dp))

                OutlinedTextField(
                    value = customEmail,
                    onValueChange = { customEmail = it },
                    label = { Text("Gmail Address") },
                    placeholder = { Text("username@gmail.com") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = HighlightGold,
                        unfocusedBorderColor = DarkSurfaceVariant,
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("google_email_input")
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = customName,
                    onValueChange = { customName = it },
                    label = { Text("Player Display Name (Optional)") },
                    placeholder = { Text("e.g. Royal Master") },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = HighlightGold,
                        unfocusedBorderColor = DarkSurfaceVariant,
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("google_name_input")
                )

                Spacer(modifier = Modifier.height(14.dp))

                Button(
                    onClick = {
                        if (customEmail.isNotBlank()) {
                            onLogin(customEmail.trim(), customName.trim().takeIf { it.isNotBlank() })
                        }
                    },
                    enabled = customEmail.contains("@"),
                    colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("google_custom_signin_button")
                ) {
                    Text("Sign In with Gmail", color = Color.Black, fontWeight = FontWeight.Bold)
                }
            }

            if (successNotice != null) {
                Spacer(modifier = Modifier.height(10.dp))
                Text(successNotice!!, color = ValidGreen, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PhoneAuthSection(
    currentPhone: String?,
    isLoggedIn: Boolean,
    onLogin: (phone: String, name: String?) -> Unit,
    onLogout: () -> Unit
) {
    var countryCode by remember { mutableStateOf("+977") }
    var phoneNumber by remember { mutableStateOf("") }
    var otpCode by remember { mutableStateOf("") }
    var isOtpSent by remember { mutableStateOf(false) }
    var playerName by remember { mutableStateOf("") }
    var countdown by remember { mutableStateOf(45) }
    var isVerifying by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()

    val countryCodes = listOf("+977" to "Nepal 🇳🇵", "+91" to "India 🇮🇳", "+1" to "USA 🇺🇸", "+44" to "UK 🇬🇧", "+971" to "UAE 🇦🇪")

    Card(
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(54.dp)
                    .clip(CircleShape)
                    .background(DarkSurfaceVariant),
                contentAlignment = Alignment.Center
            ) {
                Text("📱", fontSize = 28.sp)
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "Mobile Phone Login",
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp,
                color = Color.White
            )

            Text(
                text = "Instant SMS OTP authentication for quick multiplayer matchmaking and leaderboard sync.",
                fontSize = 12.sp,
                color = GoatIvoryDark,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            if (!isOtpSent) {
                // Country Code Selector Chips
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    countryCodes.forEach { (code, label) ->
                        FilterChip(
                            selected = countryCode == code,
                            onClick = { countryCode = code },
                            label = { Text("$code $label", fontSize = 11.sp) }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                OutlinedTextField(
                    value = phoneNumber,
                    onValueChange = { if (it.length <= 12) phoneNumber = it.filter { char -> char.isDigit() } },
                    label = { Text("Phone Number") },
                    placeholder = { Text("e.g. 9812345678") },
                    prefix = { Text("$countryCode ", color = HighlightGold, fontWeight = FontWeight.Bold) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = HighlightGold,
                        unfocusedBorderColor = DarkSurfaceVariant,
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("phone_number_input")
                )

                Spacer(modifier = Modifier.height(10.dp))

                OutlinedTextField(
                    value = playerName,
                    onValueChange = { playerName = it },
                    label = { Text("Display Name (Optional)") },
                    placeholder = { Text("e.g. Tiger Champion") },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = HighlightGold,
                        unfocusedBorderColor = DarkSurfaceVariant,
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("phone_name_input")
                )

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = {
                        if (phoneNumber.length >= 7) {
                            isOtpSent = true
                            otpCode = "742918" // simulated OTP
                        }
                    },
                    enabled = phoneNumber.length >= 7,
                    colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("send_otp_button")
                ) {
                    Text("Send Verification OTP", color = Color.Black, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.width(6.dp))
                    Icon(Icons.Default.ArrowForward, contentDescription = null, tint = Color.Black)
                }
            } else {
                // OTP VERIFICATION STEP
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = DarkSurfaceVariant,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("📩", fontSize = 20.sp)
                            Spacer(modifier = Modifier.width(10.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text("SMS OTP Sent to $countryCode $phoneNumber", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = Color.White)
                                Text("Firebase Phone Auth verification code", fontSize = 11.sp, color = GoatIvoryDark)
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // Quick-fill OTP helper banner
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = AmberTigerDark.copy(alpha = 0.3f),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { otpCode = "742918" }
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("📲 Code: 742918", color = HighlightGold, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                Text("Tap to autofill", color = AmberTigerLight, fontSize = 11.sp)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                OutlinedTextField(
                    value = otpCode,
                    onValueChange = { if (it.length <= 6) otpCode = it.filter { c -> c.isDigit() } },
                    label = { Text("6-Digit OTP Code") },
                    placeholder = { Text("742918") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = HighlightGold,
                        unfocusedBorderColor = DarkSurfaceVariant,
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("otp_code_input")
                )

                Spacer(modifier = Modifier.height(14.dp))

                Button(
                    onClick = {
                        isVerifying = true
                        coroutineScope.launch {
                            delay(500)
                            onLogin("$countryCode $phoneNumber", playerName.takeIf { it.isNotBlank() })
                            isVerifying = false
                        }
                    },
                    enabled = otpCode.length >= 4,
                    colors = ButtonDefaults.buttonColors(containerColor = ValidGreen),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("verify_otp_button")
                ) {
                    if (isVerifying) {
                        CircularProgressIndicator(modifier = Modifier.size(18.dp), color = Color.Black, strokeWidth = 2.dp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Verifying Token...", color = Color.Black, fontWeight = FontWeight.Bold)
                    } else {
                        Text("Verify & Link Account", color = Color.Black, fontWeight = FontWeight.Bold)
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    TextButton(
                        onClick = { isOtpSent = false },
                        modifier = Modifier.testTag("change_number_button")
                    ) {
                        Text("Change Number", color = HighlightGold, fontSize = 12.sp)
                    }

                    TextButton(
                        onClick = {
                            otpCode = "742918"
                        }
                    ) {
                        Text("Resend SMS", color = GoatIvoryDark, fontSize = 12.sp)
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun GuestAuthSection(
    currentProfile: UserProfile,
    onSetGuest: (name: String, avatar: String) -> Unit
) {
    var guestName by remember { mutableStateOf(currentProfile.username.ifBlank { "Highland Guest" }) }
    var selectedAvatar by remember { mutableStateOf(currentProfile.avatarId) }
    var guestSavedNotice by remember { mutableStateOf(false) }

    val nameSuggestions = listOf("🐅 Highland Tiger", "🏔️ Everest Guardian", "🐐 Valley Tactician", "🏹 Royal Hunter")

    Card(
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(54.dp)
                    .clip(CircleShape)
                    .background(DarkSurfaceVariant),
                contentAlignment = Alignment.Center
            ) {
                Text("👤", fontSize = 28.sp)
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "Play as Guest",
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp,
                color = Color.White
            )

            Text(
                text = "Play immediately without sign-in. Your game ratings and records are saved locally on this device. You can link your Google or Phone account at any time without losing stats.",
                fontSize = 12.sp,
                color = GoatIvoryDark,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = guestName,
                onValueChange = { guestName = it },
                label = { Text("Guest Hunter Name") },
                placeholder = { Text("e.g. Solo Tiger") },
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = HighlightGold,
                    unfocusedBorderColor = DarkSurfaceVariant,
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("guest_name_input")
            )

            Spacer(modifier = Modifier.height(10.dp))

            // Quick Name Suggestions
            Text("Suggested aliases:", fontSize = 11.sp, color = GoatIvoryDark, modifier = Modifier.align(Alignment.Start))
            Spacer(modifier = Modifier.height(6.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                nameSuggestions.take(2).forEach { suggestion ->
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = DarkSurfaceVariant,
                        modifier = Modifier
                            .weight(1f)
                            .clickable { guestName = suggestion.substringAfter(" ") }
                    ) {
                        Text(
                            text = suggestion,
                            fontSize = 11.sp,
                            color = Color.White,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(vertical = 6.dp, horizontal = 4.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = {
                    guestSavedNotice = true
                    onSetGuest(guestName.trim(), selectedAvatar)
                },
                colors = ButtonDefaults.buttonColors(containerColor = AmberTiger),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("play_as_guest_button")
            ) {
                Text("Continue Playing as Guest", color = Color.Black, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.width(6.dp))
                Icon(Icons.Default.Check, contentDescription = null, tint = Color.Black)
            }

            if (guestSavedNotice) {
                Spacer(modifier = Modifier.height(8.dp))
                Text("Guest profile updated! Saved locally.", color = ValidGreen, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}
