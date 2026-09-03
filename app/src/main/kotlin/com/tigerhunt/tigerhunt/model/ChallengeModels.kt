package com.tigerhunt.tigerhunt.model

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

enum class ChallengeDifficulty(val level: Int, val displayName: String, val baseReward: Int, val coinReward: Int) {
    EASY(1, "Easy", 50, 80),
    MEDIUM(2, "Medium", 100, 150),
    HARD(3, "Hard", 200, 250),
    EXPERT(4, "Expert", 500, 400)
}

data class Puzzle(
    val id: String,
    val title: String,
    val description: String,
    val position: GameState,
    val playerRole: PieceType,
    val solution: List<Move>,
    val difficulty: ChallengeDifficulty,
    val rating: Int,
    val explanation: String,
    val coinReward: Int = difficulty.coinReward,
    val isDaily: Boolean = false
) {
    val sequenceLength: Int get() = solution.size
}

object DailyChallengeManager {
    fun getTodayDateString(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        return sdf.format(Date())
    }

    fun getDailyPuzzle(dateString: String = getTodayDateString()): Puzzle {
        val hash = kotlin.math.abs(dateString.hashCode())
        val index = hash % dailyChallengePool.size
        val basePuzzle = dailyChallengePool[index]
        return basePuzzle.copy(
            id = "daily_${dateString}_${basePuzzle.id}",
            title = "Daily Challenge: ${basePuzzle.title}",
            isDaily = true,
            coinReward = basePuzzle.difficulty.coinReward + 100 // Extra bonus for daily challenge
        )
    }

    fun calculateDailyStreakBonus(streak: Int): Int {
        return when {
            streak >= 30 -> 250
            streak >= 14 -> 150
            streak >= 7 -> 100
            streak >= 3 -> 50
            else -> 20
        }
    }

    fun getStreakMultiplier(streak: Int): Float {
        return when {
            streak >= 30 -> 2.5f
            streak >= 14 -> 2.0f
            streak >= 7 -> 1.5f
            streak >= 3 -> 1.25f
            else -> 1.0f
        }
    }

