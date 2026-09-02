package com.tigerhunt.tigerhunt.engine

import com.tigerhunt.tigerhunt.model.*
import kotlin.math.abs

class GameEngine(val level: BoardLevel) {
    val connections: BoardConnections = BoardConnections(level)

    fun getValidMoves(state: GameState): List<Move> {
        if (state.isGameOver) return emptyList()

        val rawMoves = if (state.currentTurn == PlayerTurn.GOAT) {
            getGoatMoves(state)
        } else {
            getTigerMoves(state)
        }

        return filterAntiOscillationMoves(state, rawMoves)
    }

    fun getGoatMoves(state: GameState): List<Move> {
        val moves = mutableListOf<Move>()

        if (state.phase == GamePhase.PLACEMENT) {
            for (pos in connections.allPositions) {
                if (state.isPositionEmpty(pos)) {
                    moves.add(
                        Move(
                            from = Position(-1, -1),
                            to = pos,
                            pieceType = PieceType.GOAT
                        )
                    )
                }
            }
        } else {
            for (goat in state.goatsOnBoard) {
                if (state.isGoatStunned(goat.position)) continue

                for (neighbor in connections.getNeighbors(goat.position)) {
                    if (state.isPositionEmpty(neighbor)) {
                        moves.add(
                            Move(
                                from = goat.position,
                                to = neighbor,
                                pieceType = PieceType.GOAT
                            )
                        )
                    }
                }
            }
        }
        return moves
    }

    fun getTigerMoves(state: GameState): List<Move> {
        val moves = mutableListOf<Move>()

        for (tiger in state.tigers) {
            for (neighbor in connections.getNeighbors(tiger.position)) {
                if (state.isPositionEmpty(neighbor)) {
                    moves.add(
                        Move(
                            from = tiger.position,
                            to = neighbor,
                            pieceType = PieceType.TIGER
                        )
                    )
                } else {
                    val pieceAtNeighbor = state.getPieceAt(neighbor)
                    val isShielded = state.isGoatShielded(neighbor)
                    if (pieceAtNeighbor?.type == PieceType.GOAT && !isShielded) {
                        val jumpDest = connections.getJumpDestination(tiger.position, neighbor)
                        if (jumpDest != null && state.isPositionEmpty(jumpDest)) {
                            moves.add(
                                Move(
                                    from = tiger.position,
                                    to = jumpDest,
                                    capturedAt = neighbor,
                                    pieceType = PieceType.TIGER
                                )
                            )
                        }
                    }
                }
            }
        }
        return moves
    }

    private fun filterAntiOscillationMoves(state: GameState, moves: List<Move>): List<Move> {
        if (moves.size <= 1 || state.moveHistory.size < 4) return moves

        val history = state.moveHistory
        val playerMoves = history.filter {
            it.pieceType == if (state.currentTurn == PlayerTurn.TIGER) PieceType.TIGER else PieceType.GOAT
        }

        if (playerMoves.size < 2) return moves

        val last = playerMoves[playerMoves.size - 1]
        val secondLast = playerMoves[playerMoves.size - 2]

        if (last.to == secondLast.from && last.from == secondLast.to) {
            val nonRepeating = moves.filter { !(it.from == last.to && it.to == last.from) }
            if (nonRepeating.isNotEmpty()) return nonRepeating
        }

        return moves
    }

    fun isValidMove(state: GameState, move: Move): Boolean {
        val validMoves = getValidMoves(state)
        return validMoves.any {
            it.from == move.from && it.to == move.to && it.capturedAt == move.capturedAt
        }
    }

    fun executeMove(state: GameState, move: Move): GameState {
        val newPieces = state.pieces.toMutableList()
        var newGoatsPlaced = state.goatsPlaced
        var newGoatsCaptured = state.goatsCaptured
        var newPhase = state.phase
        val newHistory = state.moveHistory + move
        var newMovesWithoutCapture = state.movesWithoutCapture

        if (move.pieceType == PieceType.GOAT) {
            if (move.isPlacement) {
                newPieces.add(
                    Piece(
                        type = PieceType.GOAT,
                        position = move.to,
                        id = "goat_$newGoatsPlaced"
                    )
                )
                newGoatsPlaced++
                newMovesWithoutCapture = 0

                if (newGoatsPlaced >= state.level.goatCount) {
                    newPhase = GamePhase.MOVEMENT
                }
            } else {
                val goatIndex = newPieces.indexOfFirst {
                    it.position == move.from && it.type == PieceType.GOAT && !it.isCaptured
                }
                if (goatIndex >= 0) {
                    newPieces[goatIndex] = newPieces[goatIndex].copy(position = move.to)
                }
                if (newPhase == GamePhase.MOVEMENT) {
                    newMovesWithoutCapture++
                }
            }
        } else {
            val tigerIndex = newPieces.indexOfFirst {
                it.position == move.from && it.type == PieceType.TIGER && !it.isCaptured
            }
            if (tigerIndex >= 0) {
                newPieces[tigerIndex] = newPieces[tigerIndex].copy(position = move.to)
            }

            if (move.isCapture) {
                val goatIndex = newPieces.indexOfFirst {
                    it.position == move.capturedAt && it.type == PieceType.GOAT && !it.isCaptured
                }
                if (goatIndex >= 0) {
                    newPieces[goatIndex] = newPieces[goatIndex].copy(isCaptured = true)
                    newGoatsCaptured++
                    newMovesWithoutCapture = 0
                }
            } else {
                if (newPhase == GamePhase.MOVEMENT) {
                    newMovesWithoutCapture++
                }
            }
        }

        val updatedEffects = mutableListOf<ActiveEffect>()
        for (effect in state.activeEffects) {
            if (effect.appliedBy == state.currentTurn) {
                val rem = effect.turnsRemaining - 1
                if (rem > 0) {
                    updatedEffects.add(effect.copy(turnsRemaining = rem))
                }
            } else {
                updatedEffects.add(effect)
            }
        }

        val nextTurn = if (state.currentTurn == PlayerTurn.GOAT) PlayerTurn.TIGER else PlayerTurn.GOAT

        var newState = state.copy(
            pieces = newPieces,
            currentTurn = nextTurn,
            phase = newPhase,
            goatsPlaced = newGoatsPlaced,
            goatsCaptured = newGoatsCaptured,
            moveHistory = newHistory,
            movesWithoutCapture = newMovesWithoutCapture,
            activeEffects = updatedEffects
        )

        val sig = newState.stateSignature
        val updatedHistory = HashMap(state.positionHistory)
        updatedHistory[sig] = (updatedHistory[sig] ?: 0) + 1
        newState = newState.copy(positionHistory = updatedHistory)

        return checkWinner(newState)
    }

