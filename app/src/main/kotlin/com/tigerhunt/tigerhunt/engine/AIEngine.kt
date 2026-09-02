package com.tigerhunt.tigerhunt.engine

import com.tigerhunt.tigerhunt.model.*
import kotlinx.coroutines.delay
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

class AIEngine(
    val gameEngine: GameEngine,
    val difficulty: AIDifficulty
) {
    private val random = Random(System.currentTimeMillis())

    suspend fun getBestMove(state: GameState): Move? {
        val validMoves = gameEngine.getValidMoves(state)
        if (validMoves.isEmpty()) return null

        if (difficulty == AIDifficulty.EASY && random.nextFloat() < 0.35f) {
            return validMoves.random(random)
        }

        var bestMove: Move? = null
        var bestScore = if (state.currentTurn == PlayerTurn.TIGER) -99999 else 99999
        val shuffledMoves = validMoves.shuffled(random)

        for (move in shuffledMoves) {
            val newState = gameEngine.executeMove(state, move)
            val score = minimax(
                newState,
                difficulty.depth - 1,
                -99999,
                99999,
                state.currentTurn == PlayerTurn.GOAT
            )

            if (state.currentTurn == PlayerTurn.TIGER) {
                if (score > bestScore) {
                    bestScore = score
                    bestMove = move
                }
            } else {
                if (score < bestScore) {
                    bestScore = score
                    bestMove = move
                }
            }
        }

        return bestMove ?: shuffledMoves.firstOrNull()
    }

    private fun minimax(
        state: GameState,
        depth: Int,
        alpha: Int,
        beta: Int,
        maximizingPlayer: Boolean
    ): Int {
        if (depth == 0 || state.isGameOver) {
            return evaluate(state)
        }

        val validMoves = gameEngine.getValidMoves(state)
        if (validMoves.isEmpty()) {
            return evaluate(state)
        }

        var curAlpha = alpha
        var curBeta = beta

        if (maximizingPlayer) {
            var maxEval = -99999
            for (move in validMoves) {
                val newState = gameEngine.executeMove(state, move)
                val eval = minimax(newState, depth - 1, curAlpha, curBeta, false)
                maxEval = max(maxEval, eval)
                curAlpha = max(curAlpha, eval)
                if (curBeta <= curAlpha) break
            }
            return maxEval
        } else {
            var minEval = 99999
            for (move in validMoves) {
                val newState = gameEngine.executeMove(state, move)
                val eval = minimax(newState, depth - 1, curAlpha, curBeta, true)
                minEval = min(minEval, eval)
                curBeta = min(curBeta, eval)
                if (curBeta <= curAlpha) break
            }
            return minEval
        }
    }

    private fun evaluate(state: GameState): Int {
        if (state.winner == GameWinner.TIGERS) return 10000
        if (state.winner == GameWinner.GOATS) return -10000

        var score = 0
        score += state.goatsCaptured * 500

        val mobileTigers = gameEngine.countMobileTigers(state)
        score += mobileTigers * 60

        val trappedTigers = state.tigers.size - mobileTigers
        score -= trappedTigers * 250

        if (state.phase == GamePhase.PLACEMENT) {
            score += (state.level.goatCount - state.goatsPlaced) * 12
        }

        for (tiger in state.tigers) {
            score += positionValue(tiger.position, state.level)
        }

        val tigerCaptures = gameEngine.getTigerMoves(state.copy(currentTurn = PlayerTurn.TIGER))
            .count { it.isCapture }
        score += tigerCaptures * 40

        if (state.goatsOnBoard.size > 5) {
            val clusterPenalty = calculateClustering(state)
            score += clusterPenalty * 6
        }

        return score
    }

    private fun positionValue(pos: Position, level: BoardLevel): Int {
        val centerRow = level.rows / 2
        val centerCol = level.cols / 2
        val dist = abs(pos.row - centerRow) + abs(pos.col - centerCol)
        return 12 - dist * 2
    }

    private fun calculateClustering(state: GameState): Int {
        var adjacentPairs = 0
        val goats = state.goatsOnBoard
        for (i in goats.indices) {
            for (j in i + 1 until goats.size) {
                if (goats[i].position.isAdjacentTo(goats[j].position)) {
                    adjacentPairs++
                }
            }
        }
        return adjacentPairs
    }
}
