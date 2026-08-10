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

      expect(state.tigers.length, equals(4));
      expect(state.goatsOnBoard.length, equals(0));
      expect(state.currentTurn, equals(PlayerTurn.goat));
      expect(state.phase, equals(GamePhase.placement));
      expect(state.goatsPlaced, equals(0));
      expect(state.goatsCaptured, equals(0));
    });

    test('tigers start at corners', () {
      final state = GameState.initial(BoardLevel.traditional);
      final tigerPositions = state.tigers.map((t) => t.position).toSet();

      expect(tigerPositions, contains(const Position(0, 0)));
      expect(tigerPositions, contains(const Position(0, 4)));
      expect(tigerPositions, contains(const Position(4, 0)));
      expect(tigerPositions, contains(const Position(4, 4)));
    });

    test('getPieceAt returns correct piece', () {
      final state = GameState.initial(BoardLevel.traditional);

      final tiger = state.getPieceAt(const Position(0, 0));
      expect(tiger, isNotNull);
      expect(tiger!.type, equals(PieceType.tiger));

      final empty = state.getPieceAt(const Position(2, 2));
      expect(empty, isNull);
    });

    test('isPositionEmpty works correctly', () {
      final state = GameState.initial(BoardLevel.traditional);

      expect(state.isPositionEmpty(const Position(0, 0)), isFalse); // Tiger
      expect(state.isPositionEmpty(const Position(2, 2)), isTrue); // Empty
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

        // Should have 21 valid placements (25 - 4 tigers)
        expect(moves.length, equals(21));

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
        final move = Move(
          from: const Position(-1, -1),
          to: const Position(2, 2),
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

        // Place all 20 goats
        int goatCount = 0;
        for (int row = 0; row < 5; row++) {
          for (int col = 0; col < 5; col++) {
            if (state.isPositionEmpty(Position(row, col))) {
              final move = Move(
                from: const Position(-1, -1),
                to: Position(row, col),
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
          if (goatCount >= 20) break;
        }

        expect(state.allGoatsPlaced, isTrue);
      });
    });

    group('Tiger Movement', () {
      test('tigers can move to adjacent empty positions', () {
        // Place a goat first
        var state = engine.executeMove(
          initialState,
          const Move(
            from: Position(-1, -1),
            to: Position(2, 2),
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
        var state = engine.executeMove(
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
    });

    group('Win Conditions', () {
      test('tigers win when 5 goats captured', () {
        var state = GameState(
          level: BoardLevel.traditional,
          pieces: [
            const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
            const Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
            const Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
            const Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
            const Piece(type: PieceType.goat, position: Position(0, 1), id: 'g0'),
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
        // Create state where all tigers are trapped
        final state = GameState(
          level: BoardLevel.traditional,
          pieces: [
            // Tigers boxed in corner
            const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
            const Piece(type: PieceType.tiger, position: Position(0, 1), id: 't1'),
            const Piece(type: PieceType.tiger, position: Position(1, 0), id: 't2'),
            const Piece(type: PieceType.tiger, position: Position(1, 1), id: 't3'),
            // Goats surrounding
            const Piece(type: PieceType.goat, position: Position(0, 2), id: 'g0'),
            const Piece(type: PieceType.goat, position: Position(1, 2), id: 'g1'),
            const Piece(type: PieceType.goat, position: Position(2, 0), id: 'g2'),
            const Piece(type: PieceType.goat, position: Position(2, 1), id: 'g3'),
            const Piece(type: PieceType.goat, position: Position(2, 2), id: 'g4'),
          ],
          currentTurn: PlayerTurn.tiger,
          phase: GamePhase.movement,
          winner: GameWinner.none,
          goatsPlaced: 20,
          goatsCaptured: 0,
          moveHistory: [],
        );

        expect(engine.areTigersTrapped(state), isTrue);
      });
    });
  });
}
