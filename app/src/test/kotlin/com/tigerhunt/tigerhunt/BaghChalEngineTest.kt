package com.tigerhunt.tigerhunt

import com.tigerhunt.tigerhunt.engine.AIEngine
import com.tigerhunt.tigerhunt.engine.GameEngine
import com.tigerhunt.tigerhunt.model.*
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test

class BaghChalEngineTest {

    @Test
    fun testBoardTopologies() {
        for (level in BoardLevel.values()) {
            val engine = GameEngine(level)
            val connections = engine.connections
            assertTrue("Should have positions on board", connections.allPositions.isNotEmpty())

            // Test symmetry of neighbors
            for (pos in connections.allPositions) {
                val neighbors = connections.getNeighbors(pos)
                for (neighbor in neighbors) {
                    assertTrue(
                        "Neighbor relationship must be symmetric between $pos and $neighbor",
                        connections.getNeighbors(neighbor).contains(pos)
                    )
                }
            }
        }
    }

    @Test
    fun testInitialGameState() {
        val initialSquare = GameState.initial(BoardLevel.SQUARE)
        assertEquals(4, initialSquare.tigers.size)
        assertEquals(0, initialSquare.goatsOnBoard.size)
        assertEquals(0, initialSquare.goatsPlaced)
        assertEquals(GamePhase.PLACEMENT, initialSquare.phase)
        assertEquals(PlayerTurn.GOAT, initialSquare.currentTurn)

        val initialTrad = GameState.initial(BoardLevel.TRADITIONAL)
        assertEquals(5, initialTrad.tigers.size)
        assertEquals(20, initialTrad.level.goatCount)

        val initialPyramid = GameState.initial(BoardLevel.PYRAMID)
        assertEquals(3, initialPyramid.tigers.size)
        assertEquals(15, initialPyramid.level.goatCount)
    }

    @Test
    fun testGoatPlacementAndPhaseTransition() {
        val engine = GameEngine(BoardLevel.PYRAMID) // 15 goats
        var state = GameState.initial(BoardLevel.PYRAMID)

        val emptyPositions = engine.connections.allPositions.filter { state.isPositionEmpty(it) }
        assertTrue("Must have empty positions to place goats", emptyPositions.size >= 15)

        // Place all 15 goats
        for (i in 0 until 15) {
            assertEquals(GamePhase.PLACEMENT, state.phase)
            assertEquals(PlayerTurn.GOAT, state.currentTurn)

            val validMoves = engine.getValidMoves(state)
            assertTrue("Goat should have valid placement moves", validMoves.isNotEmpty())
            val placeMove = validMoves.first { it.isPlacement }
            state = engine.executeMove(state, placeMove)

            // Make Tiger move
            assertEquals(PlayerTurn.TIGER, state.currentTurn)
            val tigerMoves = engine.getValidMoves(state)
            if (tigerMoves.isNotEmpty()) {
                state = engine.executeMove(state, tigerMoves.first())
            }
        }

        // After placing 15 goats, phase should transition to MOVEMENT
        assertEquals(15, state.goatsPlaced)
        assertEquals(GamePhase.MOVEMENT, state.phase)
    }

    @Test
    fun testTigerJumpAndCapture() {
        val engine = GameEngine(BoardLevel.SQUARE)

        // Set up a custom state where Tiger at (0,0), Goat at (0,1), and (0,2) is empty
        val pieces = listOf(
            Piece(PieceType.TIGER, Position(0, 0), "tiger_0"),
            Piece(PieceType.GOAT, Position(0, 1), "goat_0")
        )

        val customState = GameState(
            pieces = pieces,
            level = BoardLevel.SQUARE,
            currentTurn = PlayerTurn.TIGER,
            phase = GamePhase.MOVEMENT,
            goatsPlaced = 16,
            goatsCaptured = 0
        )

        val tigerMoves = engine.getTigerMoves(customState)
        val captureMove = tigerMoves.firstOrNull { it.isCapture }

        assertNotNull("Tiger should find a capture jump over goat at (0,1)", captureMove)
        assertEquals(Position(0, 0), captureMove!!.from)
        assertEquals(Position(0, 2), captureMove.to)
        assertEquals(Position(0, 1), captureMove.capturedAt)

        val nextState = engine.executeMove(customState, captureMove)
        assertEquals(1, nextState.goatsCaptured)
        val capturedPiece = nextState.pieces.first { it.id == "goat_0" }
        assertTrue("Goat should be marked captured", capturedPiece.isCaptured)
        assertTrue("Tiger should have moved to (0,2)", nextState.pieces.any { it.type == PieceType.TIGER && it.position == Position(0, 2) })
    }