    fun applyPowerUp(state: GameState, powerUp: PowerUpType, target: Position): GameState {
        val used = HashMap<PlayerTurn, Set<PowerUpType>>(state.usedPowerUps)
        val currentUsed = HashSet(used[state.currentTurn] ?: emptySet())
        currentUsed.add(powerUp)
        used[state.currentTurn] = currentUsed

        val turns = when (powerUp) {
            PowerUpType.TIGER_ROAR -> 1
            PowerUpType.HORN_SHIELD -> 2
            PowerUpType.BOULDER -> 3
            PowerUpType.SUPER_POUNCE -> 1
        }

        val effect = ActiveEffect(
            type = powerUp,
            targetPosition = target,
            turnsRemaining = turns,
            appliedBy = state.currentTurn
        )

        return state.copy(
            activeEffects = state.activeEffects + effect,
            usedPowerUps = used
        )
    }

    fun triggerArenaCollapse(state: GameState, collapsing: Set<Position>): GameState {
        val newCollapsed = state.collapsedPositions + collapsing
        val newPieces = mutableListOf<Piece>()
        val occupiedPositions = state.pieces.filter { !it.isCaptured && !collapsing.contains(it.position) }.map { it.position }.toMutableSet()

        for (piece in state.pieces) {
            if (piece.isCaptured) {
                newPieces.add(piece)
                continue
            }
            if (collapsing.contains(piece.position)) {
                val validNeighbors = connections.getNeighbors(piece.position)
                    .filter { !newCollapsed.contains(it) && !occupiedPositions.contains(it) }

                var targetPos = validNeighbors.firstOrNull()
                if (targetPos == null) {
                    val centerRow = (connections.level.rows - 1) / 2f
                    val centerCol = (connections.level.cols - 1) / 2f
                    val allSafe = connections.allPositions.filter { !newCollapsed.contains(it) && !occupiedPositions.contains(it) }
                        .sortedBy { abs(it.row - centerRow) + abs(it.col - centerCol) }
                    targetPos = allSafe.firstOrNull()
                }

                val safePos = targetPos ?: piece.position
                occupiedPositions.add(safePos)
                newPieces.add(piece.copy(position = safePos))
            } else {
                newPieces.add(piece)
            }
        }

        val newState = state.copy(
            pieces = newPieces,
            collapsedPositions = newCollapsed
        )
        return checkWinner(newState)
    }

    private fun checkWinner(state: GameState): GameState {
        if (state.goatsCaptured >= state.level.goatsToWin) {
            return state.copy(winner = GameWinner.TIGERS, phase = GamePhase.ENDED)
        }

        val sig = state.stateSignature
        if ((state.positionHistory[sig] ?: 0) >= 3) {
            return state.copy(
                winner = GameWinner.DRAW,
                drawReason = DrawReason.THREEFOLD_REPETITION,
                phase = GamePhase.ENDED
            )
        }

        if (state.phase == GamePhase.MOVEMENT && state.movesWithoutCapture >= 40) {
            return state.copy(
                winner = GameWinner.DRAW,
                drawReason = DrawReason.STAGNATION,
                phase = GamePhase.ENDED
            )
        }

        val tigerMoves = getTigerMoves(state.copy(currentTurn = PlayerTurn.TIGER))
        if (tigerMoves.isEmpty() && state.tigers.isNotEmpty()) {
            return state.copy(winner = GameWinner.GOATS, phase = GamePhase.ENDED)
        }

        return state
    }

    fun countMobileTigers(state: GameState): Int {
        var count = 0
        for (tiger in state.tigers) {
            var canMove = false
            for (neighbor in connections.getNeighbors(tiger.position)) {
                if (state.isPositionEmpty(neighbor)) {
                    canMove = true
                    break
                }
                val piece = state.getPieceAt(neighbor)
                val isShielded = state.isGoatShielded(neighbor)
                if (piece?.type == PieceType.GOAT && !isShielded) {
                    val jumpDest = connections.getJumpDestination(tiger.position, neighbor)
                    if (jumpDest != null && state.isPositionEmpty(jumpDest)) {
                        canMove = true
                        break
                    }
                }
            }
            if (canMove) count++
        }
        return count
    }
}
