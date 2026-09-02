package com.tigerhunt.tigerhunt.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.tigerhunt.tigerhunt.data.GamePreferences
import com.tigerhunt.tigerhunt.engine.AIEngine
import com.tigerhunt.tigerhunt.engine.AudioService
import com.tigerhunt.tigerhunt.engine.GameEngine
import com.tigerhunt.tigerhunt.model.*
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.math.abs

data class GameUiState(
    val gameState: GameState,
    val gameMode: GameMode = GameMode.VS_AI,
    val boardLevel: BoardLevel = BoardLevel.TRADITIONAL,
    val playerSide: PieceType = PieceType.GOAT,
    val aiDifficulty: AIDifficulty = AIDifficulty.MEDIUM,
    val selectedPosition: Position? = null,
    val validMovesForSelection: List<Move> = emptyList(),
    val currentTheme: BoardTheme = BoardTheme.CLASSIC_NEPAL,
    val userProfile: UserProfile = UserProfile(),
    val timer: GameTimer = GameTimer.UNLIMITED,
    val powerUpsEnabled: Boolean = false,
    val soundEnabled: Boolean = true,
    val hapticsEnabled: Boolean = true,
    val isAiThinking: Boolean = false,
    val hintMove: Move? = null,
    val currentPuzzle: Puzzle? = null,
    val puzzleMoveIndex: Int = 0,
    val puzzleSuccess: Boolean = false,
    val tournamentState: TournamentState? = null,
    val tutorialStepIndex: Int = 0,
    val suddenDeathCountDown: Int = 0,
    val isGameEndDialogVisible: Boolean = false,
    val alertMessage: String? = null
)

class GameViewModel(application: Application) : AndroidViewModel(application) {
    private val prefs = GamePreferences(application)
    val audio = AudioService(application)

    private var gameEngine: GameEngine = GameEngine(BoardLevel.TRADITIONAL)
    private var aiEngine: AIEngine = AIEngine(gameEngine, AIDifficulty.MEDIUM)
    private var timerJob: Job? = null

    private val _uiState = MutableStateFlow(
        GameUiState(
            gameState = GameState.initial(BoardLevel.TRADITIONAL),
            currentTheme = prefs.getSelectedTheme(),
            userProfile = prefs.getUserProfile(),
            soundEnabled = prefs.isSoundEnabled(),
            hapticsEnabled = prefs.isHapticsEnabled(),
            powerUpsEnabled = prefs.isPowerUpsEnabled(),
            aiDifficulty = prefs.getDefaultDifficulty()
        )
    )
    val uiState: StateFlow<GameUiState> = _uiState.asStateFlow()

    init {
        audio.isSoundEnabled = prefs.isSoundEnabled()
        audio.isHapticsEnabled = prefs.isHapticsEnabled()
    }

    fun startNewGame(
        mode: GameMode = _uiState.value.gameMode,
        level: BoardLevel = _uiState.value.boardLevel,
        side: PieceType = _uiState.value.playerSide,
        difficulty: AIDifficulty = _uiState.value.aiDifficulty,
        timer: GameTimer = _uiState.value.timer,
        powerUps: Boolean = _uiState.value.powerUpsEnabled
    ) {
        timerJob?.cancel()
        gameEngine = GameEngine(level)
        aiEngine = AIEngine(gameEngine, difficulty)

        val initialState = GameState.initial(level, timer)
        _uiState.value = _uiState.value.copy(
            gameState = initialState,
            gameMode = mode,
            boardLevel = level,
            playerSide = side,
            aiDifficulty = difficulty,
            timer = timer,
            powerUpsEnabled = powerUps,
            selectedPosition = null,
            validMovesForSelection = emptyList(),
            hintMove = null,
            isAiThinking = false,
            isGameEndDialogVisible = false,
            puzzleSuccess = false,
            currentPuzzle = null,
            alertMessage = null
        )

        audio.playSound("game_start")
        startTimerLoop()

        if (mode == GameMode.VS_AI && side == PieceType.TIGER && initialState.currentTurn == PlayerTurn.GOAT) {
            triggerAiTurn()
        }
    }

