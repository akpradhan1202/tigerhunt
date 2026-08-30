import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/features/game/models/game_models.dart';
import 'package:tigerhunt/features/game/models/game_state.dart';
import 'package:tigerhunt/features/game/models/game_engine.dart';
import 'package:tigerhunt/features/game/models/board_connections.dart';

void main() {
  group('Traditional Board Fan Jumps & Captures', () {
    late BoardConnections conn;
    late GameEngine engine;

    setUp(() {
      conn = BoardConnections(BoardLevel.traditional);
      engine = GameEngine(BoardLevel.traditional);
    });

    test('Bottom fan jumps along rays', () {
      // Hub (4,2) over inner-right (5,3) -> outer-right (6,3)
      expect(
        conn.getJumpDestination(const Position(4, 2), const Position(5, 3)),
        equals(const Position(6, 3)),
      );

      // Hub (4,2) over inner-left (5,1) -> outer-left (6,1)
      expect(
        conn.getJumpDestination(const Position(4, 2), const Position(5, 1)),
        equals(const Position(6, 1)),
      );

      // Hub (4,2) over inner-mid (5,2) -> outer-mid (6,2)
      expect(
        conn.getJumpDestination(const Position(4, 2), const Position(5, 2)),
        equals(const Position(6, 2)),
      );

      // Reverse: Outer-right (6,3) over inner-right (5,3) -> Hub (4,2)
      expect(
        conn.getJumpDestination(const Position(6, 3), const Position(5, 3)),
        equals(const Position(4, 2)),
      );
    });

    test('Top fan jumps along rays', () {
      // Hub (0,2) over inner-right (-1,3) -> outer-right (-2,3)
      expect(
        conn.getJumpDestination(const Position(0, 2), const Position(-1, 3)),
        equals(const Position(-2, 3)),
      );
      // Hub (0,2) over inner-left (-1,1) -> outer-left (-2,1)
      expect(
        conn.getJumpDestination(const Position(0, 2), const Position(-1, 1)),
        equals(const Position(-2, 1)),
      );
    });

    test('Left fan jumps along rays', () {
      // Hub (2,0) over inner-top (1,-1) -> outer-top (1,-2)
      expect(
        conn.getJumpDestination(const Position(2, 0), const Position(1, -1)),
        equals(const Position(1, -2)),
      );
      // Hub (2,0) over inner-bottom (3,-1) -> outer-bottom (3,-2)
      expect(
        conn.getJumpDestination(const Position(2, 0), const Position(3, -1)),
        equals(const Position(3, -2)),
      );
    });

    test('Right fan jumps along rays', () {
      // Hub (2,4) over inner-top (1,5) -> outer-top (1,6)
      expect(
        conn.getJumpDestination(const Position(2, 4), const Position(1, 5)),
        equals(const Position(1, 6)),
      );
      // Hub (2,4) over inner-bottom (3,5) -> outer-bottom (3,6)
      expect(
        conn.getJumpDestination(const Position(2, 4), const Position(3, 5)),
        equals(const Position(3, 6)),
      );
    });

    test('Tiger at (4,2) captures Goat at (5,3) to land on (6,3)', () {
      final state = GameState(
        level: BoardLevel.traditional,
        pieces: const [
          Piece(type: PieceType.tiger, position: Position(4, 2), id: 'tiger_0'),
          Piece(type: PieceType.goat, position: Position(5, 3), id: 'goat_0'),
        ],
        currentTurn: PlayerTurn.tiger,
        phase: GamePhase.movement,
        winner: GameWinner.none,
        goatsPlaced: 20,
        goatsCaptured: 0,
        moveHistory: const [],
      );

      final moves = engine.getValidMoves(state);
      final captureMove = moves.firstWhere(
        (m) => m.from == const Position(4, 2) && m.to == const Position(6, 3),
      );

      expect(captureMove.capturedAt, equals(const Position(5, 3)));
    });
  });
}
