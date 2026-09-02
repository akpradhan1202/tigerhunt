package com.tigerhunt.tigerhunt.model

enum class GamePhase {
    PLACEMENT,
    MOVEMENT,
    ENDED
}

enum class GameWinner {
    TIGERS,
    GOATS,
    DRAW,
    NONE
}

data class GameState(
    val level: BoardLevel,
    val pieces: List<Piece>,
    val currentTurn: PlayerTurn,
    val phase: GamePhase,
    val winner: GameWinner = GameWinner.NONE,
    val drawReason: DrawReason = DrawReason.NONE,
    val goatsPlaced: Int = 0,
    val goatsCaptured: Int = 0,
    val moveHistory: List<Move> = emptyList(),
    val tigerTimeRemainingMillis: Long? = null,
    val goatTimeRemainingMillis: Long? = null,
    val isPaused: Boolean = false,
    val positionHistory: Map<String, Int> = emptyMap(),
    val movesWithoutCapture: Int = 0,
    val activeEffects: List<ActiveEffect> = emptyList(),
    val collapsedPositions: Set<Position> = emptySet(),
    val usedPowerUps: Map<PlayerTurn, Set<PowerUpType>> = mapOf(
        PlayerTurn.TIGER to emptySet(),
        PlayerTurn.GOAT to emptySet()
    )
) {
    val tigers: List<Piece> get() = pieces.filter { it.type == PieceType.TIGER && !it.isCaptured }
    val goatsOnBoard: List<Piece> get() = pieces.filter { it.type == PieceType.GOAT && !it.isCaptured }
    val goatsRemaining: Int get() = goatsPlaced - goatsCaptured
    val goatsToPlace: Int get() = level.goatCount - goatsPlaced
    val allGoatsPlaced: Boolean get() = goatsPlaced >= level.goatCount
    val isGameOver: Boolean get() = winner != GameWinner.NONE

    val stateSignature: String get() {
        val tPos = tigers.map { "${it.position.row},${it.position.col}" }.sorted().joinToString(";")
        val gPos = goatsOnBoard.map { "${it.position.row},${it.position.col}" }.sorted().joinToString(";")
        return "${currentTurn.name}|${phase.name}|$goatsToPlace|T:[$tPos]|G:[$gPos]"
    }

    fun isBoulderAt(pos: Position): Boolean =
        activeEffects.any { it.type == PowerUpType.BOULDER && it.targetPosition == pos }

    fun isGoatShielded(pos: Position): Boolean =
        activeEffects.any { it.type == PowerUpType.HORN_SHIELD && it.targetPosition == pos }

    fun isGoatStunned(pos: Position): Boolean =
        activeEffects.any { it.type == PowerUpType.TIGER_ROAR && it.targetPosition == pos }

    fun isPositionCollapsed(pos: Position): Boolean = collapsedPositions.contains(pos)

    fun getPieceAt(pos: Position): Piece? =
        pieces.firstOrNull { it.position == pos && !it.isCaptured }

    fun isPositionEmpty(pos: Position): Boolean =
        getPieceAt(pos) == null && !isBoulderAt(pos) && !isPositionCollapsed(pos)

    companion object {
        fun initial(level: BoardLevel, timer: GameTimer? = null): GameState {
            val initialTigers = when (level) {
                BoardLevel.PYRAMID -> listOf(
                    Piece(PieceType.TIGER, Position(0, 2), "tiger_0"),
                    Piece(PieceType.TIGER, Position(4, 0), "tiger_1"),
                    Piece(PieceType.TIGER, Position(4, 4), "tiger_2")
                )
                BoardLevel.SQUARE -> listOf(
                    Piece(PieceType.TIGER, Position(0, 0), "tiger_0"),
                    Piece(PieceType.TIGER, Position(0, 4), "tiger_1"),
                    Piece(PieceType.TIGER, Position(4, 0), "tiger_2"),
                    Piece(PieceType.TIGER, Position(4, 4), "tiger_3")
                )
                BoardLevel.TRADITIONAL -> listOf(
                    Piece(PieceType.TIGER, Position(0, 0), "tiger_0"),
                    Piece(PieceType.TIGER, Position(0, 4), "tiger_1"),
                    Piece(PieceType.TIGER, Position(4, 0), "tiger_2"),
                    Piece(PieceType.TIGER, Position(4, 4), "tiger_3"),
                    Piece(PieceType.TIGER, Position(2, 2), "tiger_4")
                )
            }

            val state = GameState(
                level = level,
                pieces = initialTigers,
                currentTurn = PlayerTurn.GOAT,
                phase = GamePhase.PLACEMENT,
                winner = GameWinner.NONE,
                drawReason = DrawReason.NONE,
                goatsPlaced = 0,
                goatsCaptured = 0,
                moveHistory = emptyList(),
                tigerTimeRemainingMillis = if (timer?.hasLimit == true) timer.durationMillis else null,
                goatTimeRemainingMillis = if (timer?.hasLimit == true) timer.durationMillis else null
            )
            return state.copy(positionHistory = mapOf(state.stateSignature to 1))
        }
    }
}