    fun startPuzzle(puzzle: Puzzle) {
        timerJob?.cancel()
        gameEngine = GameEngine(puzzle.position.level)
        aiEngine = AIEngine(gameEngine, AIDifficulty.MEDIUM)

        _uiState.value = _uiState.value.copy(
            gameState = puzzle.position,
            gameMode = GameMode.PUZZLES,
            boardLevel = puzzle.position.level,
            playerSide = puzzle.playerRole,
            currentPuzzle = puzzle,
            puzzleMoveIndex = 0,
            puzzleSuccess = false,
            selectedPosition = null,
            validMovesForSelection = emptyList(),
            hintMove = null,
            isGameEndDialogVisible = false,
            alertMessage = null
        )
        audio.playSound("game_start")
    }

    fun startTournament() {
        val user = _uiState.value.userProfile
        val tournament = TournamentState.createDefault(user.username)
        _uiState.value = _uiState.value.copy(tournamentState = tournament)
        startTournamentMatch()
    }

    private fun startTournamentMatch() {
        val tournament = _uiState.value.tournamentState ?: return
        val currentMatch = tournament.matches.firstOrNull {
            it.stage == tournament.currentStage && it.winner == null && (it.player1.isUser || it.player2.isUser)
        } ?: return

        val opponent = if (currentMatch.player1.isUser) currentMatch.player2 else currentMatch.player1
        startNewGame(
            mode = GameMode.TOURNAMENT,
            level = currentMatch.boardLevel,
            side = PieceType.GOAT,
            difficulty = opponent.difficulty,
            timer = GameTimer.RAPID
        )
    }

    fun onNodeClicked(pos: Position) {
        val state = _uiState.value.gameState
        if (state.isGameOver || _uiState.value.isAiThinking) return

        if (_uiState.value.gameMode == GameMode.VS_AI) {
            val isPlayerTurn = (_uiState.value.playerSide == PieceType.TIGER && state.currentTurn == PlayerTurn.TIGER) ||
                    (_uiState.value.playerSide == PieceType.GOAT && state.currentTurn == PlayerTurn.GOAT)
            if (!isPlayerTurn) return
        }

        val selected = _uiState.value.selectedPosition
        val currentTurn = state.currentTurn

        // If in goat placement phase: direct placement click
        if (currentTurn == PlayerTurn.GOAT && state.phase == GamePhase.PLACEMENT) {
            val placementMove = Move(
                from = Position(-1, -1),
                to = pos,
                pieceType = PieceType.GOAT
            )
            if (gameEngine.isValidMove(state, placementMove)) {
                processMove(placementMove)
            } else {
                audio.playSound("select")
            }
            return
        }

        // Piece movement phase:
        if (selected == null) {
            val piece = state.getPieceAt(pos)
            if (piece != null) {
                val matchesTurn = (piece.type == PieceType.TIGER && currentTurn == PlayerTurn.TIGER) ||
                        (piece.type == PieceType.GOAT && currentTurn == PlayerTurn.GOAT)
                if (matchesTurn) {
                    val allValid = gameEngine.getValidMoves(state)
                    val pieceMoves = allValid.filter { it.from == pos }
                    _uiState.value = _uiState.value.copy(
                        selectedPosition = pos,
                        validMovesForSelection = pieceMoves,
                        hintMove = null
                    )
                    audio.playSound("select")
                    audio.vibrate(25)
                }
            }
        } else {
            // Selected node already exists. Check if clicked node is a valid move
            val matchingMove = _uiState.value.validMovesForSelection.firstOrNull { it.to == pos }
            if (matchingMove != null) {
                processMove(matchingMove)
            } else {
                val clickedPiece = state.getPieceAt(pos)
                val matchesTurn = clickedPiece != null && (
                        (clickedPiece.type == PieceType.TIGER && currentTurn == PlayerTurn.TIGER) ||
                                (clickedPiece.type == PieceType.GOAT && currentTurn == PlayerTurn.GOAT)
                        )
                if (matchesTurn) {
                    val allValid = gameEngine.getValidMoves(state)
                    val pieceMoves = allValid.filter { it.from == pos }
                    _uiState.value = _uiState.value.copy(
                        selectedPosition = pos,
                        validMovesForSelection = pieceMoves
                    )
                    audio.playSound("select")
                } else {
                    _uiState.value = _uiState.value.copy(
                        selectedPosition = null,
                        validMovesForSelection = emptyList()
                    )
                }
            }
        }
    }

