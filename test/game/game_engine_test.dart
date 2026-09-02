import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/features/game/models/game_models.dart';
import 'package:tigerhunt/features/game/models/game_state.dart';
import 'package:tigerhunt/features/game/models/game_engine.dart';
import 'package:tigerhunt/features/game/models/board_connections.dart';

void main() {
  group('Position', () {
    test('equality works correctly', () {
      const pos1 = Position(2, 3);
      const pos2 = Position(2, 3);
      const pos3 = Position(3, 2);

      expect(pos1, equals(pos2));
      expect(pos1, isNot(equals(pos3)));
    });

    test('arithmetic operations work', () {
      const pos1 = Position(2, 3);
      const pos2 = Position(1, 1);

      expect(pos1 + pos2, equals(const Position(3, 4)));
      expect(pos1 - pos2, equals(const Position(1, 2)));
      expect(pos2 * 2, equals(const Position(2, 2)));
    });

    test('isAdjacentTo works correctly', () {
      const center = Position(2, 2);

      expect(center.isAdjacentTo(const Position(2, 3)), isTrue);
      expect(center.isAdjacentTo(const Position(1, 1)), isTrue);
      expect(center.isAdjacentTo(const Position(2, 4)), isFalse);
      expect(center.isAdjacentTo(const Position(2, 2)), isFalse);
    });
  });

  group('Piece', () {
    test('creates tiger piece correctly', () {
      const tiger = Piece(
        type: PieceType.tiger,
        position: Position(0, 0),
        id: 'tiger_0',
      );

      expect(tiger.type, equals(PieceType.tiger));
      expect(tiger.position, equals(const Position(0, 0)));
      expect(tiger.isCaptured, isFalse);
    });

    test('copyWith works correctly', () {
      const tiger = Piece(
        type: PieceType.tiger,
        position: Position(0, 0),
        id: 'tiger_0',
      );

      final movedTiger = tiger.copyWith(position: const Position(1, 1));

      expect(movedTiger.position, equals(const Position(1, 1)));
      expect(movedTiger.type, equals(PieceType.tiger));
      expect(movedTiger.id, equals('tiger_0'));
    });
  });

  group('BoardConnections', () {
    group('Traditional Board', () {
      late BoardConnections connections;

      setUp(() {
        connections = BoardConnections(BoardLevel.traditional);
      });

      test('all positions are valid', () {
        for (int row = 0; row < 5; row++) {
          for (int col = 0; col < 5; col++) {
            expect(
              connections.isValidPosition(Position(row, col)),
              isTrue,
              reason: 'Position ($row, $col) should be valid',
            );
          }
        }
      });

      test('corners have correct neighbors', () {
        // Top-left corner (0,0)
        final topLeftNeighbors = connections.getNeighbors(const Position(0, 0));
        expect(topLeftNeighbors, contains(const Position(0, 1)));
        expect(topLeftNeighbors, contains(const Position(1, 0)));
        expect(topLeftNeighbors, contains(const Position(1, 1))); // Diagonal
      });

      test('center has correct neighbors', () {
        // Center (2,2)
        final centerNeighbors = connections.getNeighbors(const Position(2, 2));
        expect(centerNeighbors.length, equals(8)); // All 8 directions
      });

      test('edge positions have correct neighbors', () {
        // Position (0,1) - top edge, no diagonal
        final edgeNeighbors = connections.getNeighbors(const Position(0, 1));
        expect(edgeNeighbors, contains(const Position(0, 0)));
        expect(edgeNeighbors, contains(const Position(0, 2)));
        expect(edgeNeighbors, contains(const Position(1, 1)));
        // Should NOT have diagonal neighbors (since row+col is odd)
        expect(edgeNeighbors, isNot(contains(const Position(1, 0))));
        expect(edgeNeighbors, isNot(contains(const Position(1, 2))));
      });

      test('areConnected works correctly', () {
        expect(connections.areConnected(
          const Position(0, 0),
          const Position(0, 1),
        ), isTrue);

        expect(connections.areConnected(
          const Position(0, 0),
          const Position(0, 2),
        ), isFalse);
      });

      test('getJumpDestination works for captures', () {
        final dest = connections.getJumpDestination(
          const Position(0, 0),
          const Position(0, 1),
        );
        expect(dest, equals(const Position(0, 2)));
      });

      test('every 2x2 cell has exactly one diagonal (classic pattern)', () {
        for (int row = 0; row < 4; row++) {
          for (int col = 0; col < 4; col++) {
            final tl = Position(row, col);
            final tr = Position(row, col + 1);
            final bl = Position(row + 1, col);
            final br = Position(row + 1, col + 1);
            final diagonals = [
              connections.areConnected(tl, br),
              connections.areConnected(tr, bl),
            ].where((c) => c).length;
            expect(
              diagonals,
              1,
              reason: 'cell ($row,$col) should have exactly one diagonal',
            );
          }
        }
      });

      test('diagonals alternate in checkerboard fashion', () {
        // Cells with (row+col) even carry the \\ diagonal, odd cells the /
        // diagonal, matching the classic Bagh-Chal board.
        for (int row = 0; row < 4; row++) {
          for (int col = 0; col < 4; col++) {
            final tl = Position(row, col);
            final br = Position(row + 1, col + 1);
            expect(
              connections.areConnected(tl, br),
              (row + col) % 2 == 0,
              reason: 'cell ($row,$col) main-diagonal orientation',
            );
          }
        }
      });

      test('edge midpoints connect to the inner diamond and grid', () {
        final topMid = connections.getNeighbors(const Position(0, 2));
        expect(topMid, contains(const Position(0, 1)));
        expect(topMid, contains(const Position(0, 3)));
        expect(topMid, contains(const Position(1, 2)));
        expect(topMid, contains(const Position(1, 1)));
        expect(topMid, contains(const Position(1, 3)));
      });

      test('each fan extension has 6 nodes and a hub', () {
        final fans = [
          [
            const Position(-1, 1), const Position(-1, 2), const Position(-1, 3),
            const Position(-2, 1), const Position(-2, 2), const Position(-2, 3),
          ],
          [
            const Position(5, 1), const Position(5, 2), const Position(5, 3),
            const Position(6, 1), const Position(6, 2), const Position(6, 3),
          ],
          [
            const Position(1, -1), const Position(2, -1), const Position(3, -1),
            const Position(1, -2), const Position(2, -2), const Position(3, -2),
          ],
          [
            const Position(1, 5), const Position(2, 5), const Position(3, 5),
            const Position(1, 6), const Position(2, 6), const Position(3, 6),
          ],
        ];

        for (final fan in fans) {
          for (final node in fan) {
            expect(connections.isValidPosition(node), isTrue,
                reason: '$node should be a valid extension node');
          }
          // Inner row connects to the hub and the outer row.
          for (int i = 0; i < 3; i++) {
            expect(
              connections.getNeighbors(fan[i]),
              contains(fan[i + 3]),
              reason: '${fan[i]} should connect to ${fan[i + 3]}',
            );
          }
          // Rows are joined horizontally.
          expect(connections.areConnected(fan[0], fan[1]), isTrue);
          expect(connections.areConnected(fan[1], fan[2]), isTrue);
          expect(connections.areConnected(fan[3], fan[4]), isTrue);
          expect(connections.areConnected(fan[4], fan[5]), isTrue);
        }
      });

      test('fan hubs connect to the three inner nodes', () {
        expect(connections.areConnected(
          const Position(0, 2),
          const Position(-1, 1),
        ), isTrue);
        expect(connections.areConnected(
          const Position(0, 2),
          const Position(-1, 2),
        ), isTrue);
        expect(connections.areConnected(
          const Position(0, 2),
          const Position(-1, 3),
        ), isTrue);
        expect(connections.areConnected(
          const Position(2, 0),
          const Position(1, -1),
        ), isTrue);
        expect(connections.areConnected(
          const Position(2, 0),
          const Position(2, -1),
        ), isTrue);
        expect(connections.areConnected(
          const Position(2, 4),
          const Position(2, 5),
        ), isTrue);
      });

      test('board is perfectly symmetrical', () {
        for (final a in connections.allPositions) {
          for (final b in connections.getNeighbors(a)) {
            // Mirror across the vertical axis.
            expect(
              connections.areConnected(
                Position(a.row, 4 - a.col),
                Position(b.row, 4 - b.col),
              ),
              isTrue,
              reason: '$a-$b should mirror across the vertical axis',
            );
            // Mirror across the horizontal axis.
            expect(
              connections.areConnected(
                Position(4 - a.row, a.col),
                Position(4 - b.row, b.col),
              ),
              isTrue,
              reason: '$a-$b should mirror across the horizontal axis',
            );
          }
        }
      });
    });

    group('Pyramid Board', () {
      late BoardConnections connections;

      setUp(() {
        connections = BoardConnections(BoardLevel.pyramid);
      });

      test('apex position exists', () {
        expect(connections.isValidPosition(const Position(0, 2)), isTrue);
      });

      test('apex has correct neighbors', () {
        final apexNeighbors = connections.getNeighbors(const Position(0, 2));
        expect(apexNeighbors, contains(const Position(1, 1)));
        expect(apexNeighbors, contains(const Position(1, 3)));
        expect(apexNeighbors.length, equals(2));
      });
    });
  });

  group('GameState', () {
    test('initial state has correct setup', () {
      final state = GameState.initial(BoardLevel.traditional);

      expect(state.tigers.length, equals(5));
      expect(state.goatsOnBoard.length, equals(0));
      expect(state.currentTurn, equals(PlayerTurn.goat));
      expect(state.phase, equals(GamePhase.placement));
      expect(state.goatsPlaced, equals(0));
      expect(state.goatsCaptured, equals(0));
    });

    test('tigers start at corners and center', () {
      final state = GameState.initial(BoardLevel.traditional);
      final tigerPositions = state.tigers.map((t) => t.position).toSet();

      expect(tigerPositions, contains(const Position(0, 0)));
      expect(tigerPositions, contains(const Position(0, 4)));
      expect(tigerPositions, contains(const Position(4, 0)));
      expect(tigerPositions, contains(const Position(4, 4)));
      expect(tigerPositions, contains(const Position(2, 2)));
    });

    test('getPieceAt returns correct piece', () {
      final state = GameState.initial(BoardLevel.traditional);

      final tigerCorner = state.getPieceAt(const Position(0, 0));
      expect(tigerCorner, isNotNull);
      expect(tigerCorner!.type, equals(PieceType.tiger));

      final tigerCenter = state.getPieceAt(const Position(2, 2));
      expect(tigerCenter, isNotNull);
      expect(tigerCenter!.type, equals(PieceType.tiger));

      final empty = state.getPieceAt(const Position(0, 1));
      expect(empty, isNull);
    });

    test('isPositionEmpty works correctly', () {
      final state = GameState.initial(BoardLevel.traditional);

      expect(state.isPositionEmpty(const Position(0, 0)), isFalse); // Tiger Corner
      expect(state.isPositionEmpty(const Position(2, 2)), isFalse); // Tiger Center
      expect(state.isPositionEmpty(const Position(0, 1)), isTrue); // Empty
    });
  });

  group('GameEngine', () {
    late GameEngine engine;
    late GameState initialState;

    setUp(() {
      engine = GameEngine(BoardLevel.traditional);
      initialState = GameState.initial(BoardLevel.traditional);
    });

    group('Goat Placement Phase', () {
      test('goats can be placed on empty positions', () {
        final moves = engine.getValidMoves(initialState);

        // Traditional board has 49 positions (5x5 grid + 4 fan extensions of
        // 6 nodes each); 5 are occupied by tigers, so 44 empty placement spots
        expect(moves.length, equals(44));

        // All moves should be placements
        for (final move in moves) {
          expect(move.isPlacement, isTrue);
          expect(move.pieceType, equals(PieceType.goat));
        }
      });

      test('goats cannot be placed on occupied positions', () {
        final moves = engine.getValidMoves(initialState);
        final movePositions = moves.map((m) => m.to).toSet();

        // Should not include tiger positions
        expect(movePositions, isNot(contains(const Position(0, 0))));
        expect(movePositions, isNot(contains(const Position(0, 4))));
        expect(movePositions, isNot(contains(const Position(4, 0))));
        expect(movePositions, isNot(contains(const Position(4, 4))));
      });

      test('placing a goat updates state correctly', () {
        const move = Move(
          from: Position(-1, -1),
          to: Position(1, 2),
          pieceType: PieceType.goat,
        );

        final newState = engine.executeMove(initialState, move);

        expect(newState.goatsPlaced, equals(1));
        expect(newState.goatsOnBoard.length, equals(1));
        expect(newState.currentTurn, equals(PlayerTurn.tiger));
        expect(newState.phase, equals(GamePhase.placement));
      });

      test('phase changes after all goats placed', () {
        var state = initialState;

        // Place all 20 goats on empty positions
        int goatCount = 0;
        for (final pos in engine.connections.allPositions) {
          if (state.isPositionEmpty(pos)) {
            final move = Move(
              from: const Position(-1, -1),
              to: pos,
              pieceType: PieceType.goat,
            );
            if (engine.isValidMove(state, move)) {
              state = engine.executeMove(state, move);
              goatCount++;

              // Skip tiger turns for simplicity
              if (state.currentTurn == PlayerTurn.tiger) {
                final tigerMoves = engine.getValidMoves(state);
                if (tigerMoves.isNotEmpty) {
                  state = engine.executeMove(state, tigerMoves.first);
                }
              }

              if (goatCount >= 20) break;
            }
          }
        }

        expect(state.allGoatsPlaced, isTrue);
      });
    });

    group('Tiger Movement', () {
      test('tigers can move to adjacent empty positions', () {
        // Place a goat first
        final state = engine.executeMove(
          initialState,
          const Move(
            from: Position(-1, -1),
            to: Position(1, 2),
            pieceType: PieceType.goat,
          ),
        );

        final tigerMoves = engine.getValidMoves(state);
        expect(tigerMoves.isNotEmpty, isTrue);

        // All moves should be tiger moves
        for (final move in tigerMoves) {
          expect(move.pieceType, equals(PieceType.tiger));
        }
      });

      test('tigers can capture goats by jumping', () {
        // Setup: Place a goat adjacent to a tiger with empty space beyond
        final state = engine.executeMove(
          initialState,
          const Move(
            from: Position(-1, -1),
            to: Position(0, 1), // Adjacent to tiger at (0,0)
            pieceType: PieceType.goat,
          ),
        );

        final tigerMoves = engine.getValidMoves(state);
        final captureMoves = tigerMoves.where((m) => m.isCapture).toList();

        expect(captureMoves.isNotEmpty, isTrue);

        // Find capture from (0,0) to (0,2) over goat at (0,1)
        final captureMove = captureMoves.firstWhere(
          (m) => m.from == const Position(0, 0) && m.to == const Position(0, 2),
          orElse: () => throw Exception('Capture move not found'),
        );

        expect(captureMove.capturedAt, equals(const Position(0, 1)));
      });

      test('capture removes goat from board', () {
        // Setup
        var state = engine.executeMove(
          initialState,
          const Move(
            from: Position(-1, -1),
            to: Position(0, 1),
            pieceType: PieceType.goat,
          ),
        );

        // Execute capture
        state = engine.executeMove(
          state,
          const Move(
            from: Position(0, 0),
            to: Position(0, 2),
            capturedAt: Position(0, 1),
            pieceType: PieceType.tiger,
          ),
        );

        expect(state.goatsCaptured, equals(1));
        expect(state.goatsOnBoard.length, equals(0));
        expect(state.isPositionEmpty(const Position(0, 1)), isTrue);
      });

      test('re-capturing a goat placed on the same square removes it', () {
        // Scenario: a tiger captures a goat at (0,1), the player places a new
        // goat on the same square, and the tiger captures again. The NEW goat
        // must be the one removed - the previously captured goat's stale
        // position must not shadow it.
        var state = engine.executeMove(
          initialState,
          const Move(
            from: Position(-1, -1),
            to: Position(0, 1),
            pieceType: PieceType.goat,
          ),
        );

        // Tiger at (0,0) captures over (0,1) landing at (0,2).
        state = engine.executeMove(
          state,
          const Move(
            from: Position(0, 0),
            to: Position(0, 2),
            capturedAt: Position(0, 1),
            pieceType: PieceType.tiger,
          ),
        );
        expect(state.goatsCaptured, equals(1));
        expect(state.isPositionEmpty(const Position(0, 1)), isTrue);

        // Player re-places a goat on the same square (0,1).
        state = engine.executeMove(
          state,
          const Move(
            from: Position(-1, -1),
            to: Position(0, 1),
            pieceType: PieceType.goat,
          ),
        );
        expect(state.goatsOnBoard.length, equals(1));
        expect(state.getPieceAt(const Position(0, 1))!.isCaptured, isFalse);

        // Tiger at (0,2) captures back over (0,1) landing at (0,0).
        state = engine.executeMove(
          state,
          const Move(
            from: Position(0, 2),
            to: Position(0, 0),
            capturedAt: Position(0, 1),
            pieceType: PieceType.tiger,
          ),
        );

        expect(state.goatsCaptured, equals(2));
        expect(state.goatsOnBoard.length, equals(0));
        expect(state.isPositionEmpty(const Position(0, 1)), isTrue);
        expect(state.getPieceAt(const Position(0, 1)), isNull);
      });
    });

    group('Undo / Replay', () {
      test('replayMoves rolls back the board to an earlier state', () {
        // Goat at (0,1), then a tiger slides in next to it.
        var state = engine.executeMove(
          initialState,
          const Move(
            from: Position(-1, -1),
            to: Position(0, 1),
            pieceType: PieceType.goat,
          ),
        );
        state = engine.executeMove(
          state,
          const Move(
            from: Position(0, 0),
            to: Position(1, 0),
            pieceType: PieceType.tiger,
          ),
        );
        expect(state.moveHistory.length, equals(2));

        // Undo one move (keep 1) -> back to just the goat placed.
        final afterOne = engine.replayMoves(state, 1);
        expect(afterOne.moveHistory.length, equals(1));
        expect(afterOne.getPieceAt(const Position(1, 0)), isNull);
        expect(afterOne.getPieceAt(const Position(0, 0)), isNotNull);
        expect(afterOne.getPieceAt(const Position(0, 1)), isNotNull);
        expect(afterOne.currentTurn, equals(PlayerTurn.tiger));

        // Undo everything -> fresh board, 44 empty placement spots (49 total - 5 tigers).
        final fresh = engine.replayMoves(state, 0);
        expect(fresh.moveHistory, isEmpty);
        expect(fresh.goatsOnBoard, isEmpty);
        expect(engine.getValidMoves(fresh).length, equals(44));
      });

      test('replayMoves reproduces captures and win states', () {
        // Goat at (0,1) next to tiger at (0,0); tiger captures it.
        var state = engine.executeMove(
          initialState,
          const Move(
            from: Position(-1, -1),
            to: Position(0, 1),
            pieceType: PieceType.goat,
          ),
        );
        state = engine.executeMove(
          state,
          const Move(
            from: Position(0, 0),
            to: Position(0, 2),
            capturedAt: Position(0, 1),
            pieceType: PieceType.tiger,
          ),
        );
        expect(state.goatsCaptured, equals(1));

        // Rolling back before the capture restores the goat.
        final before = engine.replayMoves(state, 1);
        expect(before.goatsCaptured, equals(0));
        expect(before.getPieceAt(const Position(0, 1)), isNotNull);

        // Replaying the full history reproduces the capture exactly.
        final replayed = engine.replayMoves(state, state.moveHistory.length);
        expect(replayed.goatsCaptured, equals(1));
        expect(replayed.goatsOnBoard.length, equals(0));
      });
    });

    group('Win Conditions', () {
      test('tigers win when 5 goats captured', () {
        var state = const GameState(
          level: BoardLevel.traditional,
          pieces: [
            Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
            Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
            Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
            Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
            Piece(type: PieceType.goat, position: Position(0, 1), id: 'g0'),
          ],
          currentTurn: PlayerTurn.tiger,
          phase: GamePhase.movement,
          winner: GameWinner.none,
          goatsPlaced: 20,
          goatsCaptured: 4, // Already captured 4
          moveHistory: [],
        );

        // Capture the 5th goat
        state = engine.executeMove(
          state,
          const Move(
            from: Position(0, 0),
            to: Position(0, 2),
            capturedAt: Position(0, 1),
            pieceType: PieceType.tiger,
          ),
        );

        expect(state.winner, equals(GameWinner.tigers));
        expect(state.isGameOver, isTrue);
      });

      test('goats win when all tigers trapped', () {
        // Tigers packed in the top-left 2x2 corner. Every adjacent square is
        // occupied, every fan node is blocked, and every capture landing
        // (behind each adjacent goat, including the diagonal jumps out through
        // the top/left fan hubs) is also occupied, so tigers have no moves.
        const state = GameState(
          level: BoardLevel.traditional,
          pieces: [
            // Tigers boxed in corner
            Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
            Piece(type: PieceType.tiger, position: Position(0, 1), id: 't1'),
            Piece(type: PieceType.tiger, position: Position(1, 0), id: 't2'),
            Piece(type: PieceType.tiger, position: Position(1, 1), id: 't3'),
            // Goats blocking every escape square
            Piece(type: PieceType.goat, position: Position(0, 2), id: 'g0'),
            Piece(type: PieceType.goat, position: Position(1, 2), id: 'g1'),
            Piece(type: PieceType.goat, position: Position(2, 0), id: 'g2'),
            Piece(type: PieceType.goat, position: Position(2, 1), id: 'g3'),
            Piece(type: PieceType.goat, position: Position(2, 2), id: 'g4'),
            // Goats blocking the triangle apexes
            Piece(type: PieceType.goat, position: Position(-1, 2), id: 'g5'),
            Piece(type: PieceType.goat, position: Position(2, -1), id: 'g6'),
            // Goats blocking every capture landing square
            Piece(type: PieceType.goat, position: Position(0, 3), id: 'g7'),
            Piece(type: PieceType.goat, position: Position(1, 3), id: 'g8'),
            Piece(type: PieceType.goat, position: Position(3, 0), id: 'g9'),
            Piece(type: PieceType.goat, position: Position(3, 1), id: 'g10'),
            Piece(type: PieceType.goat, position: Position(3, 3), id: 'g11'),
            // Goats blocking the fan capture landings (diagonal jumps out of
            // the corner through the top/left fan hubs)
            Piece(type: PieceType.goat, position: Position(-1, 3), id: 'g12'),
            Piece(type: PieceType.goat, position: Position(3, -1), id: 'g13'),
          ],
          currentTurn: PlayerTurn.tiger,
          phase: GamePhase.movement,
          winner: GameWinner.none,
          goatsPlaced: 20,
          goatsCaptured: 0,
          moveHistory: [],
        );

        expect(engine.areTigersTrapped(state), isTrue);
        // No tiger move (including captures) should be available
        expect(engine.getValidMoves(state), isEmpty);
      });
    });
  });
}
