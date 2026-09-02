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

/// Current player turn
enum PlayerTurn { tiger, goat }

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

  /// Serialize to a Firestore-friendly map
  Map<String, dynamic> toJson() => {
        'fromRow': from.row,
        'fromCol': from.col,
        'toRow': to.row,
        'toCol': to.col,
        'capturedAtRow': capturedAt?.row,
        'capturedAtCol': capturedAt?.col,
        'pieceType': pieceType.name,
      };

  /// Deserialize from a map produced by [toJson]
  factory Move.fromJson(Map<String, dynamic> json) => Move(
        from: Position(
          (json['fromRow'] as num).toInt(),
          (json['fromCol'] as num).toInt(),
        ),
        to: Position(
          (json['toRow'] as num).toInt(),
          (json['toCol'] as num).toInt(),
        ),
        capturedAt: json['capturedAtRow'] != null
            ? Position(
                (json['capturedAtRow'] as num).toInt(),
                (json['capturedAtCol'] as num).toInt(),
              )
            : null,
        pieceType: PieceType.values.firstWhere(
          (e) => e.name == json['pieceType'],
          orElse: () => PieceType.goat,
        ),
      );

  @override
  List<Object?> get props => [from, to, capturedAt, pieceType];

  @override
  String toString() => isCapture
      ? 'Move($pieceType: $from → $to, captured at $capturedAt)'
      : 'Move($pieceType: $from → $to)';
}

/// Game difficulty levels for AI
enum AIDifficulty {
  easy(name: 'Easy', depth: 1, description: 'For beginners'),
  medium(name: 'Medium', depth: 2, description: 'Casual play'),
  hard(name: 'Hard', depth: 3, description: 'Challenging'),
  expert(name: 'Expert', depth: 4, description: 'For masters');

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
    description: 'Advanced - 5 Tigers & 20 Goats',
    rows: 5,
    cols: 5,
    tigerCount: 5,
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

/// Timer presets for games with Fischer increment support
enum GameTimer {
  bullet(minutes: 1, incrementSeconds: 2, label: '1 min (+2s)'),
  twoMin(minutes: 2, incrementSeconds: 2, label: '2 min (+2s)'),
  blitz(minutes: 3, incrementSeconds: 2, label: '3 min (+2s)'),
  five(minutes: 5, incrementSeconds: 2, label: '5 min (+2s)'),
  ten(minutes: 10, incrementSeconds: 3, label: '10 min (+3s)'),
  fifteen(minutes: 15, incrementSeconds: 5, label: '15 min (+5s)'),
  thirty(minutes: 30, incrementSeconds: 5, label: '30 min (+5s)'),
  sixty(minutes: 60, incrementSeconds: 0, label: '1 hour'),
  unlimited(minutes: 0, incrementSeconds: 0, label: 'No limit');

  final int minutes;
  final int incrementSeconds;
  final String label;

  const GameTimer({
    required this.minutes,
    this.incrementSeconds = 0,
    required this.label,
  });

  Duration get duration => Duration(minutes: minutes);
  Duration get increment => Duration(seconds: incrementSeconds);
  bool get hasLimit => minutes > 0;
}

/// Tactical power-up abilities
enum PowerUpType {
  tigerRoar(
    name: 'Tiger Roar',
    description: 'Freezes an adjacent goat for 1 turn',
    icon: '⚡',
    turn: PlayerTurn.tiger,
  ),
  superPounce(
    name: 'Super Pounce',
    description: 'Leap over an empty spot (distance 2)',
    icon: '🐆',
    turn: PlayerTurn.tiger,
  ),
  hornShield(
    name: 'Horn Shield',
    description: 'Shields a goat from capture for 2 turns',
    icon: '🛡️',
    turn: PlayerTurn.goat,
  ),
  boulder(
    name: 'Boulder',
    description: 'Place a rock blocking an intersection for 3 turns',
    icon: '🪨',
    turn: PlayerTurn.goat,
  );

  final String name;
  final String description;
  final String icon;
  final PlayerTurn turn;

  const PowerUpType({
    required this.name,
    required this.description,
    required this.icon,
    required this.turn,
  });
}

/// Represents an active tactical effect on the board
class ActiveEffect extends Equatable {
  final PowerUpType type;
  final Position targetPosition;
  final int turnsRemaining;
  final PlayerTurn appliedBy;

  const ActiveEffect({
    required this.type,
    required this.targetPosition,
    required this.turnsRemaining,
    required this.appliedBy,
  });

  ActiveEffect copyWith({
    PowerUpType? type,
    Position? targetPosition,
    int? turnsRemaining,
    PlayerTurn? appliedBy,
  }) {
    return ActiveEffect(
      type: type ?? this.type,
      targetPosition: targetPosition ?? this.targetPosition,
      turnsRemaining: turnsRemaining ?? this.turnsRemaining,
      appliedBy: appliedBy ?? this.appliedBy,
    );
  }

  @override
  List<Object?> get props => [type, targetPosition, turnsRemaining, appliedBy];
}

/// Reason why a draw occurred
enum DrawReason {
  none,
  agreement,
  threefoldRepetition,
  stagnation,
  timeout,
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