    private fun processMove(move: Move) {
        val currentState = _uiState.value.gameState
        if (!gameEngine.isValidMove(currentState, move)) return

        if (_uiState.value.gameMode == GameMode.PUZZLES) {
            processPuzzleMove(move)
            return
        }

        val newState = gameEngine.executeMove(currentState, move)
        playMoveSound(move)

        _uiState.value = _uiState.value.copy(
            gameState = newState,
            selectedPosition = null,
            validMovesForSelection = emptyList(),
            hintMove = null
        )

        checkGameCompletion(newState)

        if (!newState.isGameOver && _uiState.value.gameMode == GameMode.VS_AI) {
            val isAiTurn = (_uiState.value.playerSide == PieceType.TIGER && newState.currentTurn == PlayerTurn.GOAT) ||
                    (_uiState.value.playerSide == PieceType.GOAT && newState.currentTurn == PlayerTurn.TIGER)
            if (isAiTurn) {
                triggerAiTurn()
            }
        }
    }

    private fun processPuzzleMove(move: Move) {
        val puzzle = _uiState.value.currentPuzzle ?: return
        val currentIdx = _uiState.value.puzzleMoveIndex

        if (currentIdx < puzzle.solution.size) {
            val expected = puzzle.solution[currentIdx]
            val isCorrect = move.from == expected.from && move.to == expected.to && move.capturedAt == expected.capturedAt

            if (isCorrect) {
                val newState = gameEngine.executeMove(_uiState.value.gameState, move)
                playMoveSound(move)
                val nextIdx = currentIdx + 1

                if (nextIdx >= puzzle.solution.size) {
                    // Solved puzzle!
                    _uiState.value = _uiState.value.copy(
                        gameState = newState,
                        puzzleMoveIndex = nextIdx,
                        puzzleSuccess = true,
                        isGameEndDialogVisible = true,
                        selectedPosition = null,
                        validMovesForSelection = emptyList(),
                        alertMessage = "Puzzle Solved! +${puzzle.difficulty.baseReward} Rating"
                    )
                    prefs.markPuzzleSolved(puzzle.id)
                    updateProfileAfterPuzzle(puzzle)
                    audio.playSound("game_win")
                } else {
                    _uiState.value = _uiState.value.copy(
                        gameState = newState,
                        puzzleMoveIndex = nextIdx,
                        selectedPosition = null,
                        validMovesForSelection = emptyList()
                    )
                    // AI auto plays intermediate response
                    viewModelScope.launch {
                        delay(400)
                        val aiMove = puzzle.solution[nextIdx]
                        val stateAfterAi = gameEngine.executeMove(_uiState.value.gameState, aiMove)
                        playMoveSound(aiMove)
                        _uiState.value = _uiState.value.copy(
                            gameState = stateAfterAi,
                            puzzleMoveIndex = nextIdx + 1
                        )
                    }
                }
            } else {
                audio.playSound("game_lose")
                audio.vibrate(80)
                _uiState.value = _uiState.value.copy(
                    alertMessage = "Not the best move. Try again or ask for a Hint!",
                    selectedPosition = null,
                    validMovesForSelection = emptyList()
                )
            }
        }
    }

    private fun triggerAiTurn() {
        _uiState.value = _uiState.value.copy(isAiThinking = true)
        viewModelScope.launch {
            delay(350)
            val currentState = _uiState.value.gameState
            val aiMove = aiEngine.getBestMove(currentState)
            _uiState.value = _uiState.value.copy(isAiThinking = false)

            if (aiMove != null && !currentState.isGameOver) {
                val newState = gameEngine.executeMove(currentState, aiMove)
                playMoveSound(aiMove)
                _uiState.value = _uiState.value.copy(gameState = newState)
                checkGameCompletion(newState)
            }
        }
    }

