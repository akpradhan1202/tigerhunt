import 'game_models.dart';
import 'game_state.dart';
import 'board_connections.dart';

/// Core game logic engine
class GameEngine {
  final BoardConnections connections;

  GameEngine(BoardLevel level) : connections = BoardConnections(level);

  /// Get all valid moves for current player
  List<Move> getValidMoves(GameState state) {
    if (state.isGameOver) return [];

    if (state.currentTurn == PlayerTurn.goat) {
      return _getGoatMoves(state);
    } else {
      return _getTigerMoves(state);
    }
  }

  /// Get all valid goat moves (placement or movement)
  List<Move> _getGoatMoves(GameState state) {
    final moves = <Move>[];

    if (state.phase == GamePhase.placement) {
      // Goat placement phase: can place on any empty position
      for (final pos in connections.allPositions) {
        if (state.isPositionEmpty(pos)) {
          moves.add(Move(
            from: const Position(-1, -1), // Special "placement" position
            to: pos,
            pieceType: PieceType.goat,
          ));
        }
      }
    } else {
      // Movement phase: goats can move to adjacent empty positions
      for (final goat in state.goatsOnBoard) {
        for (final neighbor in connections.getNeighbors(goat.position)) {
          if (state.isPositionEmpty(neighbor)) {
            moves.add(Move(
              from: goat.position,
              to: neighbor,
              pieceType: PieceType.goat,
            ));
          }
        }
      }
    }

    return moves;
  }

  /// Get all valid tiger moves (including captures)
  List<Move> _getTigerMoves(GameState state) {
    final moves = <Move>[];

    for (final tiger in state.tigers) {
      // Regular moves to adjacent empty positions
      for (final neighbor in connections.getNeighbors(tiger.position)) {
        if (state.isPositionEmpty(neighbor)) {
          moves.add(Move(
            from: tiger.position,
            to: neighbor,
            pieceType: PieceType.tiger,
          ));
        } else {
          // Check for capture: neighbor has a goat, and position beyond is empty
          final pieceAtNeighbor = state.getPieceAt(neighbor);
          if (pieceAtNeighbor?.type == PieceType.goat) {
            final jumpDest = connections.getJumpDestination(
              tiger.position,
              neighbor,
            );
            if (jumpDest != null && state.isPositionEmpty(jumpDest)) {
              moves.add(Move(
                from: tiger.position,
                to: jumpDest,
                capturedAt: neighbor,
                pieceType: PieceType.tiger,
              ));
            }
          }
        }
      }
    }

    return moves;
  }

  /// Execute a move and return new game state
  GameState executeMove(GameState state, Move move) {
    if (!isValidMove(state, move)) {
      throw ArgumentError('Invalid move: $move');
    }

    List<Piece> newPieces = List.from(state.pieces);
    int newGoatsPlaced = state.goatsPlaced;
    int newGoatsCaptured = state.goatsCaptured;
    GamePhase newPhase = state.phase;
    List<Move> newHistory = [...state.moveHistory, move];

    if (move.pieceType == PieceType.goat) {
      if (move.isPlacement) {
        // Place new goat
        newPieces.add(Piece(
          type: PieceType.goat,
          position: move.to,
          id: 'goat_$newGoatsPlaced',
        ));
        newGoatsPlaced++;

        // Check if all goats placed
        if (newGoatsPlaced >= state.level.goatCount) {
          newPhase = GamePhase.movement;
        }
      } else {
        // Move existing goat
        final goatIndex = newPieces.indexWhere(
          (p) => p.position == move.from && p.type == PieceType.goat,
        );
        if (goatIndex >= 0) {
          newPieces[goatIndex] = newPieces[goatIndex].copyWith(
            position: move.to,
          );
        }
      }
    } else {
      // Tiger move
      final tigerIndex = newPieces.indexWhere(
        (p) => p.position == move.from && p.type == PieceType.tiger,
      );
      if (tigerIndex >= 0) {
        newPieces[tigerIndex] = newPieces[tigerIndex].copyWith(
          position: move.to,
        );
      }

      // Handle capture
      if (move.isCapture) {
        final goatIndex = newPieces.indexWhere(
          (p) => p.position == move.capturedAt && p.type == PieceType.goat,
        );
        if (goatIndex >= 0) {
          newPieces[goatIndex] = newPieces[goatIndex].copyWith(
            isCaptured: true,
          );
          newGoatsCaptured++;
        }
      }
    }

    // Create new state
    var newState = state.copyWith(
      pieces: newPieces,
      currentTurn: state.currentTurn == PlayerTurn.goat
          ? PlayerTurn.tiger
          : PlayerTurn.goat,
      phase: newPhase,
      goatsPlaced: newGoatsPlaced,
      goatsCaptured: newGoatsCaptured,
      moveHistory: newHistory,
    );

    // Check for winner
    newState = _checkWinner(newState);

    return newState;
  }

  /// Check if a move is valid
  bool isValidMove(GameState state, Move move) {
    final validMoves = getValidMoves(state);
    return validMoves.any((m) =>
        m.from == move.from &&
        m.to == move.to &&
        m.capturedAt == move.capturedAt);
  }

  /// Check for winner
  GameState _checkWinner(GameState state) {
    // Tigers win if they capture enough goats
    if (state.goatsCaptured >= state.level.goatsToWin) {
      return state.copyWith(
        winner: GameWinner.tigers,
        phase: GamePhase.ended,
      );
    }

    // Goats win if all tigers are trapped (no valid moves)
    final tigerMoves = _getTigerMoves(state.copyWith(currentTurn: PlayerTurn.tiger));
    if (tigerMoves.isEmpty && state.tigers.isNotEmpty) {
      return state.copyWith(
        winner: GameWinner.goats,
        phase: GamePhase.ended,
      );
    }

    return state;
  }

  /// Check if tigers are trapped
  bool areTigersTrapped(GameState state) {
    final tigerMoves = _getTigerMoves(state.copyWith(currentTurn: PlayerTurn.tiger));
    return tigerMoves.isEmpty;
  }

  /// Count how many tigers can move
  int countMobileTigers(GameState state) {
    int count = 0;
    for (final tiger in state.tigers) {
      bool canMove = false;
      for (final neighbor in connections.getNeighbors(tiger.position)) {
        if (state.isPositionEmpty(neighbor)) {
          canMove = true;
          break;
        }
        // Check capture possibility
        final piece = state.getPieceAt(neighbor);
        if (piece?.type == PieceType.goat) {
          final jumpDest = connections.getJumpDestination(tiger.position, neighbor);
          if (jumpDest != null && state.isPositionEmpty(jumpDest)) {
            canMove = true;
            break;
          }
        }
      }
      if (canMove) count++;
    }
    return count;
  }
}
