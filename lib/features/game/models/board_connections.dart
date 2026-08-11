import 'game_models.dart';
import 'game_state.dart';

/// Defines valid connections for each board type
class BoardConnections {
  final BoardLevel level;
  late final Map<Position, List<Position>> _connections;

  BoardConnections(this.level) {
    _connections = _buildConnections();
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

  /// Pyramid board: Triangle shape
  ///        (0,2)
  ///       /    \
  ///    (1,1)--(1,3)
  ///     /  \  /  \
  ///  (2,0)-(2,2)-(2,4)
  ///    | \ | / | \ |
  ///  (3,0)-(3,1)-(3,2)-(3,3)-(3,4)
  ///    |   |   |   |   |
  ///  (4,0)-(4,1)-(4,2)-(4,3)-(4,4)
  Map<Position, List<Position>> _buildPyramidConnections() {
    final Map<Position, List<Position>> conn = {};

    // Top apex
    conn[const Position(0, 2)] = [
      const Position(1, 1),
      const Position(1, 3),
    ];

    // Second row
    conn[const Position(1, 1)] = [
      const Position(0, 2),
      const Position(1, 3),
      const Position(2, 0),
      const Position(2, 2),
    ];
    conn[const Position(1, 3)] = [
      const Position(0, 2),
      const Position(1, 1),
      const Position(2, 2),
      const Position(2, 4),
    ];

    // Third row
    conn[const Position(2, 0)] = [
      const Position(1, 1),
      const Position(2, 2),
      const Position(3, 0),
      const Position(3, 1),
    ];
    conn[const Position(2, 2)] = [
      const Position(1, 1),
      const Position(1, 3),
      const Position(2, 0),
      const Position(2, 4),
      const Position(3, 1),
      const Position(3, 2),
      const Position(3, 3),
    ];
    conn[const Position(2, 4)] = [
      const Position(1, 3),
      const Position(2, 2),
      const Position(3, 3),
      const Position(3, 4),
    ];

    // Fourth row (full)
    for (int col = 0; col < 5; col++) {
      final pos = Position(3, col);
      final neighbors = <Position>[];
      if (col > 0) neighbors.add(Position(3, col - 1));
      if (col < 4) neighbors.add(Position(3, col + 1));
      neighbors.add(Position(4, col));

      // Diagonal connections to row 2
      if (col == 0) neighbors.add(const Position(2, 0));
      if (col == 1) {
        neighbors.add(const Position(2, 0));
        neighbors.add(const Position(2, 2));
      }
      if (col == 2) neighbors.add(const Position(2, 2));
      if (col == 3) {
        neighbors.add(const Position(2, 2));
        neighbors.add(const Position(2, 4));
      }
      if (col == 4) neighbors.add(const Position(2, 4));

      conn[pos] = neighbors;
    }

    // Fifth row (base)
    for (int col = 0; col < 5; col++) {
      final pos = Position(4, col);
      final neighbors = <Position>[Position(3, col)];
      if (col > 0) neighbors.add(Position(4, col - 1));
      if (col < 4) neighbors.add(Position(4, col + 1));
      conn[pos] = neighbors;
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

  /// Traditional Bagh-Chal board with triangle extensions
  /// Main 5x5 grid plus 4 triangular extensions on each side
  Map<Position, List<Position>> _buildTraditionalConnections() {
    final Map<Position, List<Position>> conn = {};

    // Main 5x5 grid positions
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        final pos = Position(row, col);
        final neighbors = <Position>[];

        // Orthogonal connections (all positions)
        if (row > 0) neighbors.add(Position(row - 1, col));
        if (row < 4) neighbors.add(Position(row + 1, col));
        if (col > 0) neighbors.add(Position(row, col - 1));
        if (col < 4) neighbors.add(Position(row, col + 1));

        // Diagonal connections only where (row+col) is even
        // This creates the traditional pattern
        if ((row + col) % 2 == 0) {
          if (row > 0 && col > 0) neighbors.add(Position(row - 1, col - 1));
          if (row > 0 && col < 4) neighbors.add(Position(row - 1, col + 1));
          if (row < 4 && col > 0) neighbors.add(Position(row + 1, col - 1));
          if (row < 4 && col < 4) neighbors.add(Position(row + 1, col + 1));
        }

        conn[pos] = neighbors;
      }
    }

    // ========== TRIANGLE EXTENSION POSITIONS ==========
    // Using negative/extended coordinates for triangle positions
    // Top triangle: row -1 positions
    // Bottom triangle: row 5 positions
    // Left triangle: col -1 positions
    // Right triangle: col 5 positions

    // TOP TRIANGLE (3 new positions)
    // Apex at (-1, 2)
    conn[const Position(-1, 2)] = [
      const Position(0, 1),  // connects to grid
      const Position(0, 2),  // connects to grid center
      const Position(0, 3),  // connects to grid
    ];
    // Update grid positions to connect to triangle
    conn[const Position(0, 1)]!.add(const Position(-1, 2));
    conn[const Position(0, 2)]!.add(const Position(-1, 2));
    conn[const Position(0, 3)]!.add(const Position(-1, 2));

    // BOTTOM TRIANGLE (3 new positions)
    // Apex at (5, 2)
    conn[const Position(5, 2)] = [
      const Position(4, 1),
      const Position(4, 2),
      const Position(4, 3),
    ];
    conn[const Position(4, 1)]!.add(const Position(5, 2));
    conn[const Position(4, 2)]!.add(const Position(5, 2));
    conn[const Position(4, 3)]!.add(const Position(5, 2));

    // LEFT TRIANGLE (3 new positions)
    // Apex at (2, -1)
    conn[const Position(2, -1)] = [
      const Position(1, 0),
      const Position(2, 0),
      const Position(3, 0),
    ];
    conn[const Position(1, 0)]!.add(const Position(2, -1));
    conn[const Position(2, 0)]!.add(const Position(2, -1));
    conn[const Position(3, 0)]!.add(const Position(2, -1));

    // RIGHT TRIANGLE (3 new positions)
    // Apex at (2, 5)
    conn[const Position(2, 5)] = [
      const Position(1, 4),
      const Position(2, 4),
      const Position(3, 4),
    ];
    conn[const Position(1, 4)]!.add(const Position(2, 5));
    conn[const Position(2, 4)]!.add(const Position(2, 5));
    conn[const Position(3, 4)]!.add(const Position(2, 5));

    return conn;
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
    final direction = getDirection(from, over);
    if (direction == null) return null;

    final dest = Position(over.row + direction.row, over.col + direction.col);
    if (!isValidPosition(dest)) return null;
    if (!areConnected(over, dest)) return null;

    return dest;
  }
}