    private fun checkGameCompletion(state: GameState) {
        if (state.isGameOver) {
            timerJob?.cancel()
            val userSide = _uiState.value.playerSide
            val didUserWin = (state.winner == GameWinner.TIGERS && userSide == PieceType.TIGER) ||
                    (state.winner == GameWinner.GOATS && userSide == PieceType.GOAT)

            if (didUserWin) {
                audio.playSound("game_win")
            } else if (state.winner == GameWinner.DRAW) {
                audio.playSound("game_start")
            } else {
                audio.playSound("game_lose")
            }

            updateProfileAfterGame(state, didUserWin)
            _uiState.value = _uiState.value.copy(isGameEndDialogVisible = true)
        }
    }

    private fun updateProfileAfterGame(state: GameState, userWon: Boolean) {
        val current = _uiState.value.userProfile
        val side = _uiState.value.playerSide
        val isVsAi = _uiState.value.gameMode == GameMode.VS_AI || _uiState.value.gameMode == GameMode.TOURNAMENT
        if (!isVsAi) return

        val ratingChange = if (userWon) +25 else if (state.winner == GameWinner.DRAW) 0 else -18
        val updated = current.copy(
            rating = (current.rating + ratingChange).coerceAtLeast(400),
            winsAsTiger = if (side == PieceType.TIGER && userWon) current.winsAsTiger + 1 else current.winsAsTiger,
            lossesAsTiger = if (side == PieceType.TIGER && !userWon && state.winner != GameWinner.DRAW) current.lossesAsTiger + 1 else current.lossesAsTiger,
            winsAsGoat = if (side == PieceType.GOAT && userWon) current.winsAsGoat + 1 else current.winsAsGoat,
            lossesAsGoat = if (side == PieceType.GOAT && !userWon && state.winner != GameWinner.DRAW) current.lossesAsGoat + 1 else current.lossesAsGoat
        )
        _uiState.value = _uiState.value.copy(userProfile = updated)
        prefs.saveUserProfile(updated)
    }

    private fun updateProfileAfterPuzzle(puzzle: Puzzle) {
        val current = _uiState.value.userProfile
        val updated = current.copy(
            rating = current.rating + puzzle.difficulty.baseReward / 2,
            puzzlesSolved = current.puzzlesSolved + 1
        )
        _uiState.value = _uiState.value.copy(userProfile = updated)
        prefs.saveUserProfile(updated)
    }

    private fun playMoveSound(move: Move) {
        if (move.isCapture) {
            audio.playSound("tiger_capture")
            audio.vibrate(70)
        } else if (move.pieceType == PieceType.TIGER) {
            audio.playSound("tiger_move")
            audio.vibrate(30)
        } else {
            audio.playSound("goat_move")
            audio.vibrate(20)
        }
    }

    fun requestHint() {
        val state = _uiState.value.gameState
        if (state.isGameOver) return

        if (_uiState.value.gameMode == GameMode.PUZZLES) {
            val puzzle = _uiState.value.currentPuzzle ?: return
            val idx = _uiState.value.puzzleMoveIndex
            if (idx < puzzle.solution.size) {
                val hint = puzzle.solution[idx]
                _uiState.value = _uiState.value.copy(
                    hintMove = hint,
                    alertMessage = "Hint: Move ${hint.pieceType.displayName} from ${hint.from} to ${hint.to}"
                )
            }
            return
        }

        viewModelScope.launch {
            val best = aiEngine.getBestMove(state)
            if (best != null) {
                _uiState.value = _uiState.value.copy(
                    hintMove = best,
                    selectedPosition = if (best.isPlacement) null else best.from,
                    validMovesForSelection = listOf(best)
                )
                audio.playSound("select")
            }
        }
    }

