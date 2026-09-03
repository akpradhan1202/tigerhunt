package com.tigerhunt.tigerhunt.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
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
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tigerhunt.tigerhunt.data.GamePreferences
import com.tigerhunt.tigerhunt.engine.AudioService
import com.tigerhunt.tigerhunt.engine.GameEngine
import com.tigerhunt.tigerhunt.model.*
import com.tigerhunt.tigerhunt.ui.components.GameBoardCanvas
import com.tigerhunt.tigerhunt.ui.theme.*

data class InteractiveTutorialStep(
    val stepIndex: Int,
    val title: String,
    val icon: String,
    val headline: String,
    val roleBadge: String,
    val roleBadgeColor: Color,
    val instruction: String,
    val targetGoal: String,
    val createInitialState: () -> GameState,
    val hintFrom: Position?,
    val hintTo: Position,
    val successExplanation: String,
    val keyTakeaway: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TutorialScreen(
    onNavigateBack: () -> Unit,
    onStartPracticeGame: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val prefs = remember { GamePreferences(context) }
    val audio = remember { AudioService(context) }
    val gameEngine = remember { GameEngine(BoardLevel.PYRAMID) }

    val steps = remember {
        listOf(
            // STEP 0: Introduction & Overview
            InteractiveTutorialStep(
                stepIndex = 0,
                title = "Lesson 1: Introduction to Bagh-Chal",
                icon = "🏔️",
                headline = "The Himalayan Royal Strategy",
                roleBadge = "OVERVIEW",
                roleBadgeColor = HighlightGold,
                instruction = "Bagh-Chal ('Moving Tigers') is an ancient asymmetric strategy game from Nepal. One player commands 3 to 5 Tigers, while the other commands a herd of 15 to 20 Goats.",
                targetGoal = "Tap 'Start Interactive Training' below to begin learning piece movements step-by-step!",
                createInitialState = {
                    GameState(
                        level = BoardLevel.PYRAMID,
                        pieces = listOf(
                            Piece(PieceType.TIGER, Position(0, 2), "t0"),
                            Piece(PieceType.TIGER, Position(4, 0), "t1"),
                            Piece(PieceType.TIGER, Position(4, 4), "t2"),
                            Piece(PieceType.GOAT, Position(2, 2), "g0"),
                            Piece(PieceType.GOAT, Position(3, 1), "g1"),
                            Piece(PieceType.GOAT, Position(3, 3), "g2")
                        ),
                        currentTurn = PlayerTurn.GOAT,
                        phase = GamePhase.MOVEMENT
                    )
                },
                hintFrom = null,
                hintTo = Position(2, 2),
                successExplanation = "Tigers aim to capture 5 Goats. Goats aim to surround and trap all Tigers so they have no legal moves.",
                keyTakeaway = "Asymmetric Gameplay: Tigers are agile hunters with lethal leap captures, while Goats rely on teamwork and spatial traps."
            ),

            // STEP 1: Goat Placement Phase
            InteractiveTutorialStep(
                stepIndex = 1,
                title = "Lesson 2: Goat Placement Phase",
                icon = "🐐",
                headline = "Drop Goats One-by-One",
                roleBadge = "GOAT PHASE 1",
                roleBadgeColor = ValidGreen,
                instruction = "The game always begins with Tigers stationed at the board corners. The Goats move first! In Phase 1, Goats are placed one at a time onto any empty intersection.",
                targetGoal = "👉 Tap the glowing center node at (2, 2) to deploy your first Goat!",
                createInitialState = {
                    GameState(
                        level = BoardLevel.PYRAMID,
                        pieces = listOf(
                            Piece(PieceType.TIGER, Position(0, 2), "t0"),
                            Piece(PieceType.TIGER, Position(4, 0), "t1"),
                            Piece(PieceType.TIGER, Position(4, 4), "t2")
                        ),
                        currentTurn = PlayerTurn.GOAT,
                        phase = GamePhase.PLACEMENT,
                        goatsPlaced = 0
                    )
                },
                hintFrom = null,
                hintTo = Position(2, 2),
                successExplanation = "🎯 Goat Placed! In this initial phase, Goats CANNOT move across lines yet. All goats must be placed on the board before any goat can slide.",
                keyTakeaway = "Place Goats strategically to control central lines and restrict open tiger leaping corridors."
            ),

            // STEP 2: Tiger Standard Movement
            InteractiveTutorialStep(
                stepIndex = 2,
                title = "Lesson 3: Tiger Step Movement",
                icon = "🐅",
                headline = "Step Along Connected Lines",
                roleBadge = "TIGER MOVEMENT",
                roleBadgeColor = AmberTiger,
                instruction = "Tigers can move one step along any connected line to an adjacent empty intersection. Tigers cannot step over or onto other friendly tigers.",
                targetGoal = "👉 Tap the Tiger at (0, 2), then tap the adjacent empty node (1, 1) or (1, 3) to move it!",
                createInitialState = {
                    GameState(
                        level = BoardLevel.PYRAMID,
                        pieces = listOf(
                            Piece(PieceType.TIGER, Position(0, 2), "t0"),
                            Piece(PieceType.TIGER, Position(4, 0), "t1"),
                            Piece(PieceType.TIGER, Position(4, 4), "t2"),
                            Piece(PieceType.GOAT, Position(3, 2), "g0"),
                            Piece(PieceType.GOAT, Position(4, 2), "g1")
                        ),
                        currentTurn = PlayerTurn.TIGER,
                        phase = GamePhase.MOVEMENT
                    )
                },
                hintFrom = Position(0, 2),
                hintTo = Position(1, 1),
                successExplanation = "🐅 Tiger Stepped! Tigers can freely stalk along lines into any unoccupied adjacent intersection.",
                keyTakeaway = "Tigers have high mobility. They must position themselves adjacent to solitary goats to set up jumps."
            ),

            // STEP 3: Tiger Capture Leap Mechanics
            InteractiveTutorialStep(
                stepIndex = 3,
                title = "Lesson 4: Tiger Capture & Leap",
                icon = "💥",
                headline = "Pounce Over Solitary Goats",
                roleBadge = "TIGER CAPTURE",
                roleBadgeColor = Color(0xFFFF5252),
                instruction = "If an adjacent intersection has a Goat and the intersection immediately beyond it along the same straight line is EMPTY, the Tiger can leap over the Goat and capture it!",
                targetGoal = "👉 Tap the Tiger at (2, 0), then tap the pulsing red capture landing node at (2, 2) to leap over the Goat at (2, 1)!",
                createInitialState = {
                    GameState(
                        level = BoardLevel.PYRAMID,
                        pieces = listOf(
                            Piece(PieceType.TIGER, Position(2, 0), "t0"),
                            Piece(PieceType.GOAT, Position(2, 1), "g0"), // Goat to be leaped
                            Piece(PieceType.TIGER, Position(4, 4), "t1")
                        ),
                        currentTurn = PlayerTurn.TIGER,
                        phase = GamePhase.MOVEMENT
                    )
                },
                hintFrom = Position(2, 0),
                hintTo = Position(2, 2),
                successExplanation = "💥 Capture Successful! The Tiger leaped over the Goat and permanently eliminated it. Tigers win when they capture 5 Goats!",
                keyTakeaway = "Tigers cannot leap over two goats in a row or jump into an occupied space. Goats are safe if placed in pairs!"
            ),

            // STEP 4: Goat Phase 2 Movement
            InteractiveTutorialStep(
                stepIndex = 4,
                title = "Lesson 5: Goat Movement Phase",
                icon = "🛡️",
                headline = "Mobilize the Herd",
                roleBadge = "GOAT PHASE 2",
                roleBadgeColor = ValidGreen,
                instruction = "Once all Goats are deployed onto the board, the game enters Phase 2. Surviving Goats can now slide one step along connected lines to adjacent empty nodes. Goats cannot jump or capture.",
                targetGoal = "👉 Tap the Goat at (2, 2) and move it to the adjacent empty node at (2, 3) to reinforce your herd!",
                createInitialState = {
                    GameState(
                        level = BoardLevel.PYRAMID,
                        pieces = listOf(
                            Piece(PieceType.TIGER, Position(0, 2), "t0"),
                            Piece(PieceType.TIGER, Position(4, 0), "t1"),
                            Piece(PieceType.GOAT, Position(2, 2), "g0"),
                            Piece(PieceType.GOAT, Position(3, 1), "g1"),
                            Piece(PieceType.GOAT, Position(3, 2), "g2"),
                            Piece(PieceType.GOAT, Position(3, 3), "g3"),
                            Piece(PieceType.GOAT, Position(4, 2), "g4")
                        ),
                        currentTurn = PlayerTurn.GOAT,
                        phase = GamePhase.MOVEMENT,
                        goatsPlaced = 15
                    )
                },
                hintFrom = Position(2, 2),
                hintTo = Position(2, 3),
                successExplanation = "🛡️ Herd Shifted! Goats slide along lines to form tight interlocking clusters so Tigers have no landing space to jump.",
                keyTakeaway = "Always move Goats into formations where another Goat stands right behind it, preventing any Tiger jump."
            ),

            // STEP 5: Trapping Tigers (Goat Victory)
            InteractiveTutorialStep(
                stepIndex = 5,
                title = "Lesson 6: Trapping Tigers & Victory",
                icon = "👑",
                headline = "Immobilize All Tigers",
                roleBadge = "GOAT VICTORY",
                roleBadgeColor = HighlightGold,
                instruction = "Goats win the match when ALL Tigers on the board are completely surrounded and have ZERO legal moves left (neither a normal step nor a capture leap).",
                targetGoal = "👉 The Tiger at apex (0, 2) is nearly trapped! Move your Goat from (2, 2) to (1, 1) to seal its final escape route!",
                createInitialState = {
                    GameState(
                        level = BoardLevel.PYRAMID,
                        pieces = listOf(
                            Piece(PieceType.TIGER, Position(0, 2), "t0"), // Tiger to trap
                            Piece(PieceType.GOAT, Position(1, 3), "g0"), // Blocks right step & jump
                            Piece(PieceType.GOAT, Position(2, 4), "g1"), // Blocks landing
                            Piece(PieceType.GOAT, Position(2, 0), "g2"), // Blocks left landing
                            Piece(PieceType.GOAT, Position(2, 2), "g3")  // Goat to move into (1,1)
                        ),
                        currentTurn = PlayerTurn.GOAT,
                        phase = GamePhase.MOVEMENT,
                        goatsPlaced = 15
                    )
                },
                hintFrom = Position(2, 2),
                hintTo = Position(1, 1),
                successExplanation = "👑 Tiger Trapped! The apex Tiger now has zero legal moves remaining. When every Tiger is trapped this way, the Goats immediately win!",
                keyTakeaway = "Patience and coordinated spacing allow Goats to cage in tigers corner by corner."
            ),

            // STEP 6: Graduation & Practice Match
            InteractiveTutorialStep(
                stepIndex = 6,
                title = "Graduation: Himalayan Grandmaster",
                icon = "🎓",
                headline = "You Are Ready to Play!",
                roleBadge = "MASTERED",
                roleBadgeColor = ValidGreen,
                instruction = "Congratulations! You have mastered both the Tiger and Goat movement and capture rules. Here is a quick summary before your practice match:",
                targetGoal = "Ready to test your skills? Launch a practice match or explore the game modes in the main menu.",
                createInitialState = {
                    GameState(
                        level = BoardLevel.PYRAMID,
                        pieces = listOf(
                            Piece(PieceType.TIGER, Position(0, 2), "t0"),
                            Piece(PieceType.TIGER, Position(4, 0), "t1"),
                            Piece(PieceType.TIGER, Position(4, 4), "t2"),
                            Piece(PieceType.GOAT, Position(2, 2), "g0"),
                            Piece(PieceType.GOAT, Position(3, 2), "g1")
                        ),
                        currentTurn = PlayerTurn.GOAT,
                        phase = GamePhase.PLACEMENT
                    )
                },
                hintFrom = null,
                hintTo = Position(2, 2),
                successExplanation = "You have completed the official Bagh-Chal interactive training course.",
                keyTakeaway = "Goats: Drop 20 -> Move along lines -> Trap all Tigers. Tigers: Step 1 node -> Leap over Goats to capture 5 Goats."
            )
        )
    }

    var currentStepIndex by remember { mutableStateOf(0) }
    val currentStep = steps[currentStepIndex]

    // Step interactive state
    var currentGameState by remember(currentStepIndex) { mutableStateOf(currentStep.createInitialState()) }
    var selectedPosition by remember(currentStepIndex) { mutableStateOf<Position?>(null) }
    var isStepCompleted by remember(currentStepIndex) { mutableStateOf(currentStepIndex == 0 || currentStepIndex == steps.size - 1) }
    var stepFeedbackText by remember(currentStepIndex) { mutableStateOf<String?>(null) }

    fun markCompletedAndExit(action: () -> Unit) {
        prefs.setFirstLoginTutorialCompleted(true)
        action()
    }

    fun resetCurrentStep() {
        currentGameState = currentStep.createInitialState()
        selectedPosition = null
        isStepCompleted = currentStepIndex == 0 || currentStepIndex == steps.size - 1
        stepFeedbackText = null
        audio.playSound("button_tap")
    }

    fun handleInteractiveNodeClick(clickedPos: Position) {
        if (isStepCompleted && currentStepIndex != 0) return

        val state = currentGameState
        val currentTurn = state.currentTurn

        when (currentStepIndex) {
            0 -> {
                // Intro step - just click next
            }
            1 -> {
                // Step 1: Goat Placement Phase
                if (state.phase == GamePhase.PLACEMENT && state.isPositionEmpty(clickedPos)) {
                    val newPiece = Piece(PieceType.GOAT, clickedPos, "user_goat_${System.currentTimeMillis()}")
                    currentGameState = state.copy(
                        pieces = state.pieces + newPiece,
                        goatsPlaced = state.goatsPlaced + 1
                    )
                    selectedPosition = null
                    isStepCompleted = true
                    stepFeedbackText = currentStep.successExplanation
                    audio.playSound("goat_move")
                    audio.vibrate(40)
                } else {
                    audio.playSound("button_tap")
                }
            }
            2 -> {
                // Step 2: Tiger Step Movement
                if (selectedPosition == null) {
                    val piece = state.getPieceAt(clickedPos)
                    if (piece != null && piece.type == PieceType.TIGER) {
                        selectedPosition = clickedPos
                        audio.playSound("select")
                        audio.vibrate(20)
                    }
                } else {
                    val from = selectedPosition!!
                    val connections = BoardConnections(state.level)
                    if (connections.areConnected(from, clickedPos) && state.isPositionEmpty(clickedPos)) {
                        // Move Tiger
                        val updatedPieces = state.pieces.map {
                            if (it.position == from) it.copy(position = clickedPos) else it
                        }
                        currentGameState = state.copy(pieces = updatedPieces)
                        selectedPosition = null
                        isStepCompleted = true
                        stepFeedbackText = currentStep.successExplanation
                        audio.playSound("tiger_move")
                        audio.vibrate(40)
                    } else if (state.getPieceAt(clickedPos)?.type == PieceType.TIGER) {
                        selectedPosition = clickedPos
                        audio.playSound("select")
                    } else {
                        selectedPosition = null
                    }
                }
            }
            3 -> {
                // Step 3: Tiger Capture Leap
                if (selectedPosition == null) {
                    val piece = state.getPieceAt(clickedPos)
                    if (piece != null && piece.type == PieceType.TIGER) {
                        selectedPosition = clickedPos
                        audio.playSound("select")
                        audio.vibrate(20)
                    }
                } else {
                    val from = selectedPosition!!
                    val connections = BoardConnections(state.level)
                    val goatAtMid = state.getPieceAt(Position(2, 1))
                    // Check if leap over (2,1) into (2,2)
                    if (from == Position(2, 0) && clickedPos == Position(2, 2) && goatAtMid != null) {
                        val updatedPieces = state.pieces.filter { it.position != Position(2, 1) }.map {
                            if (it.position == from) it.copy(position = clickedPos) else it
                        }
                        currentGameState = state.copy(
                            pieces = updatedPieces,
                            goatsCaptured = state.goatsCaptured + 1
                        )
                        selectedPosition = null
                        isStepCompleted = true
                        stepFeedbackText = currentStep.successExplanation
                        audio.playSound("tiger_capture")
                        audio.vibrate(70)
                    } else if (state.getPieceAt(clickedPos)?.type == PieceType.TIGER) {
                        selectedPosition = clickedPos
                    } else {
                        selectedPosition = null
                    }
                }
            }
            4 -> {
                // Step 4: Goat Movement Phase
                if (selectedPosition == null) {
                    val piece = state.getPieceAt(clickedPos)
                    if (piece != null && piece.type == PieceType.GOAT && clickedPos == Position(2, 2)) {
                        selectedPosition = clickedPos
                        audio.playSound("select")
                        audio.vibrate(20)
                    }
                } else {
                    val from = selectedPosition!!
                    val connections = BoardConnections(state.level)
                    if (connections.areConnected(from, clickedPos) && state.isPositionEmpty(clickedPos)) {
                        val updatedPieces = state.pieces.map {
                            if (it.position == from) it.copy(position = clickedPos) else it
                        }
                        currentGameState = state.copy(pieces = updatedPieces)
                        selectedPosition = null
                        isStepCompleted = true
                        stepFeedbackText = currentStep.successExplanation
                        audio.playSound("goat_move")
                        audio.vibrate(40)
                    } else if (state.getPieceAt(clickedPos)?.type == PieceType.GOAT) {
                        selectedPosition = clickedPos
                    } else {
                        selectedPosition = null
                    }
                }
            }
            5 -> {
                // Step 5: Trapping Tigers
                if (selectedPosition == null) {
                    val piece = state.getPieceAt(clickedPos)
                    if (piece != null && piece.type == PieceType.GOAT && clickedPos == Position(2, 2)) {
                        selectedPosition = clickedPos
                        audio.playSound("select")
                        audio.vibrate(20)
                    }
                } else {
                    val from = selectedPosition!!
                    if (clickedPos == Position(1, 1)) {
                        val updatedPieces = state.pieces.map {
                            if (it.position == from) it.copy(position = clickedPos) else it
                        }
                        currentGameState = state.copy(pieces = updatedPieces)
                        selectedPosition = null
                        isStepCompleted = true
                        stepFeedbackText = currentStep.successExplanation
                        audio.playSound("game_win")
                        audio.vibrate(60)
                    } else if (state.getPieceAt(clickedPos)?.type == PieceType.GOAT) {
                        selectedPosition = clickedPos
                    } else {
                        selectedPosition = null
                    }
                }
            }
        }
    }

    // Compute dynamic valid moves to render on board for active step
    val computedValidMoves = remember(currentGameState, selectedPosition, isStepCompleted) {
        if (isStepCompleted) emptyList()
        else when (currentStepIndex) {
            1 -> listOf(Move(Position(-1, -1), Position(2, 2), pieceType = PieceType.GOAT))
            2 -> if (selectedPosition == Position(0, 2)) listOf(
                Move(Position(0, 2), Position(1, 1), pieceType = PieceType.TIGER),
                Move(Position(0, 2), Position(1, 3), pieceType = PieceType.TIGER)
            ) else emptyList()
            3 -> if (selectedPosition == Position(2, 0)) listOf(
                Move(Position(2, 0), Position(2, 2), capturedAt = Position(2, 1), pieceType = PieceType.TIGER)
            ) else emptyList()
            4 -> if (selectedPosition == Position(2, 2)) listOf(
                Move(Position(2, 2), Position(2, 3), pieceType = PieceType.GOAT),
                Move(Position(2, 2), Position(2, 1), pieceType = PieceType.GOAT)
            ) else emptyList()
            5 -> if (selectedPosition == Position(2, 2)) listOf(
                Move(Position(2, 2), Position(1, 1), pieceType = PieceType.GOAT)
            ) else emptyList()
            else -> emptyList()
        }
    }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(currentStep.icon, fontSize = 20.sp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Interactive Tutorial",
                            fontWeight = FontWeight.Bold,
                            color = HighlightGold,
                            fontSize = 17.sp
                        )
                    }
                },
                navigationIcon = {
                    IconButton(
                        onClick = { markCompletedAndExit(onNavigateBack) },
                        modifier = Modifier.testTag("tutorial_back_button")
                    ) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                actions = {
                    TextButton(
                        onClick = { markCompletedAndExit(onNavigateBack) },
                        modifier = Modifier.testTag("tutorial_skip_button")
                    ) {
                        Text(
                            text = "Skip Tutorial",
                            color = GoatIvoryDark,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
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
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // STEP PROGRESS INDICATOR
            Column(modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "STEP ${currentStepIndex + 1} OF ${steps.size}",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = HighlightGold,
                        letterSpacing = 1.sp
                    )
                    Text(
                        text = "${((currentStepIndex + 1) * 100) / steps.size}% Completed",
                        fontSize = 11.sp,
                        color = GoatIvoryDark
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    steps.indices.forEach { index ->
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(6.dp)
                                .clip(RoundedCornerShape(3.dp))
                                .background(
                                    when {
                                        index < currentStepIndex -> ValidGreen
                                        index == currentStepIndex -> HighlightGold
                                        else -> DarkSurfaceVariant
                                    }
                                )
                        )
                    }
                }
            }

            // LESSON HEADER CARD
            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BoardWoodLight.copy(alpha = 0.5f), RoundedCornerShape(20.dp))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = currentStep.title,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = AmberTiger
                        )

                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = currentStep.roleBadgeColor.copy(alpha = 0.2f)
                        ) {
                            Text(
                                text = currentStep.roleBadge,
                                fontSize = 9.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = currentStep.roleBadgeColor,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(4.dp))

                    Text(
                        text = currentStep.headline,
                        fontSize = 19.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.White
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = currentStep.instruction,
                        fontSize = 13.sp,
                        color = GoatIvory,
                        lineHeight = 18.sp
                    )
                }
            }

            // INTERACTIVE GOAL / TASK BANNER
            Surface(
                shape = RoundedCornerShape(14.dp),
                color = if (isStepCompleted) ValidGreen.copy(alpha = 0.15f) else AmberTiger.copy(alpha = 0.15f),
                border = BorderStroke(1.2.dp, if (isStepCompleted) ValidGreen else HighlightGold),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("tutorial_task_banner")
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = if (isStepCompleted) "✅" else "🎯",
                        fontSize = 20.sp
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = if (isStepCompleted) "STEP COMPLETE!" else "INTERACTIVE TASK",
                            fontSize = 10.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color = if (isStepCompleted) ValidGreen else HighlightGold,
                            letterSpacing = 1.sp
                        )
                        Text(
                            text = if (isStepCompleted) (stepFeedbackText ?: currentStep.successExplanation) else currentStep.targetGoal,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = Color.White
                        )
                    }

                    if (!isStepCompleted && currentStepIndex in 1..5) {
                        IconButton(
                            onClick = { resetCurrentStep() },
                            modifier = Modifier.size(28.dp).testTag("tutorial_reset_step_button")
                        ) {
                            Icon(Icons.Default.Refresh, contentDescription = "Reset Step", tint = GoatIvoryDark, modifier = Modifier.size(18.dp))
                        }
                    }
                }
            }

            // LIVE INTERACTIVE BOARD CANVAS
            if (currentStepIndex in 1..5) {
                Card(
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    border = BorderStroke(1.dp, BoardWoodLight),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 4.dp)
                        .testTag("interactive_tutorial_board_card")
                ) {
                    Column(
                        modifier = Modifier.padding(12.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("🎮", fontSize = 14.sp)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "Practice on Live Board",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White
                                )
                            }

                            Text(
                                text = if (isStepCompleted) "Goal Achieved 🎉" else "Tap pieces/nodes to move",
                                fontSize = 10.sp,
                                color = if (isStepCompleted) ValidGreen else AmberTigerLight
                            )
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        GameBoardCanvas(
                            gameState = currentGameState,
                            boardTheme = BoardTheme.CLASSIC_NEPAL,
                            selectedPosition = selectedPosition,
                            validMoves = computedValidMoves,
                            hintMove = if (!isStepCompleted) Move(
                                from = currentStep.hintFrom ?: Position(-1, -1),
                                to = currentStep.hintTo,
                                pieceType = if (currentStep.hintFrom == null) PieceType.GOAT else PieceType.TIGER
                            ) else null,
                            onNodeClick = { clickedPos -> handleInteractiveNodeClick(clickedPos) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .aspectRatio(1f)
                        )
                    }
                }
            } else if (currentStepIndex == 6) {
                // STEP 6: SUMMARY RECAP MATRIX
                Card(
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    border = BorderStroke(1.dp, HighlightGold.copy(alpha = 0.5f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "RULE RECAP AT A GLANCE",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = HighlightGold,
                            letterSpacing = 1.sp
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        // Goat Summary Box
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = DarkSurfaceVariant,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(modifier = Modifier.padding(12.dp)) {
                                Text("🐐", fontSize = 24.sp)
                                Spacer(modifier = Modifier.width(10.dp))
                                Column {
                                    Text("Goats (Herd Defense)", fontWeight = FontWeight.Bold, color = ValidGreen, fontSize = 13.sp)
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text("• Phase 1: Deploy all 15-20 goats one-by-one.\n• Phase 2: Slide 1 step along lines (cannot jump).\n• Victory: Trap all tigers with 0 legal moves.", fontSize = 11.sp, color = GoatIvory, lineHeight = 16.sp)
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        // Tiger Summary Box
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = DarkSurfaceVariant,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(modifier = Modifier.padding(12.dp)) {
                                Text("🐅", fontSize = 24.sp)
                                Spacer(modifier = Modifier.width(10.dp))
                                Column {
                                    Text("Tigers (Hunters)", fontWeight = FontWeight.Bold, color = AmberTiger, fontSize = 13.sp)
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text("• Starts stationed at corners.\n• Move: Step 1 node along lines.\n• Capture: Leap over adjacent solitary goats.\n• Victory: Capture 5 goats.", fontSize = 11.sp, color = GoatIvory, lineHeight = 16.sp)
                                }
                            }
                        }
                    }
                }
            }

            // KEY STRATEGY TAKEAWAY CARD
            Surface(
                shape = RoundedCornerShape(14.dp),
                color = DarkSurfaceVariant,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("💡", fontSize = 20.sp)
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text("PRO TIP", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = HighlightGold, letterSpacing = 1.sp)
                        Text(
                            text = currentStep.keyTakeaway,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = GoatIvory
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // BOTTOM NAVIGATION CONTROLS
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (currentStepIndex > 0) {
                    OutlinedButton(
                        onClick = {
                            currentStepIndex--
                            audio.playSound("button_tap")
                        },
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.testTag("tutorial_prev_button")
                    ) {
                        Icon(Icons.Default.ArrowBack, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Previous")
                    }
                } else {
                    Spacer(modifier = Modifier.width(1.dp))
                }

                if (currentStepIndex < steps.size - 1) {
                    Button(
                        onClick = {
                            currentStepIndex++
                            audio.playSound("select")
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = if (isStepCompleted) AmberTiger else DarkSurfaceVariant),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.testTag("tutorial_next_button")
                    ) {
                        Text(
                            text = if (currentStepIndex == 0) "Start Lesson →" else "Next Lesson",
                            color = if (isStepCompleted) Color.Black else GoatIvoryDark,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Icon(
                            Icons.Default.ArrowForward,
                            contentDescription = null,
                            tint = if (isStepCompleted) Color.Black else GoatIvoryDark,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                } else {
                    Button(
                        onClick = {
                            markCompletedAndExit(onStartPracticeGame)
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = ValidGreen),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.testTag("tutorial_play_button")
                    ) {
                        Text("Play Practice Game", color = Color.Black, fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.width(6.dp))
                        Icon(Icons.Default.Check, contentDescription = null, tint = Color.Black)
                    }
                }
            }
        }
    }
}
