package com.tigerhunt.tigerhunt

import android.Manifest
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.*
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.tigerhunt.tigerhunt.data.GamePreferences
import com.tigerhunt.tigerhunt.data.NotificationHelper
import com.tigerhunt.tigerhunt.model.*
import com.tigerhunt.tigerhunt.ui.screens.*
import com.tigerhunt.tigerhunt.ui.theme.DarkBackground
import com.tigerhunt.tigerhunt.ui.theme.TigerHuntTheme
import com.tigerhunt.tigerhunt.viewmodel.GameViewModel

class MainActivity : ComponentActivity() {
    private var initialNotificationRoute: String? = null
    private var initialRoomCode: String? = null
    private var initialFriendName: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        extractNotificationData(intent)

        setContent {
            TigerHuntTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = DarkBackground
                ) {
                    TigerHuntApp(
                        initialRoute = initialNotificationRoute,
                        initialRoomCode = initialRoomCode,
                        initialFriendName = initialFriendName
                    )
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractNotificationData(intent)
    }

    private fun extractNotificationData(intent: Intent?) {
        intent?.let {
            initialNotificationRoute = it.getStringExtra(NotificationHelper.EXTRA_ROUTE)
            initialRoomCode = it.getStringExtra(NotificationHelper.EXTRA_ROOM_CODE)
            initialFriendName = it.getStringExtra(NotificationHelper.EXTRA_FRIEND_NAME)
        }
    }
}