    fun undoMove() {
        val state = _uiState.value.gameState
        if (state.moveHistory.isEmpty() || state.isGameOver) return

        val movesToPop = if (_uiState.value.gameMode == GameMode.VS_AI && state.moveHistory.size >= 2) 2 else 1
        val newCount = (state.moveHistory.size - movesToPop).coerceAtLeast(0)

        var rebuilt = GameState.initial(state.level, _uiState.value.timer)
        val targetMoves = state.moveHistory.take(newCount)
        for (m in targetMoves) {
            rebuilt = gameEngine.executeMove(rebuilt, m)
        }

        _uiState.value = _uiState.value.copy(
            gameState = rebuilt,
            selectedPosition = null,
            validMovesForSelection = emptyList(),
            hintMove = null,
            isGameEndDialogVisible = false
        )
        audio.playSound("button_tap")
    }

    fun applyPowerUp(type: PowerUpType, target: Position) {
        val state = _uiState.value.gameState
        if (state.isGameOver) return
        val newState = gameEngine.applyPowerUp(state, type, target)
        _uiState.value = _uiState.value.copy(gameState = newState)
        audio.playSound("tiger_capture")
        audio.vibrate(50)
    }

    fun setTheme(theme: BoardTheme) {
        _uiState.value = _uiState.value.copy(currentTheme = theme)
        prefs.setSelectedTheme(theme)
    }

    fun toggleSound() {
        val updated = !_uiState.value.soundEnabled
        _uiState.value = _uiState.value.copy(soundEnabled = updated)
        prefs.setSoundEnabled(updated)
        audio.isSoundEnabled = updated
    }

    fun toggleHaptics() {
        val updated = !_uiState.value.hapticsEnabled
        _uiState.value = _uiState.value.copy(hapticsEnabled = updated)
        prefs.setHapticsEnabled(updated)
        audio.isHapticsEnabled = updated
    }

    fun dismissEndDialog() {
        _uiState.value = _uiState.value.copy(isGameEndDialogVisible = false)
    }

    fun dismissAlert() {
        _uiState.value = _uiState.value.copy(alertMessage = null)
    }

    private fun startTimerLoop() {
        if (!_uiState.value.timer.hasLimit) return

        timerJob = viewModelScope.launch {
            while (true) {
                delay(1000)
                val state = _uiState.value.gameState
                if (state.isGameOver || state.isPaused) continue

                if (state.currentTurn == PlayerTurn.TIGER) {
                    val rem = (state.tigerTimeRemainingMillis ?: 0L) - 1000L
                    if (rem <= 0) {
                        _uiState.value = _uiState.value.copy(
                            gameState = state.copy(
                                tigerTimeRemainingMillis = 0,
                                winner = GameWinner.GOATS,
                                drawReason = DrawReason.TIMEOUT,
                                phase = GamePhase.ENDED
                            ),
                            isGameEndDialogVisible = true
                        )
                        audio.playSound("game_win")
                        break
                    } else {
                        if (rem <= 10000 && rem % 2000 == 0L) audio.playSound("timer_warning")
                        _uiState.value = _uiState.value.copy(
                            gameState = state.copy(tigerTimeRemainingMillis = rem)
                        )
                    }
                } else {
                    val rem = (state.goatTimeRemainingMillis ?: 0L) - 1000L
                    if (rem <= 0) {
                        _uiState.value = _uiState.value.copy(
                            gameState = state.copy(
                                goatTimeRemainingMillis = 0,
                                winner = GameWinner.TIGERS,
                                drawReason = DrawReason.TIMEOUT,
                                phase = GamePhase.ENDED
                            ),
                            isGameEndDialogVisible = true
                        )
                        audio.playSound("game_lose")
                        break
                    } else {
                        if (rem <= 10000 && rem % 2000 == 0L) audio.playSound("timer_warning")
                        _uiState.value = _uiState.value.copy(
                            gameState = state.copy(goatTimeRemainingMillis = rem)
                        )
                    }
                }
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        audio.release()
    }
}
