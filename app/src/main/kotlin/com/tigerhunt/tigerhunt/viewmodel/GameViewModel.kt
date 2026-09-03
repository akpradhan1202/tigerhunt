package com.tigerhunt.tigerhunt.viewmodel

import android.app.Application
import android.net.Uri
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.tigerhunt.tigerhunt.data.FirestoreLeaderboardService
import com.tigerhunt.tigerhunt.data.GamePreferences
import com.tigerhunt.tigerhunt.data.NotificationHelper
import com.tigerhunt.tigerhunt.data.PushNotificationManager
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
import java.io.File
import java.io.FileOutputStream
import kotlin.math.abs

data class GameUiState(
    val gameState: GameState,
    val gameMode: GameMode = GameMode.VS_AI,
    val boardLevel: BoardLevel = BoardLevel.SQUARE,
    val playerSide: PieceType = PieceType.GOAT,
    val aiDifficulty: AIDifficulty = AIDifficulty.MEDIUM,
    val selectedPosition: Position? = null,
    val validMovesForSelection: List<Move> = emptyList(),
    val currentTheme: BoardTheme = BoardTheme.CLASSIC_NEPAL,
    val userProfile: UserProfile = UserProfile(),
    val timer: GameTimer = GameTimer.CLASSIC,
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
    val alertMessage: String? = null,
    val onlineOpponent: OnlineOpponent? = null,
    val roomCode: String? = null,
    val friendPlayerName: String = "Friend",
    val chatMessages: List<Pair<String, String>> = emptyList(),
    val leaderboardPlayers: List<LeaderboardPlayer> = emptyList(),
    val isLeaderboardLoading: Boolean = false,
    val leaderboardError: String? = null,
    val leaderboardFilter: LeaderboardFilter = LeaderboardFilter.TOTAL_WINS,
    val isScoreSyncing: Boolean = false,
    val scoreSyncSuccessMessage: String? = null,
    val leaderboardSearchQuery: String = "",
    val pushNotificationsEnabled: Boolean = true,
    val turnNotificationsEnabled: Boolean = true,
    val tournamentNotificationsEnabled: Boolean = true,
    val fcmToken: String? = null,
    val notificationTestStatus: String? = null,
    val friends: List<Friend> = listOf(
        Friend(
            id = "f1",
            name = "Aarav Shrestha",
            avatar = "🐅",
            rating = 1450,
            rank = "Mountain Guardian",
            status = FriendStatus.ONLINE,
            friendCode = "BH-4891",
            countryFlag = "🇳🇵",
            isFavorite = true
        ),
        Friend(
            id = "f2",
            name = "Priya Sharma",
            avatar = "🐐",
            rating = 1380,
            rank = "Highland Stalker",
            status = FriendStatus.ONLINE,
            friendCode = "BH-7723",
            countryFlag = "🇮🇳"
        ),
        Friend(
            id = "f3",
            name = "Kiran Thapa",
            avatar = "👑",
            rating = 1520,
            rank = "Mountain Guardian",
            status = FriendStatus.IN_GAME,
            friendCode = "BH-1904",
            countryFlag = "🇳🇵"
        ),
        Friend(
            id = "f4",
            name = "Tenzing Norgay",
            avatar = "🏔️",
            rating = 1840,
            rank = "Apex Predator",
            status = FriendStatus.OFFLINE,
            friendCode = "BH-8821",
            countryFlag = "🇳🇵",
            lastSeen = "2h ago"
        )
    )
)

class GameViewModel(application: Application) : AndroidViewModel(application) {
    private val prefs = GamePreferences(application)
    val audio = AudioService(application)
    private val firestoreService = FirestoreLeaderboardService()

    private var gameEngine: GameEngine = GameEngine(BoardLevel.SQUARE)
    private var aiEngine: AIEngine = AIEngine(gameEngine, AIDifficulty.MEDIUM)
    private var timerJob: Job? = null

    private val _uiState = MutableStateFlow(
        GameUiState(
            gameState = GameState.initial(BoardLevel.SQUARE, GameTimer.CLASSIC),
            boardLevel = BoardLevel.SQUARE,
            timer = GameTimer.CLASSIC,
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
        loadLeaderboard()

        val initialFcm = prefs.getFcmToken()
        _uiState.value = _uiState.value.copy(
            pushNotificationsEnabled = prefs.isPushNotificationsEnabled(),
            turnNotificationsEnabled = prefs.isTurnNotificationsEnabled(),
            tournamentNotificationsEnabled = prefs.isTournamentNotificationsEnabled(),
            fcmToken = initialFcm
        )

        // Initialize FCM registration and channel subscriptions
        PushNotificationManager.initialize(application) { token ->
            _uiState.value = _uiState.value.copy(fcmToken = token)
        }
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
            alertMessage = if (puzzle.isDaily) "Daily Tactical Challenge • Sequence (${puzzle.sequenceLength} Move${if (puzzle.sequenceLength > 1) "s" else ""})" else null
        )
        audio.playSound("game_start")
    }

