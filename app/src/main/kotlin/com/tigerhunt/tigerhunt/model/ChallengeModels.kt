package com.tigerhunt.tigerhunt.model

enum class ChallengeDifficulty(val level: Int, val displayName: String, val baseReward: Int) {
    EASY(1, "Easy", 50),
    MEDIUM(2, "Medium", 100),
    HARD(3, "Hard", 200),
    EXPERT(4, "Expert", 500)
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
    val explanation: String
)

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
