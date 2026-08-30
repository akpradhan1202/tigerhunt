import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/features/game/models/game_models.dart';
import 'package:tigerhunt/features/game/models/game_state.dart';
import 'package:tigerhunt/features/game/models/game_engine.dart';
import 'package:tigerhunt/features/game/models/board_connections.dart';

void main() {
  test('pyramid board 3 corners setup and connections', () {
    final conn = BoardConnections(BoardLevel.pyramid);
    expect(conn.allPositions.length, equals(18));

    // Initial setup has 3 tigers at apex (0,2), bottom-left (4,0), bottom-right (4,4)
    final state = GameState.initial(BoardLevel.pyramid);
    final tigerPositions = state.tigers.map((t) => t.position).toSet();
    expect(tigerPositions, equals({
      const Position(0, 2),
      const Position(4, 0),
      const Position(4, 4),
    }));

    // Test upward moves in column 1:
    // (3,1) can move up to (2,1)
    expect(conn.areConnected(const Position(3, 1), const Position(2, 1)), isTrue);
    // (2,1) can move up to (1,1)
    expect(conn.areConnected(const Position(2, 1), const Position(1, 1)), isTrue);

    // Test upward moves in column 2:
    // (3,2) can move up to (2,2)
    expect(conn.areConnected(const Position(3, 2), const Position(2, 2)), isTrue);

    // Test upward moves in column 3:
    // (3,3) can move up to (2,3)
    expect(conn.areConnected(const Position(3, 3), const Position(2, 3)), isTrue);
    // (2,3) can move up to (1,3)
    expect(conn.areConnected(const Position(2, 3), const Position(1, 3)), isTrue);

    // Test upward moves in column 0 & 4:
    expect(conn.areConnected(const Position(3, 0), const Position(2, 0)), isTrue);
    expect(conn.areConnected(const Position(3, 4), const Position(2, 4)), isTrue);
  });
}
