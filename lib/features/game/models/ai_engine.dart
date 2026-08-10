import 'dart:math';
import 'game_models.dart';
import 'game_state.dart';
import 'game_engine.dart';

/// AI engine using Minimax with Alpha-Beta pruning
class AIEngine {
  final GameEngine gameEngine;
  final AIDifficulty difficulty;
  final Random _random = Random();

  AIEngine({
    required this.gameEngine,
    required this.difficulty,
  });

  /// Get the best move for the current player
  Future<Move?> getBestMove(GameState state) async {
    final validMoves = gameEngine.getValidMoves(state);
    if (validMoves.isEmpty) return null;

    // For easy mode, sometimes make random moves
    if (difficulty == AIDifficulty.easy && _random.nextDouble() < 0.3) {
      return validMoves[_random.nextInt(validMoves.length)];
    }

    Move? bestMove;
    int bestScore = state.currentTurn == PlayerTurn.tiger
        ? -99999
        : 99999;

    // Shuffle moves for variety at same scores
    validMoves.shuffle(_random);

    for (final move in validMoves) {
      final newState = gameEngine.executeMove(state, move);
      final score = _minimax(
        newState,
        difficulty.depth - 1,
        -99999,
        99999,
        state.currentTurn == PlayerTurn.goat, // Maximize for tigers
      );

      if (state.currentTurn == PlayerTurn.tiger) {
        if (score > bestScore) {
          bestScore = score;
          bestMove = move;
        }
      } else {
        if (score < bestScore) {
          bestScore = score;
          bestMove = move;
        }
      }
    }

    return bestMove ?? validMoves.first;
  }

  /// Minimax with alpha-beta pruning
  int _minimax(
    GameState state,
    int depth,
    int alpha,
    int beta,
    bool maximizingPlayer,
  ) {
    // Terminal conditions
    if (depth == 0 || state.isGameOver) {
      return _evaluate(state);
    }

    final validMoves = gameEngine.getValidMoves(state);
    if (validMoves.isEmpty) {
      return _evaluate(state);
    }

    if (maximizingPlayer) {
      int maxEval = -99999;
      for (final move in validMoves) {
        final newState = gameEngine.executeMove(state, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, false);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break; // Beta cutoff
      }
      return maxEval;
    } else {
      int minEval = 99999;
      for (final move in validMoves) {
        final newState = gameEngine.executeMove(state, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, true);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break; // Alpha cutoff
      }
      return minEval;
    }
  }

  /// Evaluate board position (positive = good for tigers)
  int _evaluate(GameState state) {
    // Check for winner
    if (state.winner == GameWinner.tigers) return 10000;
    if (state.winner == GameWinner.goats) return -10000;

    int score = 0;

    // Factor 1: Captured goats (very important for tigers)
    score += state.goatsCaptured * 500;

    // Factor 2: Tiger mobility
    final mobileTigers = gameEngine.countMobileTigers(state);
    score += mobileTigers * 50;

    // Factor 3: Trapped tigers are bad
    final trappedTigers = state.tigers.length - mobileTigers;
    score -= trappedTigers * 200;

    // Factor 4: Goats placed (during placement, fewer is worse for goats)
    if (state.phase == GamePhase.placement) {
      // Tigers want goats bunched up
      score += (state.level.goatCount - state.goatsPlaced) * 10;
    }

    // Factor 5: Position control (center positions are valuable)
    for (final tiger in state.tigers) {
      score += _positionValue(tiger.position, state.level);
    }

    // Factor 6: Capture threats
    final captureMoves = gameEngine.getValidMoves(
      state.copyWith(currentTurn: PlayerTurn.tiger),
    ).where((m) => m.isCapture).length;
    score += captureMoves * 30;

    // Factor 7: Goat clustering (goats want to spread out to trap tigers)
    if (state.goatsOnBoard.length > 5) {
      final clusterPenalty = _calculateClustering(state);
      score += clusterPenalty * 5; // Good for tigers if goats cluster
    }

    return score;
  }

  /// Value of a position (center is more valuable)
  int _positionValue(Position pos, BoardLevel level) {
    final centerRow = level.rows ~/ 2;
    final centerCol = level.cols ~/ 2;
    final distFromCenter = (pos.row - centerRow).abs() +
        (pos.col - centerCol).abs();
    return 10 - distFromCenter * 2;
  }

  /// Calculate clustering penalty for goats
  int _calculateClustering(GameState state) {
    int adjacentPairs = 0;
    final goats = state.goatsOnBoard;

    for (int i = 0; i < goats.length; i++) {
      for (int j = i + 1; j < goats.length; j++) {
        if (goats[i].position.isAdjacentTo(goats[j].position)) {
          adjacentPairs++;
        }
      }
    }

    return adjacentPairs;
  }
}

/// AI player wrapper for easy use
class AIPlayer {
  final AIEngine _engine;
  final PieceType playingAs;

  AIPlayer({
    required GameEngine gameEngine,
    required AIDifficulty difficulty,
    required this.playingAs,
  }) : _engine = AIEngine(gameEngine: gameEngine, difficulty: difficulty);

  /// Get AI's move if it's their turn
  Future<Move?> getMove(GameState state) async {
    final isMyTurn = (playingAs == PieceType.tiger &&
            state.currentTurn == PlayerTurn.tiger) ||
        (playingAs == PieceType.goat &&
            state.currentTurn == PlayerTurn.goat);

    if (!isMyTurn) return null;

    // Add small delay for more natural feel
    await Future.delayed(const Duration(milliseconds: 300));

    return _engine.getBestMove(state);
  }
}