    fun startDailyPuzzle() {
        val todayDate = DailyChallengeManager.getTodayDateString()
        val puzzle = DailyChallengeManager.getDailyPuzzle(todayDate)
        startPuzzle(puzzle)
    }

    fun isDailyPuzzleSolvedToday(): Boolean {
        val todayDate = DailyChallengeManager.getTodayDateString()
        return prefs.isDailyPuzzleSolvedForDate(todayDate)
    }

    fun startTournament() {
        val user = _uiState.value.userProfile
        val tournament = TournamentState.createDefault(user.username)
        _uiState.value = _uiState.value.copy(tournamentState = tournament)

        val firstMatch = tournament.matches.firstOrNull { it.player1.isUser || it.player2.isUser }
        val opponentName = if (firstMatch != null) {
            if (firstMatch.player1.isUser) firstMatch.player2.name else firstMatch.player1.name
        } else "Sherpa Tenzing"

        // Trigger real tournament start push notification
        PushNotificationManager.sendTournamentStartPush(
            context = getApplication(),
            tournamentTitle = "Kathmandu Championship Cup",
            stageName = tournament.currentStage.displayName,
            opponentName = opponentName
        )

        startTournamentMatch()
    }

    fun startLiveGame(
        level: BoardLevel,
        timer: GameTimer,
        opponent: OnlineOpponent,
        playerSide: PieceType
    ) {
        timerJob?.cancel()
        gameEngine = GameEngine(level)
        // Set AI engine corresponding to opponent rating
        val difficulty = when {
            opponent.rating >= 1350 -> AIDifficulty.EXPERT
            opponent.rating >= 1250 -> AIDifficulty.HARD
            opponent.rating >= 1100 -> AIDifficulty.MEDIUM
            else -> AIDifficulty.EASY
        }
        aiEngine = AIEngine(gameEngine, difficulty)

        val initialState = GameState.initial(level, timer)
        _uiState.value = _uiState.value.copy(
            gameState = initialState,
            gameMode = GameMode.PLAY_LIVE,
            boardLevel = level,
            playerSide = playerSide,
            aiDifficulty = difficulty,
            timer = timer,
            onlineOpponent = opponent,
            roomCode = null,
            chatMessages = listOf("System" to "Connected to ${opponent.countryFlag} ${opponent.name} (${opponent.rating} ELO)"),
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

        if (playerSide == PieceType.TIGER && initialState.currentTurn == PlayerTurn.GOAT) {
            triggerLiveOpponentTurn()
        }
    }

    fun startFriendGame(
        mode: GameMode,
        level: BoardLevel,
        timer: GameTimer,
        playerSide: PieceType,
        friendName: String,
        roomCode: String?
    ) {
        timerJob?.cancel()
        gameEngine = GameEngine(level)
        aiEngine = AIEngine(gameEngine, AIDifficulty.MEDIUM)

        val initialState = GameState.initial(level, timer)
        _uiState.value = _uiState.value.copy(
            gameState = initialState,
            gameMode = mode,
            boardLevel = level,
            playerSide = playerSide,
            timer = timer,
            friendPlayerName = friendName,
            roomCode = roomCode,
            chatMessages = if (roomCode != null) listOf("System" to "Friend room $roomCode connected!") else emptyList(),
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
    }

    fun sendQuickEmote(emote: String) {
        val current = _uiState.value.chatMessages
        val user = _uiState.value.userProfile.username
        val updated = (current + (user to emote)).takeLast(10)
        _uiState.value = _uiState.value.copy(chatMessages = updated)
        audio.playSound("select")

        // Opponent occasional reaction
        if (_uiState.value.gameMode == GameMode.PLAY_LIVE) {
            viewModelScope.launch {
                delay(1200)
                val opponent = _uiState.value.onlineOpponent ?: return@launch
                val responses = listOf("👍", "🐅", "🇳🇵", "🔥", "Good move!", "GG!", "🤝")
                val reply = responses.random()
                val afterReply = (_uiState.value.chatMessages + (opponent.name to reply)).takeLast(10)
                _uiState.value = _uiState.value.copy(chatMessages = afterReply)
            }
        }
    }

    fun resignGame() {
        val state = _uiState.value.gameState
        if (state.isGameOver) return
        val userSide = _uiState.value.playerSide
        val winner = if (userSide == PieceType.TIGER) GameWinner.GOATS else GameWinner.TIGERS
        val endState = state.copy(winner = winner, phase = GamePhase.ENDED)
        _uiState.value = _uiState.value.copy(gameState = endState)
        checkGameCompletion(endState)
    }

    fun startTournamentMatch() {
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

        if (_uiState.value.gameMode == GameMode.VS_AI || _uiState.value.gameMode == GameMode.PLAY_LIVE) {
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

        if (!newState.isGameOver) {
            if (_uiState.value.gameMode == GameMode.VS_AI) {
                val isAiTurn = (_uiState.value.playerSide == PieceType.TIGER && newState.currentTurn == PlayerTurn.GOAT) ||
                        (_uiState.value.playerSide == PieceType.GOAT && newState.currentTurn == PlayerTurn.TIGER)
                if (isAiTurn) {
                    triggerAiTurn()
                }
            } else if (_uiState.value.gameMode == GameMode.PLAY_LIVE) {
                val isOpponentTurn = (_uiState.value.playerSide == PieceType.TIGER && newState.currentTurn == PlayerTurn.GOAT) ||
                        (_uiState.value.playerSide == PieceType.GOAT && newState.currentTurn == PlayerTurn.TIGER)
                if (isOpponentTurn) {
                    triggerLiveOpponentTurn()
                }
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

    private fun triggerLiveOpponentTurn() {
        _uiState.value = _uiState.value.copy(isAiThinking = true)
        viewModelScope.launch {
            val opponentDelay = (800L..1600L).random()
            delay(opponentDelay)
            val currentState = _uiState.value.gameState
            val opponentMove = aiEngine.getBestMove(currentState)
            _uiState.value = _uiState.value.copy(isAiThinking = false)

            if (opponentMove != null && !currentState.isGameOver) {
                val newState = gameEngine.executeMove(currentState, opponentMove)
                playMoveSound(opponentMove)
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
        val isRanked = _uiState.value.gameMode == GameMode.VS_AI ||
                _uiState.value.gameMode == GameMode.TOURNAMENT ||
                _uiState.value.gameMode == GameMode.PLAY_LIVE
        if (!isRanked) return

        val opponentRating = _uiState.value.onlineOpponent?.rating ?: 1200
        val ratingDiff = (opponentRating - current.rating).coerceIn(-400, 400)
        val baseChange = if (userWon) +20 + (ratingDiff / 20) else if (state.winner == GameWinner.DRAW) 0 else -16 - (ratingDiff / 25)
        val finalRatingChange = baseChange.coerceIn(-35, 35)

        val updated = current.copy(
            rating = (current.rating + finalRatingChange).coerceAtLeast(400),
            winsAsTiger = if (side == PieceType.TIGER && userWon) current.winsAsTiger + 1 else current.winsAsTiger,
            lossesAsTiger = if (side == PieceType.TIGER && !userWon && state.winner != GameWinner.DRAW) current.lossesAsTiger + 1 else current.lossesAsTiger,
            winsAsGoat = if (side == PieceType.GOAT && userWon) current.winsAsGoat + 1 else current.winsAsGoat,
            lossesAsGoat = if (side == PieceType.GOAT && !userWon && state.winner != GameWinner.DRAW) current.lossesAsGoat + 1 else current.lossesAsGoat
        )
        _uiState.value = _uiState.value.copy(userProfile = updated)
        prefs.saveUserProfile(updated)

        // Sync score to Firestore in background
        viewModelScope.launch {
            firestoreService.syncUserScoreToFirestore(updated)
            loadLeaderboard(showLoading = false)
        }
    }

    private fun updateProfileAfterPuzzle(puzzle: Puzzle) {
        val current = _uiState.value.userProfile
        val todayDate = DailyChallengeManager.getTodayDateString()
        val isDaily = puzzle.isDaily || puzzle.id.startsWith("daily_")

        var coinsEarned = puzzle.coinReward
        var newStreak = current.dailyStreak

        if (isDaily) {
            val wasAlreadySolvedToday = prefs.isDailyPuzzleSolvedForDate(todayDate)
            if (!wasAlreadySolvedToday) {
                val yesterday = getYesterdayDateString()
                newStreak = if (current.lastDailyPuzzleDate == yesterday) {
                    current.dailyStreak + 1
                } else if (current.lastDailyPuzzleDate == todayDate) {
                    current.dailyStreak
                } else {
                    1
                }

                val bonusCoins = DailyChallengeManager.calculateDailyStreakBonus(newStreak)
                coinsEarned += bonusCoins
                prefs.markDailyPuzzleSolvedForDate(todayDate)
            } else {
                coinsEarned = 25 // Practice reward
            }
        }

        val updated = current.copy(
            rating = current.rating + puzzle.difficulty.baseReward / 2,
            puzzlesSolved = current.puzzlesSolved + 1,
            coins = current.coins + coinsEarned,
            dailyStreak = newStreak,
            lastDailyPuzzleDate = if (isDaily) todayDate else current.lastDailyPuzzleDate
        )
        _uiState.value = _uiState.value.copy(
            userProfile = updated,
            alertMessage = if (isDaily) "🎉 Daily Solved! +$coinsEarned 🪙 Coins Awarded! 🔥 $newStreak Day Streak!" else "Puzzle Solved! +$coinsEarned 🪙 Coins & +${puzzle.difficulty.baseReward / 2} Rating"
        )
        prefs.saveUserProfile(updated)

        // Sync score to Firestore
        viewModelScope.launch {
            firestoreService.syncUserScoreToFirestore(updated)
            loadLeaderboard(showLoading = false)
        }
    }

    private fun getYesterdayDateString(): String {
        val cal = java.util.Calendar.getInstance()
        cal.add(java.util.Calendar.DAY_OF_YEAR, -1)
        val sdf = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
        return sdf.format(cal.time)
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

    fun loginWithGoogle(email: String, displayName: String? = null) {
        val name = displayName?.takeIf { it.isNotBlank() } ?: email.substringBefore("@").replace(".", " ").capitalize()
        val current = _uiState.value.userProfile
        val updated = current.copy(
            id = "google_${email.hashCode()}",
            username = name,
            email = email,
            authMethod = AuthMethod.GMAIL,
            isLoggedIn = true
        )
        _uiState.value = _uiState.value.copy(userProfile = updated)
        prefs.saveUserProfile(updated)
        audio.playSound("game_win")
    }

    fun loginWithPhone(phoneNumber: String, displayName: String? = null) {
        val name = displayName?.takeIf { it.isNotBlank() } ?: "Player ${phoneNumber.takeLast(4)}"
        val current = _uiState.value.userProfile
        val updated = current.copy(
            id = "phone_${phoneNumber.hashCode()}",
            username = name,
            phoneNumber = phoneNumber,
            authMethod = AuthMethod.PHONE,
            isLoggedIn = true
        )
        _uiState.value = _uiState.value.copy(userProfile = updated)
        prefs.saveUserProfile(updated)
        audio.playSound("game_win")
    }

    fun loginAsGuest(guestName: String = "Guest Hunter") {
        val current = _uiState.value.userProfile
        val updated = current.copy(
            id = "guest_${System.currentTimeMillis() % 10000}",
            username = guestName.ifBlank { "Guest Hunter" },
            email = null,
            phoneNumber = null,
            authMethod = AuthMethod.GUEST,
            isLoggedIn = true
        )
        _uiState.value = _uiState.value.copy(userProfile = updated)
        prefs.saveUserProfile(updated)
        audio.playSound("piece_place")
    }

    fun addFriend(nameOrCode: String): Boolean {
        val trimmed = nameOrCode.trim()
        if (trimmed.isBlank()) return false

        val currentFriends = _uiState.value.friends
        val isCode = trimmed.uppercase().startsWith("BH-")
        val friendName = if (isCode) "Player ${trimmed.takeLast(4)}" else trimmed
        val friendCode = if (isCode) trimmed.uppercase() else "BH-${abs(trimmed.hashCode() % 9000) + 1000}"

        if (currentFriends.any { it.friendCode.equals(friendCode, ignoreCase = true) || it.name.equals(friendName, ignoreCase = true) }) {
            return false
        }

        val avatars = listOf("🐅", "🐐", "👑", "🏔️", "🦅", "🏹", "🛡️", "🐆")
        val ranks = listOf("Highland Stalker", "Mountain Guardian", "Apex Predator", "Bagh Novice")
        val newFriend = Friend(
            id = "friend_${System.currentTimeMillis()}",
            name = friendName,
            avatar = avatars.random(),
            rating = (1150..1650).random(),
            rank = ranks.random(),
            status = FriendStatus.ONLINE,
            friendCode = friendCode,
            countryFlag = listOf("🇳🇵", "🇮🇳", "🇧🇹", "🇺🇸", "🇬🇧").random(),
            isFavorite = false,
            lastSeen = "Just now"
        )

        _uiState.value = _uiState.value.copy(
            friends = listOf(newFriend) + currentFriends
        )
        audio.playSound("game_win")
        audio.vibrate(30)
        return true
    }

    fun removeFriend(friendId: String) {
        _uiState.value = _uiState.value.copy(
            friends = _uiState.value.friends.filter { it.id != friendId }
        )
        audio.playSound("tiger_capture")
    }

    fun toggleFavoriteFriend(friendId: String) {
        _uiState.value = _uiState.value.copy(
            friends = _uiState.value.friends.map { friend ->
                if (friend.id == friendId) friend.copy(isFavorite = !friend.isFavorite) else friend
            }
        )
        audio.vibrate(20)
    }

    fun updateProfile(username: String, avatar: String, customAvatarUri: String? = _uiState.value.userProfile.customAvatarUri) {
        val current = _uiState.value.userProfile
        val updated = current.copy(
            username = username.ifBlank { current.username },
            avatarId = avatar,
            customAvatarUri = customAvatarUri
        )
        _uiState.value = _uiState.value.copy(userProfile = updated)
        prefs.saveUserProfile(updated)
        loadLeaderboard()
    }

    fun saveCustomAvatarFromUri(uri: Uri): String? {
        return try {
            val context = getApplication<Application>()
            val inputStream = context.contentResolver.openInputStream(uri) ?: return null
            val avatarFileName = "custom_avatar_${System.currentTimeMillis()}.png"
            val file = File(context.filesDir, avatarFileName)
            FileOutputStream(file).use { outputStream ->
                inputStream.copyTo(outputStream)
            }
            val filePath = file.absolutePath
            val current = _uiState.value.userProfile
            val updated = current.copy(customAvatarUri = filePath)
            _uiState.value = _uiState.value.copy(userProfile = updated)
            prefs.saveUserProfile(updated)
            loadLeaderboard()
            audio.vibrate(25)
            filePath
        } catch (e: Exception) {
            Log.e("GameViewModel", "Failed to save avatar from URI", e)
            null
        }
    }

    fun removeCustomAvatar() {
        val current = _uiState.value.userProfile
        val updated = current.copy(customAvatarUri = null)
        _uiState.value = _uiState.value.copy(userProfile = updated)
        prefs.saveUserProfile(updated)
        loadLeaderboard()
        audio.vibrate(20)
    }

    fun logout() {
        prefs.clearSession()
        val current = _uiState.value.userProfile
        val updated = current.copy(
            id = "guest_${System.currentTimeMillis() % 10000}",
            email = null,
            phoneNumber = null,
            authMethod = AuthMethod.GUEST,
            isLoggedIn = false,
            username = "Guest Hunter"
        )
        _uiState.value = _uiState.value.copy(userProfile = updated)
        prefs.saveUserProfile(updated)
        audio.vibrate(30)
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

    fun loadLeaderboard(
        filter: LeaderboardFilter = _uiState.value.leaderboardFilter,
        showLoading: Boolean = true
    ) {
        if (showLoading) {
            _uiState.value = _uiState.value.copy(isLeaderboardLoading = true, leaderboardError = null)
        }
        viewModelScope.launch {
            val result = firestoreService.fetchLeaderboard(
                currentUser = _uiState.value.userProfile,
                filter = filter
            )
            result.onSuccess { players ->
                _uiState.value = _uiState.value.copy(
                    leaderboardPlayers = players,
                    isLeaderboardLoading = false,
                    leaderboardError = null
                )
            }.onFailure { err ->
                _uiState.value = _uiState.value.copy(
                    isLeaderboardLoading = false,
                    leaderboardError = err.message ?: "Failed to load live leaderboard from Firestore"
                )
            }
        }
    }

    fun setLeaderboardFilter(filter: LeaderboardFilter) {
        _uiState.value = _uiState.value.copy(leaderboardFilter = filter)
        loadLeaderboard(filter = filter, showLoading = true)
    }

    fun setLeaderboardSearchQuery(query: String) {
        _uiState.value = _uiState.value.copy(leaderboardSearchQuery = query)
    }

    fun syncUserScoreToFirestore() {
        _uiState.value = _uiState.value.copy(isScoreSyncing = true, scoreSyncSuccessMessage = null)
        viewModelScope.launch {
            val result = firestoreService.syncUserScoreToFirestore(_uiState.value.userProfile)
            _uiState.value = _uiState.value.copy(
                isScoreSyncing = false,
                scoreSyncSuccessMessage = "Score & ${_uiState.value.userProfile.totalWins} Wins successfully synced to Firestore!"
            )
            loadLeaderboard(showLoading = false)
            audio.playSound("select")
            audio.vibrate(40)
        }
    }

    fun dismissScoreSyncMessage() {
        _uiState.value = _uiState.value.copy(scoreSyncSuccessMessage = null)
    }

    // ==========================================
    // PUSH NOTIFICATIONS & FCM MANAGEMENT
    // ==========================================

    fun togglePushNotifications() {
        val updated = !_uiState.value.pushNotificationsEnabled
        _uiState.value = _uiState.value.copy(pushNotificationsEnabled = updated)
        prefs.setPushNotificationsEnabled(updated)
        audio.vibrate(20)
    }

    fun toggleTurnNotifications() {
        val updated = !_uiState.value.turnNotificationsEnabled
        _uiState.value = _uiState.value.copy(turnNotificationsEnabled = updated)
        prefs.setTurnNotificationsEnabled(updated)
        audio.vibrate(20)
    }

    fun toggleTournamentNotifications() {
        val updated = !_uiState.value.tournamentNotificationsEnabled
        _uiState.value = _uiState.value.copy(tournamentNotificationsEnabled = updated)
        prefs.setTournamentNotificationsEnabled(updated)
        audio.vibrate(20)
    }

    fun testFriendTurnNotification(
        friendName: String = "Aarav Shrestha",
        roomCode: String = "8899"
    ) {
        val context = getApplication<Application>()
        PushNotificationManager.sendFriendTurnPush(
            context = context,
            friendName = friendName,
            roomCode = roomCode,
            role = if (_uiState.value.playerSide == PieceType.TIGER) "Tiger" else "Goats",
            moveSummary = "Placed goat on center node • Turn is yours!"
        )
        _uiState.value = _uiState.value.copy(
            notificationTestStatus = "Turn Push Alert dispatched for Room #$roomCode against $friendName"
        )
        audio.playSound("select")
        audio.vibrate(40)
    }

    fun testTournamentStartNotification(
        tournamentTitle: String = "Kathmandu Championship Cup",
        stageName: String = "Quarter-Finals",
        opponentName: String = "Sherpa Tenzing"
    ) {
        val context = getApplication<Application>()
        PushNotificationManager.sendTournamentStartPush(
            context = context,
            tournamentTitle = tournamentTitle,
            stageName = stageName,
            opponentName = opponentName
        )
        _uiState.value = _uiState.value.copy(
            notificationTestStatus = "Championship Push Alert dispatched for $stageName vs $opponentName!"
        )
        audio.playSound("game_win")
        audio.vibrate(40)
    }

    fun simulateOpponentFriendMove(friendName: String, roomCode: String) {
        val context = getApplication<Application>()
        PushNotificationManager.scheduleSimulatedFriendTurn(
            context = context,
            friendName = friendName,
            roomCode = roomCode,
            delayMillis = 2000L,
            role = if (_uiState.value.playerSide == PieceType.TIGER) "Tiger" else "Goats",
            moveSummary = "$friendName played move to center intersection"
        )
        _uiState.value = _uiState.value.copy(
            notificationTestStatus = "Opponent move scheduled. Turn notification incoming in 2 seconds!"
        )
    }

    fun nudgeFriendTurn(friend: Friend, roomCode: String = "8899") {
        val context = getApplication<Application>()
        PushNotificationManager.sendFriendTurnPush(
            context = context,
            friendName = friend.name,
            roomCode = roomCode,
            role = "Tigers",
            moveSummary = "Turn nudge: Prompting ${friend.name} to play move in Bagh-Chal"
        )
        _uiState.value = _uiState.value.copy(
            alertMessage = "Turn nudge notification sent to ${friend.name}!"
        )
        audio.playSound("select")
        audio.vibrate(30)
    }

    fun dismissNotificationTestStatus() {
        _uiState.value = _uiState.value.copy(notificationTestStatus = null)
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        audio.release()
    }
}
