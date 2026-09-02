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

    List<Move> rawMoves;
    if (state.currentTurn == PlayerTurn.goat) {
      rawMoves = _getGoatMoves(state);
    } else {
      rawMoves = _getTigerMoves(state);
    }

    // Filter anti-oscillation loops if other moves are available
    return _filterAntiOscillationMoves(state, rawMoves);
  }

  /// Get all valid goat moves (placement or movement)
  List<Move> _getGoatMoves(GameState state) {
    final moves = <Move>[];

    if (state.phase == GamePhase.placement) {
      // Goat placement phase: can place on any empty position (not collapsed or bouldered)
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
      // Movement phase: active goats can move if not stunned
      for (final goat in state.goatsOnBoard) {
        if (state.isGoatStunned(goat.position)) continue;

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
          // Check for capture: neighbor has an active unshielded goat
          final pieceAtNeighbor = state.getPieceAt(neighbor);
          final isShielded = state.isGoatShielded(neighbor);
          if (pieceAtNeighbor?.type == PieceType.goat && !isShielded) {
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

  /// Filter out 2-spot repetitive ping-pong loop moves if alternative moves exist
  List<Move> _filterAntiOscillationMoves(GameState state, List<Move> moves) {
    if (moves.length <= 1 || state.moveHistory.length < 4) return moves;

    final history = state.moveHistory;
    // Look at player's previous moves
    final playerMoves = history
        .where((m) =>
            m.pieceType ==
            (state.currentTurn == PlayerTurn.tiger ? PieceType.tiger : PieceType.goat))
        .toList();

    if (playerMoves.length < 2) return moves;

    final last = playerMoves[playerMoves.length - 1];
    final secondLast = playerMoves[playerMoves.length - 2];

    // If player went A -> B, then B -> A, moving A -> B again is an oscillation
    if (last.to == secondLast.from && last.from == secondLast.to) {
      final repeatingMove = Move(
        from: last.to,
        to: last.from,
        pieceType: last.pieceType,
      );

      final nonRepeating = moves
          .where((m) => !(m.from == repeatingMove.from && m.to == repeatingMove.to))
          .toList();

      if (nonRepeating.isNotEmpty) {
        return nonRepeating;
      }
    }

    return moves;
  }

  /// Rebuild a fresh game state by replaying the first [moveCount] moves of
  /// [state]'s history from the initial position.
  GameState replayMoves(GameState state, int moveCount, {GameTimer? timer}) {
    var rebuilt = GameState.initial(state.level, timer: timer);
    final moves = state.moveHistory.take(moveCount);
    for (final move in moves) {
      rebuilt = executeMove(rebuilt, move);
    }
    return rebuilt;
  }

  /// Execute a move and return new game state
  GameState executeMove(GameState state, Move move) {
    if (!isValidMove(state, move)) {
      throw ArgumentError('Invalid move: $move');
    }

    final List<Piece> newPieces = List.from(state.pieces);
    int newGoatsPlaced = state.goatsPlaced;
    int newGoatsCaptured = state.goatsCaptured;
    GamePhase newPhase = state.phase;
    final List<Move> newHistory = [...state.moveHistory, move];

    int newMovesWithoutCapture = state.movesWithoutCapture;

    if (move.pieceType == PieceType.goat) {
      if (move.isPlacement) {
        newPieces.add(Piece(
          type: PieceType.goat,
          position: move.to,
          id: 'goat_$newGoatsPlaced',
        ));
        newGoatsPlaced++;
        newMovesWithoutCapture = 0;

        if (newGoatsPlaced >= state.level.goatCount) {
          newPhase = GamePhase.movement;
        }
      } else {
        final goatIndex = newPieces.indexWhere(
          (p) =>
              p.position == move.from &&
              p.type == PieceType.goat &&
              !p.isCaptured,
        );
        if (goatIndex >= 0) {
          newPieces[goatIndex] = newPieces[goatIndex].copyWith(
            position: move.to,
          );
        }
        if (newPhase == GamePhase.movement) {
          newMovesWithoutCapture++;
        }
      }
    } else {
      // Tiger move
      final tigerIndex = newPieces.indexWhere(
        (p) =>
            p.position == move.from &&
            p.type == PieceType.tiger &&
            !p.isCaptured,
      );
      if (tigerIndex >= 0) {
        newPieces[tigerIndex] = newPieces[tigerIndex].copyWith(
          position: move.to,
        );
      }

      if (move.isCapture) {
        final goatIndex = newPieces.indexWhere(
          (p) =>
              p.position == move.capturedAt &&
              p.type == PieceType.goat &&
              !p.isCaptured,
        );
        if (goatIndex >= 0) {
          newPieces[goatIndex] = newPieces[goatIndex].copyWith(
            isCaptured: true,
          );
          newGoatsCaptured++;
          newMovesWithoutCapture = 0;
        }
      } else {
        if (newPhase == GamePhase.movement) {
          newMovesWithoutCapture++;
        }
      }
    }

    // Tick down active effects belonging to the turn that just played
    final updatedEffects = <ActiveEffect>[];
    for (final effect in state.activeEffects) {
      if (effect.appliedBy == state.currentTurn) {
        final remaining = effect.turnsRemaining - 1;
        if (remaining > 0) {
          updatedEffects.add(effect.copyWith(turnsRemaining: remaining));
        }
      } else {
        updatedEffects.add(effect);
      }
    }

    final nextTurn = state.currentTurn == PlayerTurn.goat
        ? PlayerTurn.tiger
        : PlayerTurn.goat;

    // Create intermediate state to compute canonical signature
    var newState = state.copyWith(
      pieces: newPieces,
      currentTurn: nextTurn,
      phase: newPhase,
      goatsPlaced: newGoatsPlaced,
      goatsCaptured: newGoatsCaptured,
      moveHistory: newHistory,
      movesWithoutCapture: newMovesWithoutCapture,
      activeEffects: updatedEffects,
    );

    // Track position history for threefold repetition
    final sig = newState.stateSignature;
    final updatedHistory = Map<String, int>.from(state.positionHistory);
    updatedHistory[sig] = (updatedHistory[sig] ?? 0) + 1;
    newState = newState.copyWith(positionHistory: updatedHistory);

    // Check for winner / draw
    newState = _checkWinner(newState);

    return newState;
  }

  /// Apply a tactical power-up
  GameState applyPowerUp(
    GameState state, {
    required PowerUpType powerUp,
    required Position target,
  }) {
    final used = Map<PlayerTurn, Set<PowerUpType>>.from(state.usedPowerUps);
    final currentUsed = Set<PowerUpType>.from(used[state.currentTurn] ?? {});
    currentUsed.add(powerUp);
    used[state.currentTurn] = currentUsed;

    int turns;
    switch (powerUp) {
      case PowerUpType.tigerRoar:
        turns = 1;
        break;
      case PowerUpType.hornShield:
        turns = 2;
        break;
      case PowerUpType.boulder:
        turns = 3;
        break;
      case PowerUpType.superPounce:
        turns = 1;
        break;
    }

    final effect = ActiveEffect(
      type: powerUp,
      targetPosition: target,
      turnsRemaining: turns,
      appliedBy: state.currentTurn,
    );

    return state.copyWith(
      activeEffects: [...state.activeEffects, effect],
      usedPowerUps: used,
    );
  }

  /// Trigger Sudden Death Arena Collapse on a set of nodes
  GameState triggerArenaCollapse(GameState state, Set<Position> collapsing) {
    final newCollapsed = {...state.collapsedPositions, ...collapsing};
    final newPieces = <Piece>[];

    // Keep track of positions occupied by pieces that aren't collapsing
    final occupiedPositions = <Position>{};
    for (final p in state.pieces) {
      if (!p.isCaptured && !collapsing.contains(p.position)) {
        occupiedPositions.add(p.position);
      }
    }

    for (final piece in state.pieces) {
      if (piece.isCaptured) {
        newPieces.add(piece);
        continue;
      }
      if (collapsing.contains(piece.position)) {
        // Fair Inward Relocation for Both Goats and Tigers (no one dies!)
        Position? targetPos;
        final validNeighbors = connections
            .getNeighbors(piece.position)
            .where((pos) => !newCollapsed.contains(pos) && !occupiedPositions.contains(pos))
            .toList();

        if (validNeighbors.isNotEmpty) {
          targetPos = validNeighbors.first;
        } else {
          // If direct neighbors are full/collapsed, relocate towards center
          final centerRow = (connections.level.rows - 1) / 2.0;
          final centerCol = (connections.level.cols - 1) / 2.0;
          final allSafe = <Position>[];
          for (int r = 0; r < connections.level.rows; r++) {
            for (int c = 0; c < connections.level.cols; c++) {
              final pos = Position(r, c);
              if (connections.isValidPosition(pos) &&
                  !newCollapsed.contains(pos) &&
                  !occupiedPositions.contains(pos)) {
                allSafe.add(pos);
              }
            }
          }
          if (allSafe.isNotEmpty) {
            allSafe.sort((a, b) {
              final distA = (a.row - centerRow).abs() + (a.col - centerCol).abs();
              final distB = (b.row - centerRow).abs() + (b.col - centerCol).abs();
              return distA.compareTo(distB);
            });
            targetPos = allSafe.first;
          }
        }

        final safePos = targetPos ?? piece.position;
        occupiedPositions.add(safePos);
        newPieces.add(piece.copyWith(position: safePos));
      } else {
        newPieces.add(piece);
      }
    }

    var newState = state.copyWith(
      pieces: newPieces,
      collapsedPositions: newCollapsed,
    );

    return _checkWinner(newState);
  }

  /// Check if a move is valid
  bool isValidMove(GameState state, Move move) {
    final validMoves = getValidMoves(state);
    return validMoves.any((m) =>
        m.from == move.from &&
        m.to == move.to &&
        m.capturedAt == move.capturedAt);
  }

  /// Check for winner or draw
  GameState _checkWinner(GameState state) {
    // Tigers win if they capture enough goats
    if (state.goatsCaptured >= state.level.goatsToWin) {
      return state.copyWith(
        winner: GameWinner.tigers,
        phase: GamePhase.ended,
      );
    }

    // Threefold Repetition Draw
    final sig = state.stateSignature;
    if ((state.positionHistory[sig] ?? 0) >= 3) {
      return state.copyWith(
        winner: GameWinner.draw,
        drawReason: DrawReason.threefoldRepetition,
        phase: GamePhase.ended,
      );
    }

    // 40-Move Stagnation Draw
    if (state.phase == GamePhase.movement && state.movesWithoutCapture >= 40) {
      return state.copyWith(
        winner: GameWinner.draw,
        drawReason: DrawReason.stagnation,
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
        final piece = state.getPieceAt(neighbor);
        final isShielded = state.isGoatShielded(neighbor);
        if (piece?.type == PieceType.goat && !isShielded) {
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
