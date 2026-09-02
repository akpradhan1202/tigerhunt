package com.tigerhunt.tigerhunt.model

import kotlin.math.abs

/**
 * Represents a discrete coordinate position on the game board.
 */
data class Position(val row: Int, val col: Int) {
    operator fun plus(other: Position) = Position(row + other.row, col + other.col)
    operator fun minus(other: Position) = Position(row - other.row, col - other.col)
    operator fun times(scalar: Int) = Position(row * scalar, col * scalar)

    fun isAdjacentTo(other: Position): Boolean {
        val dx = abs(col - other.col)
        val dy = abs(row - other.row)
        return dx <= 1 && dy <= 1 && (dx + dy > 0)
    }

    override fun toString(): String = "($row, $col)"
}

enum class PieceType(val displayName: String) {
    TIGER("Tiger"),
    GOAT("Goat")
}

enum class PlayerTurn(val displayName: String) {
    TIGER("Tiger"),
    GOAT("Goat")
}

data class Piece(
    val type: PieceType,
    val position: Position,
    val id: String,
    val isCaptured: Boolean = false
)

data class Move(
    val from: Position,
    val to: Position,
    val capturedAt: Position? = null,
    val pieceType: PieceType
) {
    val isCapture: Boolean get() = capturedAt != null
    val isPlacement: Boolean get() = from == Position(-1, -1)
}

enum class AIDifficulty(
    val displayName: String,
    val depth: Int,
    val description: String,
    val rating: Int
) {
    EASY("Easy", 1, "For beginners and learners", 800),
    MEDIUM("Medium", 2, "Balanced tactical play", 1200),
    HARD("Hard", 3, "Challenging aggressive hunter", 1600),
    EXPERT("Expert", 4, "Grandmaster Bagh-Chal AI", 2000)
}

enum class BoardLevel(
    val displayName: String,
    val description: String,
    val rows: Int,
    val cols: Int,
    val tigerCount: Int,
    val goatCount: Int,
    val goatsToWin: Int
) {
    PYRAMID(
        displayName = "Pyramid",
        description = "Beginner - Triangle Board (3 Tigers, 15 Goats)",
        rows = 5,
        cols = 5,
        tigerCount = 3,
        goatCount = 15,
        goatsToWin = 5
    ),
    SQUARE(
        displayName = "Square",
        description = "Intermediate - 5x5 Grid with Diagonals (4 Tigers, 16 Goats)",
        rows = 5,
        cols = 5,
        tigerCount = 4,
        goatCount = 16,
        goatsToWin = 5
    ),
    TRADITIONAL(
        displayName = "Traditional",
        description = "Advanced - Full Bagh-Chal with 4 Fan Extensions (5 Tigers, 20 Goats)",
        rows = 5,
        cols = 5,
        tigerCount = 5,
        goatCount = 20,
        goatsToWin = 5
    )
}

enum class GameTimer(
    val minutes: Int,
    val incrementSeconds: Int,
    val label: String
) {
    BULLET(1, 2, "1 min (+2s)"),
    BLITZ(3, 2, "3 min (+2s)"),
    RAPID(5, 3, "5 min (+3s)"),
    CLASSIC(10, 5, "10 min (+5s)"),
    UNLIMITED(0, 0, "No Limit");

    val hasLimit: Boolean get() = minutes > 0
    val durationMillis: Long get() = minutes * 60 * 1000L
    val incrementMillis: Long get() = incrementSeconds * 1000L
}

enum class PowerUpType(
    val displayName: String,
    val description: String,
    val icon: String,
    val turn: PlayerTurn
) {
    TIGER_ROAR("Tiger Roar", "Freezes an adjacent goat for 1 turn", "⚡", PlayerTurn.TIGER),
    SUPER_POUNCE("Super Pounce", "Leap over an empty intersection (distance 2)", "🐆", PlayerTurn.TIGER),
    HORN_SHIELD("Horn Shield", "Shields a goat from capture for 2 turns", "🛡️", PlayerTurn.GOAT),
    BOULDER("Boulder", "Place a rock blocking an intersection for 3 turns", "🪨", PlayerTurn.GOAT)
}

data class ActiveEffect(
    val type: PowerUpType,
    val targetPosition: Position,
    val turnsRemaining: Int,
    val appliedBy: PlayerTurn
)

enum class DrawReason {
    NONE,
    AGREEMENT,
    THREEFOLD_REPETITION,
    STAGNATION,
    TIMEOUT
}

enum class GameMode(val displayName: String, val description: String) {
    VS_AI("vs AI", "Play against intelligent Bagh-Chal bot"),
    PASS_AND_PLAY("Pass & Play", "Local 2-player on the same device"),
    PUZZLES("Puzzles & Tactics", "Solve tactical board scenarios"),
    TOURNAMENT("Tournament", "Championship bracket elimination"),
    TUTORIAL("Learn to Play", "Interactive step-by-step tutorial")
}
