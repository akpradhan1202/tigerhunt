import 'game_models.dart';

/// Defines valid connections for each board type
class BoardConnections {
  final BoardLevel level;
  late final Map<Position, List<Position>> _connections;
  late final Map<Position, Map<Position, Position>> _jumps;

  BoardConnections(this.level) {
    _connections = _buildConnections();
    _jumps = _buildJumps();
  }

  Map<Position, List<Position>> _buildConnections() {
    switch (level) {
      case BoardLevel.pyramid:
        return _buildPyramidConnections();
      case BoardLevel.square:
        return _buildSquareConnections();
      case BoardLevel.traditional:
        return _buildTraditionalConnections();
    }
  }

  Map<Position, Map<Position, Position>> _buildJumps() {
    switch (level) {
      case BoardLevel.pyramid:
        return _buildPyramidJumps();
      case BoardLevel.square:
        return _buildSquareJumps();
      case BoardLevel.traditional:
        return _buildTraditionalJumps();
    }
  }

  void _addCollinearLine(
    Map<Position, Map<Position, Position>> jumps,
    List<Position> line,
  ) {
    for (int i = 0; i < line.length - 2; i++) {
      final a = line[i];
      final b = line[i + 1];
      final c = line[i + 2];
      jumps.putIfAbsent(a, () => {})[b] = c;
      jumps.putIfAbsent(c, () => {})[b] = a;
    }
  }

  /// Pyramid board: Triangle shape on top of a 5x3 grid (18 points)
  ///            (0,2) [Apex]
  ///           /     \
  ///        (1,1)---(1,3)
  ///       /  |  \ /  |  \
  ///  (2,0)-(2,1)-(2,2)-(2,3)-(2,4)
  ///    |     |     |     |     |
  ///  (3,0)-(3,1)-(3,2)-(3,3)-(3,4)
  ///    |     |     |     |     |
  ///  (4,0)-(4,1)-(4,2)-(4,3)-(4,4)
  Map<Position, List<Position>> _buildPyramidConnections() {
    final Map<Position, List<Position>> conn = {};

    void link(Position a, Position b) {
      conn.putIfAbsent(a, () => <Position>[]).add(b);
      conn.putIfAbsent(b, () => <Position>[]).add(a);
    }

    // Top apex (0,2) to (1,1) and (1,3)
    link(const Position(0, 2), const Position(1, 1));
    link(const Position(0, 2), const Position(1, 3));
    link(const Position(1, 1), const Position(1, 3)); // horizontal at row 1

    // Row 1 to Row 2:
    // Outer triangle slopes:
    link(const Position(1, 1), const Position(2, 0));
    link(const Position(1, 3), const Position(2, 4));
    // Vertical lines:
    link(const Position(1, 1), const Position(2, 1));
    link(const Position(1, 3), const Position(2, 3));
    // Inner diagonals meeting at center (2,2):
    link(const Position(1, 1), const Position(2, 2));
    link(const Position(1, 3), const Position(2, 2));

    // Rows 2, 3, 4 (5x3 grid):
    // Horizontal connections
    for (int row = 2; row <= 4; row++) {
      for (int col = 0; col < 4; col++) {
        link(Position(row, col), Position(row, col + 1));
      }
    }

    // Vertical connections between rows 2, 3, 4
    for (int col = 0; col <= 4; col++) {
      link(Position(2, col), Position(3, col));
      link(Position(3, col), Position(4, col));
    }

    return conn;
  }

