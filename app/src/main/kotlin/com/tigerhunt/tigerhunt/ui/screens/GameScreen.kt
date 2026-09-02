package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.model.*
import com.tigerhunt.tigerhunt.ui.components.*
import com.tigerhunt.tigerhunt.ui.theme.*
import com.tigerhunt.tigerhunt.viewmodel.GameViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GameScreen(
    viewModel: GameViewModel,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()
    var showThemeDialog by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = when (uiState.gameMode) {
                                GameMode.VS_AI -> "vs AI (${uiState.aiDifficulty.displayName})"
                                GameMode.PASS_AND_PLAY -> "Pass & Play (Local)"
                                GameMode.PUZZLES -> uiState.currentPuzzle?.title ?: "Puzzle Challenge"
                                GameMode.TOURNAMENT -> "Tournament: ${uiState.tournamentState?.currentStage?.displayName}"
                                GameMode.TUTORIAL -> "Tutorial Practice"
                            },
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = "${uiState.boardLevel.displayName} Board • ${if (uiState.gameState.phase == GamePhase.PLACEMENT) "Goat Placement Phase" else "Movement Phase"}",
                            fontSize = 12.sp,
                            color = HighlightGold
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack, modifier = Modifier.testTag("game_back_button")) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                actions = {
                    IconButton(onClick = { showThemeDialog = true }) {
                        Icon(Icons.Default.Palette, contentDescription = "Board Theme", tint = Color.White)
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
                .padding(bottom = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // PLAYER & CAPTURE STATS
            PlayerInfoBar(
                gameState = uiState.gameState,
                isTigerPlayer = uiState.playerSide == PieceType.TIGER,
                isAiThinking = uiState.isAiThinking
            )

            // STATUS NOTIFICATION / HINT BAR
            uiState.alertMessage?.let { msg ->
                Surface(
                    color = DarkSurfaceVariant,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = msg,
                            fontSize = 12.sp,
                            color = HighlightGold,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier.weight(1f)
                        )
                        TextButton(onClick = { viewModel.dismissAlert() }) {
                            Text("OK", fontSize = 11.sp, color = AmberTiger)
                        }
                    }
                }
            }

            // BOARD CANVAS
            Box(
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                GameBoardCanvas(
                    gameState = uiState.gameState,
                    boardTheme = uiState.currentTheme,
                    selectedPosition = uiState.selectedPosition,
                    validMoves = uiState.validMovesForSelection,
                    hintMove = uiState.hintMove,
                    onNodeClick = { pos -> viewModel.onNodeClicked(pos) }
                )
            }

            // CONTROLS BAR
            GameControls(
                onUndoClick = { viewModel.undoMove() },
                onHintClick = { viewModel.requestHint() },
                onRestartClick = {
                    if (uiState.gameMode == GameMode.PUZZLES && uiState.currentPuzzle != null) {
                        viewModel.startPuzzle(uiState.currentPuzzle!!)
                    } else {
                        viewModel.startNewGame()
                    }
                },
                onSettingsClick = { showThemeDialog = true },
                isSoundEnabled = uiState.soundEnabled,
                onSoundToggle = { viewModel.toggleSound() },
                canUndo = uiState.gameState.moveHistory.isNotEmpty() && !uiState.gameState.isGameOver
            )
        }
    }

    if (uiState.isGameEndDialogVisible) {
        GameEndDialog(
            winner = uiState.gameState.winner,
            drawReason = uiState.gameState.drawReason,
            onRematchClick = {
                viewModel.dismissEndDialog()
                if (uiState.gameMode == GameMode.PUZZLES && uiState.currentPuzzle != null) {
                    viewModel.startPuzzle(uiState.currentPuzzle!!)
                } else {
                    viewModel.startNewGame()
                }
            },
            onHomeClick = {
                viewModel.dismissEndDialog()
                onNavigateBack()
            },
            onDismiss = { viewModel.dismissEndDialog() },
            isPuzzle = uiState.gameMode == GameMode.PUZZLES,
            puzzleTitle = uiState.currentPuzzle?.title
        )
    }

    if (showThemeDialog) {
        AlertDialog(
            onDismissRequest = { showThemeDialog = false },
            containerColor = DarkSurface,
            title = { Text("Select Board Theme", color = Color.White, fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    BoardTheme.values().forEach { theme ->
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (uiState.currentTheme == theme) DarkSurfaceVariant else Color.Transparent,
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("theme_${theme.name.lowercase()}")
                        ) {
                            TextButton(
                                onClick = {
                                    viewModel.setTheme(theme)
                                    showThemeDialog = false
                                },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = theme.displayName,
                                            fontWeight = FontWeight.Bold,
                                            color = if (uiState.currentTheme == theme) HighlightGold else Color.White
                                        )
                                        Text(
                                            text = theme.description,
                                            fontSize = 11.sp,
                                            color = GoatIvoryDark
                                        )
                                    }
                                    if (uiState.currentTheme == theme) {
                                        Text("✓", color = HighlightGold, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showThemeDialog = false }) {
                    Text("Done", color = AmberTiger)
                }
            }
        )
    }
}