@Composable
fun TigerHuntApp(
    viewModel: GameViewModel = viewModel(),
    initialRoute: String? = null,
    initialRoomCode: String? = null,
    initialFriendName: String? = null
) {
    val navController = rememberNavController()
    val uiState by viewModel.uiState.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = androidx.compose.runtime.remember { GamePreferences(context) }

    val isAlreadyLoggedIn = prefs.getUserProfile().isLoggedIn

    // Runtime Permission Request for Android 13+ (POST_NOTIFICATIONS)
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        // Permission result handled
    }

    LaunchedEffect(Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    // Handle deep link notification route
    LaunchedEffect(initialRoute) {
        if (!initialRoute.isNullOrEmpty() && isAlreadyLoggedIn) {
            navController.navigate(initialRoute)
        }
    }

    NavHost(
        navController = navController,
        startDestination = if (isAlreadyLoggedIn) {
            if (!prefs.isFirstLoginTutorialCompleted()) "tutorial" else "home"
        } else "auth",
        enterTransition = { fadeIn(animationSpec = tween(300)) },
        exitTransition = { fadeOut(animationSpec = tween(300)) }
    ) {
        composable("home") {
            HomeScreen(
                userProfile = uiState.userProfile,
                onNavigateToGame = { mode, level, side, difficulty, timer ->
                    viewModel.startNewGame(
                        mode = mode,
                        level = level,
                        side = side,
                        difficulty = difficulty,
                        timer = timer
                    )
                    navController.navigate("game")
                },
                onNavigateToPlayLive = { navController.navigate("play_live") },
                onNavigateToPlayFriend = { navController.navigate("play_friend") },
                onNavigateToChallenges = { navController.navigate("challenges") },
                onNavigateToTournaments = { navController.navigate("tournaments") },
                onNavigateToTutorial = { navController.navigate("tutorial") },
                onNavigateToRules = { navController.navigate("rules") },
                onNavigateToStats = { navController.navigate("stats") },
                onNavigateToLeaderboard = { navController.navigate("leaderboard") },
                onNavigateToSettings = { navController.navigate("settings") },
                onNavigateToAuth = { navController.navigate("auth") }
            )
        }

        composable("leaderboard") {
            LeaderboardScreen(
                players = uiState.leaderboardPlayers,
                userProfile = uiState.userProfile,
                currentFilter = uiState.leaderboardFilter,
                isLoading = uiState.isLeaderboardLoading,
                error = uiState.leaderboardError,
                isScoreSyncing = uiState.isScoreSyncing,
                syncSuccessMessage = uiState.scoreSyncSuccessMessage,
                searchQuery = uiState.leaderboardSearchQuery,
                onFilterChanged = { filter -> viewModel.setLeaderboardFilter(filter) },
                onSearchQueryChanged = { query -> viewModel.setLeaderboardSearchQuery(query) },
                onRefresh = { viewModel.loadLeaderboard() },
                onSyncScore = { viewModel.syncUserScoreToFirestore() },
                onDismissSyncMessage = { viewModel.dismissScoreSyncMessage() },
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable("play_live") {
            PlayLiveScreen(
                userProfile = uiState.userProfile,
                onStartLiveMatch = { level, timer, opponent, side ->
                    viewModel.startLiveGame(
                        level = level,
                        timer = timer,
                        opponent = opponent,
                        playerSide = side
                    )
                    navController.navigate("game")
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable("play_friend") {
            PlayFriendScreen(
                userProfile = uiState.userProfile,
                friends = uiState.friends,
                onAddFriend = { nameOrCode -> viewModel.addFriend(nameOrCode) },
                onRemoveFriend = { id -> viewModel.removeFriend(id) },
                onToggleFavoriteFriend = { id -> viewModel.toggleFavoriteFriend(id) },
                onStartFriendGame = { mode, level, timer, side, friendName, roomCode ->
                    viewModel.startFriendGame(
                        mode = mode,
                        level = level,
                        timer = timer,
                        playerSide = side,
                        friendName = friendName,
                        roomCode = roomCode
                    )
                    navController.navigate("game")
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable("auth") {
            AuthScreen(
                userProfile = uiState.userProfile,
                onLoginGoogle = { email, name ->
                    viewModel.loginWithGoogle(email, name)
                    val nextRoute = if (!prefs.isFirstLoginTutorialCompleted()) "tutorial" else "home"
                    navController.navigate(nextRoute) {
                        popUpTo("auth") { inclusive = true }
                    }
                },
                onLoginPhone = { phone, name ->
                    viewModel.loginWithPhone(phone, name)
                    val nextRoute = if (!prefs.isFirstLoginTutorialCompleted()) "tutorial" else "home"
                    navController.navigate(nextRoute) {
                        popUpTo("auth") { inclusive = true }
                    }
                },
                onLoginGuest = { guestName ->
                    viewModel.loginAsGuest(guestName)
                    val nextRoute = if (!prefs.isFirstLoginTutorialCompleted()) "tutorial" else "home"
                    navController.navigate(nextRoute) {
                        popUpTo("auth") { inclusive = true }
                    }
                },
                onUpdateProfile = { username, avatar ->
                    viewModel.updateProfile(username, avatar)
                },
                onUploadCustomAvatar = { uri ->
                    viewModel.saveCustomAvatarFromUri(uri)
                },
                onRemoveCustomAvatar = {
                    viewModel.removeCustomAvatar()
                },
                onLogout = {
                    viewModel.logout()
                    navController.navigate("auth") {
                        popUpTo(0) { inclusive = true }
                    }
                },
                onNavigateBack = {
                    if (!navController.popBackStack()) {
                        navController.navigate("home")
                    }
                }
            )
        }

        composable("game") {
            GameScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable("challenges") {
            ChallengesScreen(
                userProfile = uiState.userProfile,
                onSelectPuzzle = { puzzle ->
                    viewModel.startPuzzle(puzzle)
                    navController.navigate("game")
                },
                onNavigateBack = { navController.popBackStack() },
                prefs = prefs
            )
        }

        composable("tournaments") {
            TournamentsScreen(
                tournamentState = uiState.tournamentState,
                onStartTournament = {
                    viewModel.startTournament()
                    navController.navigate("game")
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable("tutorial") {
            TutorialScreen(
                onNavigateBack = {
                    if (!navController.popBackStack()) {
                        navController.navigate("home") {
                            popUpTo("tutorial") { inclusive = true }
                        }
                    }
                },
                onStartPracticeGame = {
                    viewModel.startNewGame(
                        mode = GameMode.TUTORIAL,
                        level = BoardLevel.PYRAMID,
                        side = PieceType.GOAT,
                        difficulty = AIDifficulty.EASY,
                        timer = GameTimer.RAPID
                    )
                    navController.navigate("game") {
                        popUpTo("tutorial") { inclusive = true }
                    }
                }
            )
        }

        composable("rules") {
            RulesScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable("stats") {
            StatsScreen(
                userProfile = uiState.userProfile,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToAuth = { navController.navigate("auth") },
                onNavigateToLeaderboard = { navController.navigate("leaderboard") }
            )
        }

        composable("settings") {
            SettingsScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToAuth = { navController.navigate("auth") },
                onLogout = {
                    viewModel.logout()
                    navController.navigate("auth") {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }
    }
}