    val dailyChallengePool: List<Puzzle> by lazy {
        listOf(
            Puzzle(
                id = "daily_p1",
                title = "Apex Corral Strike",
                description = "2-Move Sequence: Force the apex tiger into an unescapable trap",
                position = GameState(
                    level = BoardLevel.TRADITIONAL,
                    pieces = listOf(
                        Piece(PieceType.TIGER, Position(0, 2), "t0"),
                        Piece(PieceType.TIGER, Position(4, 0), "t1"),
                        Piece(PieceType.TIGER, Position(4, 4), "t2"),
                        Piece(PieceType.GOAT, Position(1, 3), "g0"),
                        Piece(PieceType.GOAT, Position(2, 4), "g1"),
                        Piece(PieceType.GOAT, Position(2, 0), "g2"),
                        Piece(PieceType.GOAT, Position(2, 2), "g3")
                    ),
                    currentTurn = PlayerTurn.GOAT,
                    phase = GamePhase.MOVEMENT,
                    goatsPlaced = 20,
                    goatsCaptured = 0
                ),
                playerRole = PieceType.GOAT,
                solution = listOf(
                    Move(Position(2, 2), Position(1, 1), null, PieceType.GOAT)
                ),
                difficulty = ChallengeDifficulty.MEDIUM,
                rating = 1300,
                explanation = "Sliding into (1,1) cuts off the apex tiger's only remaining step, locking it down completely!"
            ),
            Puzzle(
                id = "daily_p2",
                title = "Himalayan Double Ricochet",
                description = "2-Move Sequence: Leap across diagonals to capture two goats in succession",
                position = GameState(
                    level = BoardLevel.TRADITIONAL,
                    pieces = listOf(
                        Piece(PieceType.TIGER, Position(4, 0), "t0"),
                        Piece(PieceType.TIGER, Position(0, 0), "t1"),
                        Piece(PieceType.TIGER, Position(0, 4), "t2"),
                        Piece(PieceType.GOAT, Position(3, 1), "g0"),
                        Piece(PieceType.GOAT, Position(3, 3), "g1")
                    ),
                    currentTurn = PlayerTurn.TIGER,
                    phase = GamePhase.MOVEMENT,
                    goatsPlaced = 20,
                    goatsCaptured = 0
                ),
                playerRole = PieceType.TIGER,
                solution = listOf(
                    Move(Position(4, 0), Position(2, 2), Position(3, 1), PieceType.TIGER),
                    Move(Position(2, 2), Position(4, 4), Position(3, 3), PieceType.TIGER)
                ),
                difficulty = ChallengeDifficulty.HARD,
                rating = 1500,
                explanation = "First leap into the central hub at (2,2) over (3,1), then ricochet down the second diagonal to (4,4) over (3,3)!"
            ),
            Puzzle(
                id = "daily_p3",
                title = "Center Sanctuary Shield",
                description = "Deploy the crucial central goat to block 4 potential jump lanes",
                position = GameState(
                    level = BoardLevel.TRADITIONAL,
                    pieces = listOf(
                        Piece(PieceType.TIGER, Position(0, 0), "t0"),
                        Piece(PieceType.TIGER, Position(0, 4), "t1"),
                        Piece(PieceType.TIGER, Position(4, 0), "t2"),
                        Piece(PieceType.TIGER, Position(4, 4), "t3"),
                        Piece(PieceType.GOAT, Position(1, 1), "g0"),
                        Piece(PieceType.GOAT, Position(1, 3), "g1"),
                        Piece(PieceType.GOAT, Position(3, 1), "g2")
                    ),
                    currentTurn = PlayerTurn.GOAT,
                    phase = GamePhase.PLACEMENT,
                    goatsPlaced = 3,
                    goatsCaptured = 0
                ),
                playerRole = PieceType.GOAT,
                solution = listOf(
                    Move(Position(-1, -1), Position(2, 2), null, PieceType.GOAT)
                ),
                difficulty = ChallengeDifficulty.EASY,
                rating = 950,
                explanation = "Dropping a goat at (2,2) locks the central nexus and stops tigers from penetrating the core of the board."
            ),
            Puzzle(
                id = "daily_p4",
                title = "Avalanche Triple Pounce",
                description = "3-Move Sequence: Execute a devastating 3-part tiger leap sequence",
                position = GameState(
                    level = BoardLevel.TRADITIONAL,
                    pieces = listOf(
                        Piece(PieceType.TIGER, Position(0, 0), "t0"),
                        Piece(PieceType.TIGER, Position(0, 4), "t1"),
                        Piece(PieceType.TIGER, Position(4, 0), "t2"),
                        Piece(PieceType.GOAT, Position(1, 1), "g0"),
                        Piece(PieceType.GOAT, Position(3, 3), "g1"),
                        Piece(PieceType.GOAT, Position(3, 4), "g2")
                    ),
                    currentTurn = PlayerTurn.TIGER,
                    phase = GamePhase.MOVEMENT,
                    goatsPlaced = 20,
                    goatsCaptured = 0
                ),
                playerRole = PieceType.TIGER,
                solution = listOf(
                    Move(Position(0, 0), Position(2, 2), Position(1, 1), PieceType.TIGER),
                    Move(Position(2, 2), Position(4, 4), Position(3, 3), PieceType.TIGER),
                    Move(Position(4, 4), Position(2, 4), Position(3, 4), PieceType.TIGER)
                ),
                difficulty = ChallengeDifficulty.EXPERT,
                rating = 1800,
                explanation = "Three consecutive leaping captures: (0,0)->(2,2) over (1,1), then (2,2)->(4,4) over (3,3), then (4,4)->(2,4) over (3,4)!"
            ),
            Puzzle(
                id = "daily_p5",
                title = "Flank Interlocking Citadel",
                description = "Reinforce the goat defensive perimeter to guard all flank entries",
                position = GameState(
                    level = BoardLevel.TRADITIONAL,
                    pieces = listOf(
                        Piece(PieceType.TIGER, Position(0, 2), "t0"),
                        Piece(PieceType.TIGER, Position(2, 0), "t1"),
                        Piece(PieceType.TIGER, Position(4, 2), "t2"),
                        Piece(PieceType.GOAT, Position(1, 1), "g0"),
                        Piece(PieceType.GOAT, Position(1, 2), "g1"),
                        Piece(PieceType.GOAT, Position(2, 1), "g2")
                    ),
                    currentTurn = PlayerTurn.GOAT,
                    phase = GamePhase.PLACEMENT,
                    goatsPlaced = 3,
                    goatsCaptured = 0
                ),
                playerRole = PieceType.GOAT,
                solution = listOf(
                    Move(Position(-1, -1), Position(2, 2), null, PieceType.GOAT)
                ),
                difficulty = ChallengeDifficulty.MEDIUM,
                rating = 1200,
                explanation = "Positioning a goat at (2,2) bonds all three nearby goats into a mutually defensive triangle."
            ),
            Puzzle(
                id = "daily_p6",
                title = "Final 5th Capture Blitz",
                description = "Deliver the match-ending 5th goat leap for an instant win",
                position = GameState(
                    level = BoardLevel.TRADITIONAL,
                    pieces = listOf(
                        Piece(PieceType.TIGER, Position(0, 0), "t0"),
                        Piece(PieceType.TIGER, Position(0, 4), "t1"),
                        Piece(PieceType.TIGER, Position(4, 0), "t2"),
                        Piece(PieceType.TIGER, Position(4, 4), "t3"),
                        Piece(PieceType.GOAT, Position(1, 1), "g0")
                    ),
                    currentTurn = PlayerTurn.TIGER,
                    phase = GamePhase.MOVEMENT,
                    goatsPlaced = 20,
                    goatsCaptured = 4
                ),
                playerRole = PieceType.TIGER,
                solution = listOf(
                    Move(Position(0, 0), Position(2, 2), Position(1, 1), PieceType.TIGER)
                ),
                difficulty = ChallengeDifficulty.HARD,
                rating = 1450,
                explanation = "Leaping over the solitary goat at (1,1) secures the decisive 5th capture!"
            ),
            Puzzle(
                id = "daily_p7",
                title = "Silent Sidestep Ambush",
                description = "2-Move Sequence: Sidestep to unblock the vertical strike alley",
                position = GameState(
                    level = BoardLevel.TRADITIONAL,
                    pieces = listOf(
                        Piece(PieceType.TIGER, Position(0, 0), "t0"),
                        Piece(PieceType.TIGER, Position(0, 4), "t1"),
                        Piece(PieceType.TIGER, Position(4, 0), "t2"),
                        Piece(PieceType.TIGER, Position(4, 4), "t3"),
                        Piece(PieceType.GOAT, Position(1, 1), "g0"),
                        Piece(PieceType.GOAT, Position(2, 2), "g1"),
                        Piece(PieceType.GOAT, Position(1, 2), "g2")
                    ),
                    currentTurn = PlayerTurn.TIGER,
                    phase = GamePhase.MOVEMENT,
                    goatsPlaced = 20,
                    goatsCaptured = 0
                ),
                playerRole = PieceType.TIGER,
                solution = listOf(
                    Move(Position(0, 0), Position(0, 1), null, PieceType.TIGER),
                    Move(Position(0, 1), Position(2, 1), Position(1, 1), PieceType.TIGER)
                ),
                difficulty = ChallengeDifficulty.MEDIUM,
                rating = 1250,
                explanation = "Stepping sideways to (0,1) unmasks a direct vertical line down to (2,1) over the goat at (1,1)!"
            )
        )
    }
}