  /// Square board with diagonals
  Map<Position, List<Position>> _buildSquareConnections() {
    final Map<Position, List<Position>> conn = {};

    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        final pos = Position(row, col);
        final neighbors = <Position>[];

        // Orthogonal connections
        if (row > 0) neighbors.add(Position(row - 1, col));
        if (row < 4) neighbors.add(Position(row + 1, col));
        if (col > 0) neighbors.add(Position(row, col - 1));
        if (col < 4) neighbors.add(Position(row, col + 1));

        // Diagonal connections (only from certain positions)
        final hasDiagonal = (row + col) % 2 == 0;
        if (hasDiagonal) {
          if (row > 0 && col > 0) neighbors.add(Position(row - 1, col - 1));
          if (row > 0 && col < 4) neighbors.add(Position(row - 1, col + 1));
          if (row < 4 && col > 0) neighbors.add(Position(row + 1, col - 1));
          if (row < 4 && col < 4) neighbors.add(Position(row + 1, col + 1));
        }

        conn[pos] = neighbors;
      }
    }

    return conn;
  }

  /// Traditional Bagh-Chal board.
  ///
  /// A large 5x5 square grid connected by horizontal and vertical lines, with
  /// the classic diagonal pattern drawn inside it: the two main diagonals
  /// (corner to corner, meeting at the center) plus an inner diamond joining
  /// the four edge midpoints. Together those diagonals give every 2x2 cell a
  /// single alternating diagonal, creating the traditional triangular/diamond
  /// patterns. Four fan-shaped extensions stick out from the middle of each
  /// side (top, bottom, left, right): an outer row of 3 nodes on a curved
  /// boundary, an inner row of 3 nodes, and fan lines converging on the
  /// side's middle grid point.
  Map<Position, List<Position>> _buildTraditionalConnections() {
    final Map<Position, List<Position>> conn = {};

    // Main 5x5 grid positions: all horizontal + vertical connections.
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        final pos = Position(row, col);
        final neighbors = <Position>[];
        if (row > 0) neighbors.add(Position(row - 1, col));
        if (row < 4) neighbors.add(Position(row + 1, col));
        if (col > 0) neighbors.add(Position(row, col - 1));
        if (col < 4) neighbors.add(Position(row, col + 1));
        conn[pos] = neighbors;
      }
    }

    void link(Position a, Position b) {
      conn.putIfAbsent(a, () => <Position>[]).add(b);
      conn.putIfAbsent(b, () => <Position>[]).add(a);
    }

    // Two main diagonals, corner to corner through the center.
    link(const Position(0, 0), const Position(1, 1));
    link(const Position(1, 1), const Position(2, 2));
    link(const Position(2, 2), const Position(3, 3));
    link(const Position(3, 3), const Position(4, 4));
    link(const Position(0, 4), const Position(1, 3));
    link(const Position(1, 3), const Position(2, 2));
    link(const Position(2, 2), const Position(3, 1));
    link(const Position(3, 1), const Position(4, 0));

    // Inner diamond joining the four edge midpoints.
    link(const Position(0, 2), const Position(1, 1));
    link(const Position(0, 2), const Position(1, 3));
    link(const Position(1, 1), const Position(2, 0));
    link(const Position(1, 3), const Position(2, 4));
    link(const Position(2, 0), const Position(3, 1));
    link(const Position(2, 4), const Position(3, 3));
    link(const Position(3, 1), const Position(4, 2));
    link(const Position(3, 3), const Position(4, 2));

    // ========== FAN EXTENSIONS ==========
    // Each side has an inner row of 3 and an outer row of 3 nodes. The fan
    // lines connect the side's middle grid point (hub) to the three inner
    // nodes; verticals join inner to outer; horizontals join the rows.
    void fanTop() {
      link(const Position(0, 2), const Position(-1, 1));
      link(const Position(0, 2), const Position(-1, 2));
      link(const Position(0, 2), const Position(-1, 3));
      for (final c in [1, 2, 3]) {
        link(Position(-1, c), Position(-2, c));
      }
      link(const Position(-1, 1), const Position(-1, 2));
      link(const Position(-1, 2), const Position(-1, 3));
      link(const Position(-2, 1), const Position(-2, 2));
      link(const Position(-2, 2), const Position(-2, 3));
    }

    void fanBottom() {
      link(const Position(4, 2), const Position(5, 1));
      link(const Position(4, 2), const Position(5, 2));
      link(const Position(4, 2), const Position(5, 3));
      for (final c in [1, 2, 3]) {
        link(Position(5, c), Position(6, c));
      }
      link(const Position(5, 1), const Position(5, 2));
      link(const Position(5, 2), const Position(5, 3));
      link(const Position(6, 1), const Position(6, 2));
      link(const Position(6, 2), const Position(6, 3));
    }

    void fanLeft() {
      link(const Position(2, 0), const Position(1, -1));
      link(const Position(2, 0), const Position(2, -1));
      link(const Position(2, 0), const Position(3, -1));
      for (final r in [1, 2, 3]) {
        link(Position(r, -1), Position(r, -2));
      }
      link(const Position(1, -1), const Position(2, -1));
      link(const Position(2, -1), const Position(3, -1));
      link(const Position(1, -2), const Position(2, -2));
      link(const Position(2, -2), const Position(3, -2));
    }

    void fanRight() {
      link(const Position(2, 4), const Position(1, 5));
      link(const Position(2, 4), const Position(2, 5));
      link(const Position(2, 4), const Position(3, 5));
      for (final r in [1, 2, 3]) {
        link(Position(r, 5), Position(r, 6));
      }
      link(const Position(1, 5), const Position(2, 5));
      link(const Position(2, 5), const Position(3, 5));
      link(const Position(1, 6), const Position(2, 6));
      link(const Position(2, 6), const Position(3, 6));
    }

    fanTop();
    fanBottom();
    fanLeft();
    fanRight();

    return conn;
  }

  Map<Position, Map<Position, Position>> _buildTraditionalJumps() {
    final jumps = <Position, Map<Position, Position>>{};

    void addLine(List<Position> line) {
      _addCollinearLine(jumps, line);
    }

    // 5 Horizontal rows of 5x5 grid
    for (int r = 0; r < 5; r++) {
      addLine([for (int c = 0; c < 5; c++) Position(r, c)]);
    }

    // 5 Vertical columns of 5x5 grid
    for (int c = 0; c < 5; c++) {
      addLine([for (int r = 0; r < 5; r++) Position(r, c)]);
    }

    // Main diagonals
    addLine([
      const Position(0, 0),
      const Position(1, 1),
      const Position(2, 2),
      const Position(3, 3),
      const Position(4, 4),
    ]);
    addLine([
      const Position(0, 4),
      const Position(1, 3),
      const Position(2, 2),
      const Position(3, 1),
      const Position(4, 0),
    ]);

    // Inner diamond diagonals
    addLine([const Position(0, 2), const Position(1, 1), const Position(2, 0)]);
    addLine([const Position(0, 2), const Position(1, 3), const Position(2, 4)]);
    addLine([const Position(2, 0), const Position(3, 1), const Position(4, 2)]);
    addLine([const Position(2, 4), const Position(3, 3), const Position(4, 2)]);

    // Top fan lines & extensions through hub into grid:
    addLine([const Position(1, 3), const Position(0, 2), const Position(-1, 1), const Position(-2, 1)]);
    addLine([const Position(1, 2), const Position(0, 2), const Position(-1, 2), const Position(-2, 2)]);
    addLine([const Position(1, 1), const Position(0, 2), const Position(-1, 3), const Position(-2, 3)]);
    addLine([const Position(-1, 1), const Position(-1, 2), const Position(-1, 3)]);
    addLine([const Position(-2, 1), const Position(-2, 2), const Position(-2, 3)]);

    // Bottom fan lines & extensions through hub into grid:
    addLine([const Position(3, 3), const Position(4, 2), const Position(5, 1), const Position(6, 1)]);
    addLine([const Position(3, 2), const Position(4, 2), const Position(5, 2), const Position(6, 2)]);
    addLine([const Position(3, 1), const Position(4, 2), const Position(5, 3), const Position(6, 3)]);
    addLine([const Position(5, 1), const Position(5, 2), const Position(5, 3)]);
    addLine([const Position(6, 1), const Position(6, 2), const Position(6, 3)]);

    // Left fan lines & extensions through hub into grid:
    addLine([const Position(3, 1), const Position(2, 0), const Position(1, -1), const Position(1, -2)]);
    addLine([const Position(2, 1), const Position(2, 0), const Position(2, -1), const Position(2, -2)]);
    addLine([const Position(1, 1), const Position(2, 0), const Position(3, -1), const Position(3, -2)]);
    addLine([const Position(1, -1), const Position(2, -1), const Position(3, -1)]);
    addLine([const Position(1, -2), const Position(2, -2), const Position(3, -2)]);

    // Right fan lines & extensions through hub into grid:
    addLine([const Position(3, 3), const Position(2, 4), const Position(1, 5), const Position(1, 6)]);
    addLine([const Position(2, 3), const Position(2, 4), const Position(2, 5), const Position(2, 6)]);
    addLine([const Position(1, 3), const Position(2, 4), const Position(3, 5), const Position(3, 6)]);
    addLine([const Position(1, 5), const Position(2, 5), const Position(3, 5)]);
    addLine([const Position(1, 6), const Position(2, 6), const Position(3, 6)]);

    return jumps;
  }

  Map<Position, Map<Position, Position>> _buildPyramidJumps() {
    final jumps = <Position, Map<Position, Position>>{};

    void addLine(List<Position> line) {
      _addCollinearLine(jumps, line);
    }

    // Outer slants:
    addLine([const Position(0, 2), const Position(1, 1), const Position(2, 0), const Position(3, 0), const Position(4, 0)]);
    addLine([const Position(0, 2), const Position(1, 3), const Position(2, 4), const Position(3, 4), const Position(4, 4)]);

    // Columns:
    addLine([const Position(2, 0), const Position(3, 0), const Position(4, 0)]);
    addLine([const Position(1, 1), const Position(2, 1), const Position(3, 1), const Position(4, 1)]);
    addLine([const Position(2, 2), const Position(3, 2), const Position(4, 2)]);
    addLine([const Position(1, 3), const Position(2, 3), const Position(3, 3), const Position(4, 3)]);
    addLine([const Position(2, 4), const Position(3, 4), const Position(4, 4)]);

    // Rows:
    addLine([const Position(2, 0), const Position(2, 1), const Position(2, 2), const Position(2, 3), const Position(2, 4)]);
    addLine([const Position(3, 0), const Position(3, 1), const Position(3, 2), const Position(3, 3), const Position(3, 4)]);
    addLine([const Position(4, 0), const Position(4, 1), const Position(4, 2), const Position(4, 3), const Position(4, 4)]);

    return jumps;
  }

  Map<Position, Map<Position, Position>> _buildSquareJumps() {
    final jumps = <Position, Map<Position, Position>>{};

    void addLine(List<Position> line) {
      _addCollinearLine(jumps, line);
    }

    for (int r = 0; r < 5; r++) {
      addLine([for (int c = 0; c < 5; c++) Position(r, c)]);
    }
    for (int c = 0; c < 5; c++) {
      addLine([for (int r = 0; r < 5; r++) Position(r, c)]);
    }

    // Diagonals of 3+ points:
    addLine([const Position(0, 2), const Position(1, 3), const Position(2, 4)]);
    addLine([const Position(0, 1), const Position(1, 2), const Position(2, 3), const Position(3, 4)]);
    addLine([const Position(0, 0), const Position(1, 1), const Position(2, 2), const Position(3, 3), const Position(4, 4)]);
    addLine([const Position(1, 0), const Position(2, 1), const Position(3, 2), const Position(4, 3)]);
    addLine([const Position(2, 0), const Position(3, 1), const Position(4, 2)]);

    addLine([const Position(0, 2), const Position(1, 1), const Position(2, 0)]);
    addLine([const Position(0, 3), const Position(1, 2), const Position(2, 1), const Position(3, 0)]);
    addLine([const Position(0, 4), const Position(1, 3), const Position(2, 2), const Position(3, 1), const Position(4, 0)]);
    addLine([const Position(1, 4), const Position(2, 3), const Position(3, 2), const Position(4, 1)]);
    addLine([const Position(2, 4), const Position(3, 3), const Position(4, 2)]);

    return jumps;
  }

  /// Get all valid positions for this board
  List<Position> get allPositions => _connections.keys.toList();

  /// Get neighbors of a position
  List<Position> getNeighbors(Position pos) => _connections[pos] ?? [];

  /// Check if two positions are connected
  bool areConnected(Position a, Position b) {
    final neighbors = _connections[a];
    return neighbors?.contains(b) ?? false;
  }

  /// Check if a position is valid on this board
  bool isValidPosition(Position pos) => _connections.containsKey(pos);

  /// Get direction from one position to another (for capture checking)
  Position? getDirection(Position from, Position to) {
    if (!areConnected(from, to)) return null;
    return Position(to.row - from.row, to.col - from.col);
  }

  /// Get position after jumping over another (for tiger captures)
  Position? getJumpDestination(Position from, Position over) {
    final mappedDest = _jumps[from]?[over];
    if (mappedDest != null) {
      return mappedDest;
    }

    final direction = getDirection(from, over);
    if (direction == null) return null;

    final dest = Position(over.row + direction.row, over.col + direction.col);
    if (!isValidPosition(dest)) return null;
    if (!areConnected(over, dest)) return null;

    return dest;
  }
}