    @Test
    fun testTigerVictoryCondition() {
        val engine = GameEngine(BoardLevel.SQUARE)

        // State with 4 goats already captured, and 1 more capture available
        val pieces = listOf(
            Piece(PieceType.TIGER, Position(0, 0), "tiger_0"),
            Piece(PieceType.GOAT, Position(0, 1), "goat_0")
        )

        val state = GameState(
            pieces = pieces,
            level = BoardLevel.SQUARE,
            currentTurn = PlayerTurn.TIGER,
            phase = GamePhase.MOVEMENT,
            goatsPlaced = 16,
            goatsCaptured = 4 // 4 captured so far, 5th will trigger win
        )

        val captureMove = Move(
            from = Position(0, 0),
            to = Position(0, 2),
            capturedAt = Position(0, 1),
            pieceType = PieceType.TIGER
        )

        val endState = engine.executeMove(state, captureMove)
        assertEquals(5, endState.goatsCaptured)
        assertEquals(GameWinner.TIGERS, endState.winner)
        assertEquals(GamePhase.ENDED, endState.phase)
        assertTrue(endState.isGameOver)
    }

    @Test
    fun testGoatVictoryConditionWhenTigersTrapped() {
        val engine = GameEngine(BoardLevel.SQUARE)

        // 1 Tiger cornered at (0,0) surrounded by goats with no jump landing available
        val pieces = listOf(
            Piece(PieceType.TIGER, Position(0, 0), "tiger_0"),
            Piece(PieceType.GOAT, Position(0, 1), "goat_1"),
            Piece(PieceType.GOAT, Position(0, 2), "goat_2"),
            Piece(PieceType.GOAT, Position(1, 0), "goat_3"),
            Piece(PieceType.GOAT, Position(2, 0), "goat_4"),
            Piece(PieceType.GOAT, Position(1, 1), "goat_5"),
            Piece(PieceType.GOAT, Position(2, 2), "goat_6")
        )

        val state = GameState(
            pieces = pieces,
            level = BoardLevel.SQUARE,
            currentTurn = PlayerTurn.GOAT,
            phase = GamePhase.MOVEMENT,
            goatsPlaced = 16,
            goatsCaptured = 0
        )

        // Count mobile tigers
        assertEquals(0, engine.countMobileTigers(state))

        // When tiger has turn and zero moves, goat wins
        val tigerTurnState = state.copy(currentTurn = PlayerTurn.TIGER)
        val validTigerMoves = engine.getValidMoves(tigerTurnState)
        assertEquals(0, validTigerMoves.size)
    }

    @Test
    fun testAIEngineComputesValidMoves() = runBlocking {
        val engine = GameEngine(BoardLevel.SQUARE)
        val ai = AIEngine(engine, AIDifficulty.EASY)
        val state = GameState.initial(BoardLevel.SQUARE)

        // Test AI as Goat during placement
        val goatAIMove = ai.getBestMove(state)
        assertNotNull("AI should find a placement move as Goat", goatAIMove)
        assertTrue(goatAIMove!!.isPlacement)

        // Test AI as Tiger
        val stateWithTigerTurn = state.copy(currentTurn = PlayerTurn.TIGER)
        val tigerAI = AIEngine(engine, AIDifficulty.MEDIUM)
        val tigerAIMove = tigerAI.getBestMove(stateWithTigerTurn)
        assertNotNull("AI should find a valid move as Tiger", tigerAIMove)
        assertEquals(PieceType.TIGER, tigerAIMove!!.pieceType)
    }

    @Test
    fun testPuzzleLibraryIntegrity() {
        val puzzles = PuzzleLibrary.allPuzzles
        assertTrue("Puzzle library should not be empty", puzzles.isNotEmpty())

        for (puzzle in puzzles) {
            assertNotNull("Puzzle ID cannot be null", puzzle.id)
            assertTrue("Puzzle title cannot be blank", puzzle.title.isNotBlank())
            assertTrue("Puzzle must have pieces", puzzle.position.pieces.isNotEmpty())
            assertTrue("Puzzle solution cannot be empty", puzzle.solution.isNotEmpty())
            assertEquals("Puzzle turn must match playerRole", puzzle.playerRole.name, puzzle.position.currentTurn.name)
        }
    }

    @Test
    fun testUserProfileAuthMethods() {
        val guest = UserProfile(
            id = "guest_123",
            username = "Guest Player",
            authMethod = AuthMethod.GUEST,
            isLoggedIn = false
        )
        assertFalse(guest.isLoggedIn)
        assertEquals(AuthMethod.GUEST, guest.authMethod)

        val googleUser = guest.copy(
            id = "google_alok",
            username = "Alok Pradhan",
            email = "alokpradhan1989@gmail.com",
            authMethod = AuthMethod.GMAIL,
            isLoggedIn = true
        )
        assertTrue(googleUser.isLoggedIn)
        assertEquals("alokpradhan1989@gmail.com", googleUser.email)
        assertEquals(AuthMethod.GMAIL, googleUser.authMethod)

        val phoneUser = guest.copy(
            id = "phone_981234",
            username = "Mobile Hunter",
            phoneNumber = "+977 9812345678",
            authMethod = AuthMethod.PHONE,
            isLoggedIn = true
        )
        assertTrue(phoneUser.isLoggedIn)
        assertEquals("+977 9812345678", phoneUser.phoneNumber)
        assertEquals(AuthMethod.PHONE, phoneUser.authMethod)
    }
}
