import 'package:flutter_test/flutter_test.dart';

import 'package:tigerhunt/features/game/models/game_models.dart';
import 'package:tigerhunt/features/game/widgets/game_board.dart';

void main() {
  group('traditionalBoardSegments', () {
    test('covers every position including the four triangle apexes', () {
      final segments = traditionalBoardSegments();
      expect(segments, isNotEmpty);

      final positions = <Position>{};
      for (final (from, to) in segments) {
        positions.add(from);
        positions.add(to);
      }

      // 5x5 grid (25) + 4 fan extensions of 6 nodes each = 49 playable points.
      expect(positions.length, 49);

      for (final node in [
        const Position(-1, 2), // top inner
        const Position(-2, 2), // top outer
        const Position(6, 2), // bottom outer
        const Position(2, -2), // left outer
        const Position(2, 6), // right outer
      ]) {
        expect(positions, contains(node));
      }
    });

    test('segments span the whole board, centered with all four extensions', () {
      const boardSize = 400.0;
      final segments = traditionalBoardSegments();
      expect(segments, isNotEmpty);

      var minX = double.infinity, minY = double.infinity;
      var maxX = -double.infinity, maxY = -double.infinity;
      for (final (from, to) in segments) {
        for (final pos in [from, to]) {
          final o = traditionalPositionOffset(pos, boardSize);
          if (o.dx < minX) minX = o.dx;
          if (o.dy < minY) minY = o.dy;
          if (o.dx > maxX) maxX = o.dx;
          if (o.dy > maxY) maxY = o.dy;
        }
      }

      // The reference layout fits inside the canvas: extensions reach
      // 0.035/0.965 of the board size, so the pattern stays within bounds
      // while covering nearly the whole canvas, and is centered.
      expect(minX, greaterThan(0));
      expect(minY, greaterThan(0));
      expect(maxX, lessThan(boardSize));
      expect(maxY, lessThan(boardSize));
      expect(minY, lessThan(boardSize * 0.1)); // top fan outer row at 0.035
      expect(maxY, greaterThan(boardSize * 0.9)); // bottom fan outer row at 0.965
      expect(minX, lessThan(boardSize * 0.1)); // left fan outer column
      expect(maxX, greaterThan(boardSize * 0.9)); // right fan outer column

      // Centered: the four sides reach equally far out.
      expect(minX - 0, closeTo(boardSize - maxX, 0.001));
      expect(minY - 0, closeTo(boardSize - maxY, 0.001));
    });

    test('every grid position lies on at least one segment', () {
      final segments = traditionalBoardSegments();
      final endpoints = <Position>{};
      for (final (from, to) in segments) {
        endpoints.add(from);
        endpoints.add(to);
      }
      for (int row = 0; row < 5; row++) {
        for (int col = 0; col < 5; col++) {
          expect(
            endpoints,
            contains(Position(row, col)),
            reason: 'grid point ($row,$col) should be drawn',
          );
        }
      }
    });

    test('traditionalPositionOffset matches the reference layout', () {
      const boardSize = 400.0;

      void expectOffset(Position pos, double x, double y) {
        final o = traditionalPositionOffset(pos, boardSize);
        expect(o.dx, closeTo(x, 0.001), reason: 'dx of $pos');
        expect(o.dy, closeTo(y, 0.001), reason: 'dy of $pos');
      }

      // Central 5x5 grid spans the middle half of the canvas (0.25..0.75).
      expectOffset(const Position(0, 0), 100, 100);
      expectOffset(const Position(4, 4), 300, 300);
      expectOffset(const Position(2, 2), 200, 200);
      expectOffset(const Position(0, 2), 200, 100);

      // Top fan: outer row flat at y=0.035 (x: 0.39, 0.50, 0.61), inner row
      // at y=0.135 (x: 0.43, 0.50, 0.57), hub is grid (0,2).
      expectOffset(const Position(-2, 1), 156, 14);
      expectOffset(const Position(-2, 2), 200, 14);
      expectOffset(const Position(-1, 1), 172, 54);
      expectOffset(const Position(-1, 2), 200, 54);

      // Side fans mirror the top fan.
      expectOffset(const Position(2, -2), 14, 200);
      expectOffset(const Position(2, -1), 54, 200);
      expectOffset(const Position(2, 6), 386, 200);
    });
  });
}