object PuzzleLibrary {
    val allPuzzles: List<Puzzle> by lazy {
        beginnerPuzzles + intermediatePuzzles + advancedPuzzles
    }

    val beginnerPuzzles: List<Puzzle> = listOf(
        Puzzle(
            id = "puzzle_001",
            title = "First Capture",
            description = "Find the move to capture a goat",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(2, 2), "t0"),
                    Piece(PieceType.TIGER, Position(0, 4), "t1"),
                    Piece(PieceType.TIGER, Position(4, 0), "t2"),
                    Piece(PieceType.TIGER, Position(4, 4), "t3"),
                    Piece(PieceType.GOAT, Position(2, 3), "g0")
                ),
                currentTurn = PlayerTurn.TIGER,
                phase = GamePhase.MOVEMENT,
                goatsPlaced = 20,
                goatsCaptured = 0
            ),
            playerRole = PieceType.TIGER,
            solution = listOf(
                Move(Position(2, 2), Position(2, 4), Position(2, 3), PieceType.TIGER)
            ),
            difficulty = ChallengeDifficulty.EASY,
            rating = 800,
            explanation = "The tiger at (2,2) jumps horizontally over the goat at (2,3) to land on (2,4) and capture it!"
        ),
        Puzzle(
            id = "puzzle_002",
            title = "Double Threat",
            description = "Set up a position where tiger threatens multiple captures",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(1, 1), "t0"),
                    Piece(PieceType.TIGER, Position(0, 4), "t1"),
                    Piece(PieceType.TIGER, Position(4, 0), "t2"),
                    Piece(PieceType.TIGER, Position(4, 4), "t3"),
                    Piece(PieceType.GOAT, Position(2, 1), "g0"),
                    Piece(PieceType.GOAT, Position(2, 3), "g1"),
                    Piece(PieceType.GOAT, Position(1, 2), "g2")
                ),
                currentTurn = PlayerTurn.TIGER,
                phase = GamePhase.MOVEMENT,
                goatsPlaced = 20,
                goatsCaptured = 0
            ),
            playerRole = PieceType.TIGER,
            solution = listOf(
                Move(Position(1, 1), Position(2, 2), null, PieceType.TIGER)
            ),
            difficulty = ChallengeDifficulty.EASY,
            rating = 900,
            explanation = "Moving to the center intersection (2,2) creates multiple diagonal and orthogonal capture threats simultaneously!"
        ),
        Puzzle(
            id = "puzzle_003",
            title = "Corner Capture",
            description = "Jump over the goat guarding the corner diagonal",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(0, 4), "t0"),
                    Piece(PieceType.TIGER, Position(0, 0), "t1"),
                    Piece(PieceType.TIGER, Position(4, 0), "t2"),
                    Piece(PieceType.TIGER, Position(4, 4), "t3"),
                    Piece(PieceType.GOAT, Position(1, 3), "g0")
                ),
                currentTurn = PlayerTurn.TIGER,
                phase = GamePhase.MOVEMENT,
                goatsPlaced = 20,
                goatsCaptured = 0
            ),
            playerRole = PieceType.TIGER,
            solution = listOf(
                Move(Position(0, 4), Position(2, 2), Position(1, 3), PieceType.TIGER)
            ),
            difficulty = ChallengeDifficulty.EASY,
            rating = 850,
            explanation = "The tiger leaps along the diagonal line from (0,4) over (1,3) to land squarely in the center (2,2)!"
        ),
        Puzzle(
            id = "puzzle_004",
            title = "Straight Line",
            description = "Capture the goat directly down the left column",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(0, 0), "t0"),
                    Piece(PieceType.TIGER, Position(0, 4), "t1"),
                    Piece(PieceType.TIGER, Position(4, 0), "t2"),
                    Piece(PieceType.TIGER, Position(4, 4), "t3"),
                    Piece(PieceType.GOAT, Position(1, 0), "g0")
                ),
                currentTurn = PlayerTurn.TIGER,
                phase = GamePhase.MOVEMENT,
                goatsPlaced = 20,
                goatsCaptured = 0
            ),
            playerRole = PieceType.TIGER,
            solution = listOf(
                Move(Position(0, 0), Position(2, 0), Position(1, 0), PieceType.TIGER)
            ),
            difficulty = ChallengeDifficulty.EASY,
            rating = 850,
            explanation = "A straight vertical jump from (0,0) over (1,0) to (2,0) captures the edge goat cleanly."
        ),
        Puzzle(
            id = "puzzle_005",
            title = "Smart Start",
            description = "Claim the strategic centre square with your first goat",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(0, 0), "t0"),
                    Piece(PieceType.TIGER, Position(0, 4), "t1"),
                    Piece(PieceType.TIGER, Position(4, 0), "t2"),
                    Piece(PieceType.TIGER, Position(4, 4), "t3"),
                    Piece(PieceType.GOAT, Position(1, 1), "g0"),
                    Piece(PieceType.GOAT, Position(1, 3), "g1")
                ),
                currentTurn = PlayerTurn.GOAT,
                phase = GamePhase.PLACEMENT,
                goatsPlaced = 2,
                goatsCaptured = 0
            ),
            playerRole = PieceType.GOAT,
            solution = listOf(
                Move(Position(-1, -1), Position(2, 2), null, PieceType.GOAT)
            ),
            difficulty = ChallengeDifficulty.EASY,
            rating = 750,
            explanation = "The centre (2,2) is the most powerful hub on the board. Controlling it blocks tiger mobility across 8 distinct lines!"
        )
    )

    val intermediatePuzzles: List<Puzzle> = listOf(
        Puzzle(
            id = "puzzle_101",
            title = "Escape the Trap",
            description = "Find the only escape move that keeps the tiger mobile",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(0, 0), "t0"),
                    Piece(PieceType.TIGER, Position(2, 2), "t1"),
                    Piece(PieceType.TIGER, Position(4, 0), "t2"),
                    Piece(PieceType.TIGER, Position(4, 4), "t3"),
                    Piece(PieceType.GOAT, Position(0, 1), "g0"),
                    Piece(PieceType.GOAT, Position(1, 0), "g1"),
                    Piece(PieceType.GOAT, Position(0, 2), "g2"),
                    Piece(PieceType.GOAT, Position(2, 0), "g3")
                ),
                currentTurn = PlayerTurn.TIGER,
                phase = GamePhase.MOVEMENT,
                goatsPlaced = 20,
                goatsCaptured = 0
            ),
            playerRole = PieceType.TIGER,
            solution = listOf(
                Move(Position(0, 0), Position(1, 1), null, PieceType.TIGER)
            ),
            difficulty = ChallengeDifficulty.MEDIUM,
            rating = 1250,
            explanation = "Moving along the diagonal to (1,1) is the only unblocked route to escape total corner encirclement!"
        ),
        Puzzle(
            id = "puzzle_102",
            title = "Boomerang Strike",
            description = "Execute a two-turn double diagonal assault",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(4, 0), "t0"),
                    Piece(PieceType.TIGER, Position(0, 0), "t1"),
                    Piece(PieceType.TIGER, Position(0, 4), "t2"),
                    Piece(PieceType.GOAT, Position(3, 1), "g0"),
                    Piece(PieceType.GOAT, Position(3, 3), "g1")
                ),
                currentTurn = PlayerTurn.TIGER,
                phase = GamePhase.MOVEMENT,
                goatsPlaced = 20,
                goatsCaptured = 0
            ),
            playerRole = PieceType.TIGER,
            solution = listOf(
                Move(Position(4, 0), Position(2, 2), Position(3, 1), PieceType.TIGER),
                Move(Position(2, 2), Position(4, 4), Position(3, 3), PieceType.TIGER)
            ),
            difficulty = ChallengeDifficulty.MEDIUM,
            rating = 1350,
            explanation = "The tiger sweeps diagonally to the centre, then ricochets down the opposing diagonal for a double harvest!"
        ),
        Puzzle(
            id = "puzzle_103",
            title = "Patient Hunter",
            description = "Direct jump is guarded — sidestep to unlock the attack",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(0, 0), "t0"),
                    Piece(PieceType.TIGER, Position(0, 4), "t1"),
                    Piece(PieceType.TIGER, Position(4, 0), "t2"),
                    Piece(PieceType.TIGER, Position(4, 4), "t3"),
                    Piece(PieceType.GOAT, Position(1, 1), "g0"),
                    Piece(PieceType.GOAT, Position(2, 2), "g1"),
                    Piece(PieceType.GOAT, Position(1, 2), "g2")
                ),
                currentTurn = PlayerTurn.TIGER,
                phase = GamePhase.MOVEMENT,
                goatsPlaced = 20,
                goatsCaptured = 0
            ),
            playerRole = PieceType.TIGER,
            solution = listOf(
                Move(Position(0, 0), Position(0, 1), null, PieceType.TIGER),
                Move(Position(0, 1), Position(2, 1), Position(1, 1), PieceType.TIGER)
            ),
            difficulty = ChallengeDifficulty.MEDIUM,
            rating = 1200,
            explanation = "The direct jump to (2,2) is occupied. Stepping to (0,1) opens a vertical attack lane down to (2,1)!"
        )
    )

    val advancedPuzzles: List<Puzzle> = listOf(
        Puzzle(
            id = "puzzle_201",
            title = "The Perfect Trap",
            description = "Place a goat to completely immobilize the remaining tiger",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(0, 0), "t0"),
                    Piece(PieceType.TIGER, Position(2, 2), "t1"),
                    Piece(PieceType.TIGER, Position(4, 0), "t2"),
                    Piece(PieceType.TIGER, Position(4, 4), "t3"),
                    Piece(PieceType.GOAT, Position(0, 1), "g0"),
                    Piece(PieceType.GOAT, Position(1, 0), "g1"),
                    Piece(PieceType.GOAT, Position(1, 1), "g2")
                ),
                currentTurn = PlayerTurn.GOAT,
                phase = GamePhase.PLACEMENT,
                goatsPlaced = 3,
                goatsCaptured = 0
            ),
            playerRole = PieceType.GOAT,
            solution = listOf(
                Move(Position(-1, -1), Position(1, 2), null, PieceType.GOAT)
            ),
            difficulty = ChallengeDifficulty.HARD,
            rating = 1550,
            explanation = "Placing a goat on (1,2) cuts off the secondary escape corridor, sealing the tiger in a completely immovable quadrant!"
        ),
        Puzzle(
            id = "puzzle_202",
            title = "Final Victory Strike",
            description = "Capture the 5th goat to claim instant match victory",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(0, 0), "t0"),
                    Piece(PieceType.TIGER, Position(0, 4), "t1"),
                    Piece(PieceType.TIGER, Position(4, 0), "t2"),
                    Piece(PieceType.TIGER, Position(4, 4), "t3"),
                    Piece(PieceType.GOAT, Position(1, 1), "g0")
                ),
                currentTurn = PlayerTurn.TIGER,
                phase = GamePhase.MOVEMENT,
                goatsPlaced = 20,
                goatsCaptured = 4
            ),
            playerRole = PieceType.TIGER,
            solution = listOf(
                Move(Position(0, 0), Position(2, 2), Position(1, 1), PieceType.TIGER)
            ),
            difficulty = ChallengeDifficulty.HARD,
            rating = 1500,
            explanation = "With 4 goats already captured, leaping into (2,2) over (1,1) delivers the 5th capture and ends the game!"
        ),
        Puzzle(
            id = "puzzle_203",
            title = "Mastermind Triple Chain",
            description = "Execute a devastating 3-part capture sequence",
            position = GameState(
                level = BoardLevel.TRADITIONAL,
                pieces = listOf(
                    Piece(PieceType.TIGER, Position(0, 0), "t0"),
                    Piece(PieceType.TIGER, Position(0, 4), "t1"),
                    Piece(PieceType.TIGER, Position(4, 0), "t2"),
                    Piece(PieceType.GOAT, Position(1, 1), "g0"),
                    Piece(PieceType.GOAT, Position(3, 3), "g1"),
                    Piece(PieceType.GOAT, Position(3, 4), "g2")
                ),
                currentTurn = PlayerTurn.TIGER,
                phase = GamePhase.MOVEMENT,
                goatsPlaced = 20,
                goatsCaptured = 0
            ),
            playerRole = PieceType.TIGER,
            solution = listOf(
                Move(Position(0, 0), Position(2, 2), Position(1, 1), PieceType.TIGER),
                Move(Position(2, 2), Position(4, 4), Position(3, 3), PieceType.TIGER),
                Move(Position(4, 4), Position(2, 4), Position(3, 4), PieceType.TIGER)
            ),
            difficulty = ChallengeDifficulty.EXPERT,
            rating = 1750,
            explanation = "A triple chain pounce: diagonal to (2,2), diagonal to (4,4), then vertical sweep back to (2,4) captures 3 goats!"
        )
    )
}
