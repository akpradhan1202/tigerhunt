package com.tigerhunt.tigerhunt.ui.screens

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
import androidx.compose.foundation.BorderStroke
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
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
import com.tigerhunt.tigerhunt.model.AuthMethod
import com.tigerhunt.tigerhunt.model.BoardTheme
import com.tigerhunt.tigerhunt.ui.theme.*
import com.tigerhunt.tigerhunt.viewmodel.GameViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: GameViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToAuth: () -> Unit,
    onLogout: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()
    var showLogoutDialog by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Settings",
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("settings_back_button")) {
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
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // ACCOUNT & LOGIN CARD
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("settings_account_card")
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onNavigateToAuth() },
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(46.dp)
                                .clip(CircleShape)
                                .background(DarkSurfaceVariant)
                                .border(1.5.dp, HighlightGold, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(uiState.userProfile.avatarId, fontSize = 22.sp)
                        }

                        Spacer(modifier = Modifier.width(14.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = uiState.userProfile.username,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    color = Color.White
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                if (uiState.userProfile.isLoggedIn) {
                                    Surface(
                                        shape = RoundedCornerShape(4.dp),
                                        color = ValidGreen.copy(alpha = 0.2f)
                                    ) {
                                        Text(
                                            "SYNCED",
                                            color = ValidGreen,
                                            fontSize = 9.sp,
                                            fontWeight = FontWeight.Bold,
                                            modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                                        )
                                    }
                                }
                            }

                            Text(
                                text = when (uiState.userProfile.authMethod) {
                                    AuthMethod.GMAIL -> "Google: ${uiState.userProfile.email ?: "Linked"}"
                                    AuthMethod.PHONE -> "Phone: ${uiState.userProfile.phoneNumber ?: "Linked"}"
                                    AuthMethod.GUEST -> "Guest Player (Tap to manage account)"
                                },
                                fontSize = 12.sp,
                                color = GoatIvoryDark
                            )
                        }

                        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = HighlightGold)
                    }

                    Spacer(modifier = Modifier.height(12.dp))
                    HorizontalDivider(color = DarkSurfaceVariant)
                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        TextButton(
                            onClick = onNavigateToAuth,
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text(
                                text = if (uiState.userProfile.isLoggedIn) "Account Details" else "Sign In / Link Account",
                                color = HighlightGold,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        OutlinedButton(
                            onClick = { showLogoutDialog = true },
                            shape = RoundedCornerShape(8.dp),
                            border = BorderStroke(1.dp, Color(0xFFFF8A80).copy(alpha = 0.6f)),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFFF8A80)),
                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                            modifier = Modifier.testTag("settings_logout_btn")
                        ) {
                            Icon(Icons.Default.Logout, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color(0xFFFF8A80))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Log Out", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFFFF8A80))
                        }
                    }
                }
            }

            // AUDIO & HAPTICS
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "AUDIO & FEEDBACK",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold,
                        letterSpacing = 1.sp
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Sound Effects", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = Color.White)
                            Text("Authentic game piece and audio cues", fontSize = 12.sp, color = GoatIvoryDark)
                        }
                        Switch(
                            checked = uiState.soundEnabled,
                            onCheckedChange = { viewModel.toggleSound() },
                            modifier = Modifier.testTag("sound_effects_switch")
                        )
                    }

                    HorizontalDivider(color = DarkSurfaceVariant, modifier = Modifier.padding(vertical = 10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Haptic Feedback", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = Color.White)
                            Text("Vibrate on moves and captures", fontSize = 12.sp, color = GoatIvoryDark)
                        }
                        Switch(
                            checked = uiState.hapticsEnabled,
                            onCheckedChange = { viewModel.toggleHaptics() },
                            modifier = Modifier.testTag("haptics_switch")
                        )
                    }
                }
            }

            // PUSH NOTIFICATIONS & FCM
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth().testTag("push_notifications_settings_card")
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Default.NotificationsActive,
                                contentDescription = null,
                                tint = HighlightGold,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "PUSH NOTIFICATIONS & FCM",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = HighlightGold,
                                letterSpacing = 1.sp
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (uiState.pushNotificationsEnabled) Color(0xFF2E7D32).copy(alpha = 0.3f) else DarkSurfaceVariant
                        ) {
                            Text(
                                text = if (uiState.pushNotificationsEnabled) "FCM ACTIVE" else "DISABLED",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (uiState.pushNotificationsEnabled) Color(0xFF81C784) else GoatIvoryDark,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // Master Toggle
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Allow Push Notifications", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = Color.White)
                            Text("Receive alerts when app is in background or closed", fontSize = 12.sp, color = GoatIvoryDark)
                        }
                        Switch(
                            checked = uiState.pushNotificationsEnabled,
                            onCheckedChange = { viewModel.togglePushNotifications() },
                            modifier = Modifier.testTag("push_notifications_master_switch")
                        )
                    }

                    if (uiState.pushNotificationsEnabled) {
                        HorizontalDivider(color = DarkSurfaceVariant, modifier = Modifier.padding(vertical = 10.dp))

                        // Turn Notifications Toggle
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text("Friend Match & Turn Alerts", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color.White)
                                Text("Notifies you instantly when a friend makes a move", fontSize = 11.sp, color = GoatIvoryDark)
                            }
                            Switch(
                                checked = uiState.turnNotificationsEnabled,
                                onCheckedChange = { viewModel.toggleTurnNotifications() },
                                modifier = Modifier.testTag("turn_notifications_switch")
                            )
                        }

                        HorizontalDivider(color = DarkSurfaceVariant, modifier = Modifier.padding(vertical = 10.dp))

                        // Tournament Notifications Toggle
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text("Tournament Starts & Brackets", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color.White)
                                Text("Notifies when a tournament starts or your round begins", fontSize = 11.sp, color = GoatIvoryDark)
                            }
                            Switch(
                                checked = uiState.tournamentNotificationsEnabled,
                                onCheckedChange = { viewModel.toggleTournamentNotifications() },
                                modifier = Modifier.testTag("tournament_notifications_switch")
                            )
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Testing Actions
                        Text(
                            text = "TEST PUSH NOTIFICATIONS",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = GoatIvoryDark,
                            letterSpacing = 0.5.sp
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            OutlinedButton(
                                onClick = { viewModel.testFriendTurnNotification() },
                                shape = RoundedCornerShape(10.dp),
                                border = BorderStroke(1.dp, AmberTiger.copy(alpha = 0.6f)),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = AmberTiger),
                                modifier = Modifier.weight(1f).testTag("test_turn_notification_button")
                            ) {
                                Text("⚡ Test Turn Alert", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }

                            OutlinedButton(
                                onClick = { viewModel.testTournamentStartNotification() },
                                shape = RoundedCornerShape(10.dp),
                                border = BorderStroke(1.dp, HighlightGold.copy(alpha = 0.6f)),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = HighlightGold),
                                modifier = Modifier.weight(1f).testTag("test_tournament_notification_button")
                            ) {
                                Text("🏆 Test Tourney Alert", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                        }

                        if (uiState.notificationTestStatus != null) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = Color(0xFF1B5E20).copy(alpha = 0.4f),
                                border = BorderStroke(1.dp, Color(0xFF81C784).copy(alpha = 0.5f)),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.padding(8.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(
                                        text = "✓ ${uiState.notificationTestStatus}",
                                        fontSize = 11.sp,
                                        color = Color(0xFFA5D6A7),
                                        modifier = Modifier.weight(1f)
                                    )
                                    TextButton(
                                        onClick = { viewModel.dismissNotificationTestStatus() },
                                        contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp)
                                    ) {
                                        Text("Dismiss", fontSize = 10.sp, color = Color.White)
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "FCM Token: ${uiState.fcmToken?.take(18) ?: "Generating..."}... (Topic Subscriptions: tournaments, friend_matches)",
                            fontSize = 10.sp,
                            color = GoatIvoryDark.copy(alpha = 0.7f)
                        )
                    }
                }
            }

            // BOARD THEMES
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "BOARD THEME",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = HighlightGold,
                        letterSpacing = 1.sp
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    BoardTheme.values().forEach { theme ->
                        val isSelected = uiState.currentTheme == theme
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (isSelected) DarkSurfaceVariant else Color.Transparent,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { viewModel.setTheme(theme) }
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = theme.displayName,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isSelected) HighlightGold else Color.White
                                    )
                                    Text(
                                        text = theme.description,
                                        fontSize = 11.sp,
                                        color = GoatIvoryDark
                                    )
                                }
                                if (isSelected) {
                                    Text("✓", color = HighlightGold, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                                }
                            }
                        }
                    }
                }
            }

            // ABOUT
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Tiger Hunt - Bagh-Chal",
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        color = Color.White
                    )
                    Text(
                        text = "Version 1.0.0 • Modern Android & Jetpack Compose Edition",
                        fontSize = 12.sp,
                        color = GoatIvoryDark
                    )
                }
            }

            // DEDICATED LOGOUT / EXIT SESSION BUTTON
            OutlinedButton(
                onClick = { showLogoutDialog = true },
                shape = RoundedCornerShape(14.dp),
                border = BorderStroke(1.5.dp, Color(0xFFFF8A80).copy(alpha = 0.7f)),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFFF8A80)),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .testTag("settings_bottom_logout_button")
            ) {
                Icon(Icons.Default.Logout, contentDescription = null, tint = Color(0xFFFF8A80))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Log Out & Clear Session", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color(0xFFFF8A80))
            }

            Spacer(modifier = Modifier.height(16.dp))
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
                    Text("Confirm Log Out", fontWeight = FontWeight.Bold, color = Color.White)
                }
            },
            text = {
                Text(
                    text = "Are you sure you want to log out? Your session will be cleared and you will be returned to the sign-in and guest access screen.",
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
                    modifier = Modifier.testTag("confirm_logout_button")
                ) {
                    Text("Log Out", color = Color.White, fontWeight = FontWeight.Bold)
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
