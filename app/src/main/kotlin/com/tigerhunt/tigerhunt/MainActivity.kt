package com.tigerhunt.tigerhunt

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.*
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.tigerhunt.tigerhunt.data.GamePreferences
import com.tigerhunt.tigerhunt.model.*
import com.tigerhunt.tigerhunt.ui.screens.*
import com.tigerhunt.tigerhunt.ui.theme.DarkBackground
import com.tigerhunt.tigerhunt.ui.theme.TigerHuntTheme
import com.tigerhunt.tigerhunt.viewmodel.GameViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TigerHuntTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = DarkBackground
                ) {
                    TigerHuntApp()
                }
            }
        }
    }
}

@Composable
fun TigerHuntApp(
    viewModel: GameViewModel = viewModel()
) {
    val navController = rememberNavController()
    val uiState by viewModel.uiState.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = androidx.compose.runtime.remember { GamePreferences(context) }

    NavHost(
        navController = navController,
        startDestination = "home",
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
                onNavigateToChallenges = { navController.navigate("challenges") },
                onNavigateToTournaments = { navController.navigate("tournaments") },
                onNavigateToTutorial = { navController.navigate("tutorial") },
                onNavigateToRules = { navController.navigate("rules") },
                onNavigateToStats = { navController.navigate("stats") },
                onNavigateToSettings = { navController.navigate("settings") }
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
                onNavigateBack = { navController.popBackStack() },
                onStartPracticeGame = {
                    viewModel.startNewGame(
                        mode = GameMode.TUTORIAL,
                        level = BoardLevel.PYRAMID,
                        side = PieceType.GOAT,
                        difficulty = AIDifficulty.EASY,
                        timer = GameTimer.UNLIMITED
                    )
                    navController.navigate("game")
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
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable("settings") {
            SettingsScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
