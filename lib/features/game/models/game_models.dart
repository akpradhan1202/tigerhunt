import 'package:equatable/equatable.dart';

/// Represents a position on the game board
class Position extends Equatable {
  final int row;
  final int col;

  const Position(this.row, this.col);

  @override
  List<Object?> get props => [row, col];

  @override
  String toString() => 'Position($row, $col)';

  Position operator +(Position other) => Position(row + other.row, col + other.col);
  Position operator -(Position other) => Position(row - other.row, col - other.col);
  Position operator *(int scalar) => Position(row * scalar, col * scalar);

  /// Calculate distance to another position
  double distanceTo(Position other) {
    final dx = (col - other.col).abs();
    final dy = (row - other.row).abs();
    return (dx * dx + dy * dy).toDouble();
  }

  /// Check if position is adjacent to another
  bool isAdjacentTo(Position other) {
    final dx = (col - other.col).abs();
    final dy = (row - other.row).abs();
    return dx <= 1 && dy <= 1 && (dx + dy > 0);
  }
}

/// Types of pieces in the game
enum PieceType { tiger, goat }

/// Represents a game piece
class Piece extends Equatable {
  final PieceType type;
  final Position position;
  final String id;
  final bool isCaptured;

  const Piece({
    required this.type,
    required this.position,
    required this.id,
    this.isCaptured = false,
  });

  Piece copyWith({
    PieceType? type,
    Position? position,
    String? id,
    bool? isCaptured,
  }) {
    return Piece(
      type: type ?? this.type,
      position: position ?? this.position,
      id: id ?? this.id,
      isCaptured: isCaptured ?? this.isCaptured,
    );
  }

  @override
  List<Object?> get props => [type, position, id, isCaptured];

  @override
  String toString() => 'Piece($type at $position, captured: $isCaptured)';
}

/// Represents a move in the game
class Move extends Equatable {
  final Position from;
  final Position to;
  final Position? capturedAt; // Position of captured goat (if any)
  final PieceType pieceType;

  const Move({
    required this.from,
    required this.to,
    this.capturedAt,
    required this.pieceType,
  });

  bool get isCapture => capturedAt != null;
  bool get isPlacement => from == const Position(-1, -1); // Special case for goat placement

  @override
  List<Object?> get props => [from, to, capturedAt, pieceType];

  @override
  String toString() => isCapture
      ? 'Move($pieceType: $from → $to, captured at $capturedAt)'
      : 'Move($pieceType: $from → $to)';
}

/// Game difficulty levels for AI
enum AIDifficulty {
  easy(name: 'Easy', depth: 2, description: 'For beginners'),
  medium(name: 'Medium', depth: 4, description: 'Casual play'),
  hard(name: 'Hard', depth: 6, description: 'Challenging'),
  expert(name: 'Expert', depth: 8, description: 'For masters');

  final String name;
  final int depth;
  final String description;

  const AIDifficulty({
    required this.name,
    required this.depth,
    required this.description,
  });
}

/// Board level types
enum BoardLevel {
  pyramid(
    name: 'Pyramid',
    description: 'Beginner - Triangle board',
    rows: 5,
    cols: 5,
    tigerCount: 3,
    goatCount: 15,
    goatsToWin: 5,
  ),
  square(
    name: 'Square',
    description: 'Intermediate - Square grid with diagonals',
    rows: 5,
    cols: 5,
    tigerCount: 4,
    goatCount: 16,
    goatsToWin: 5,
  ),
  traditional(
    name: 'Traditional',
    description: 'Advanced - Classic Bagh-Chal',
    rows: 5,
    cols: 5,
    tigerCount: 4,
    goatCount: 20,
    goatsToWin: 5,
  );

  final String name;
  final String description;
  final int rows;
  final int cols;
  final int tigerCount;
  final int goatCount;
  final int goatsToWin;

  const BoardLevel({
    required this.name,
    required this.description,
    required this.rows,
    required this.cols,
    required this.tigerCount,
    required this.goatCount,
    required this.goatsToWin,
  });
}

/// Timer presets for games
enum GameTimer {
  five(minutes: 5, label: '5 min'),
  ten(minutes: 10, label: '10 min'),
  fifteen(minutes: 15, label: '15 min'),
  thirty(minutes: 30, label: '30 min'),
  sixty(minutes: 60, label: '1 hour'),
  unlimited(minutes: 0, label: 'No limit');

  final int minutes;
  final String label;

  const GameTimer({required this.minutes, required this.label});

  Duration get duration => Duration(minutes: minutes);
  bool get hasLimit => minutes > 0;
}

/// Game mode types
enum GameMode {
  offline('Offline', 'Play against AI or locally'),
  online('Online', 'Play with friends or strangers'),
  tutorial('Tutorial', 'Learn how to play');

  final String name;
  final String description;

  const GameMode(this.name, this.description);
}

/// Online match types
enum OnlineMatchType {
  random('Random', 'Play with a stranger'),
  friend('With Friend', 'Invite a friend with code'),
  ranked('Ranked', 'Competitive matches');

  final String name;
  final String description;

  const OnlineMatchType(this.name, this.description);
}
