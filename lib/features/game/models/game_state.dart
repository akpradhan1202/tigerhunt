import 'package:equatable/equatable.dart';
import 'game_models.dart';

/// Current phase of the game
enum GamePhase {
  placement, // Goats are being placed on the board
  movement,  // All goats placed, now both sides move
  ended,     // Game is over
}

/// Who won the game
enum GameWinner {
  tigers,    // Tigers captured enough goats
  goats,     // Goats trapped all tigers
  draw,      // Time ran out or stalemate
  none,      // Game still in progress
}

/// Complete game state
class GameState extends Equatable {
  final BoardLevel level;
  final List<Piece> pieces;
  final PlayerTurn currentTurn;
  final GamePhase phase;
  final GameWinner winner;
  final DrawReason drawReason;
  final int goatsPlaced;
  final int goatsCaptured;
  final List<Move> moveHistory;
  final Duration? tigerTimeRemaining;
  final Duration? goatTimeRemaining;
  final bool isPaused;
  final Map<String, int> positionHistory;
  final int movesWithoutCapture;
  final List<ActiveEffect> activeEffects;
  final Set<Position> collapsedPositions;
  final Map<PlayerTurn, Set<PowerUpType>> usedPowerUps;

  const GameState({
    required this.level,
    required this.pieces,
    required this.currentTurn,
    required this.phase,
    required this.winner,
    this.drawReason = DrawReason.none,
    required this.goatsPlaced,
    required this.goatsCaptured,
    required this.moveHistory,
    this.tigerTimeRemaining,
    this.goatTimeRemaining,
    this.isPaused = false,
    this.positionHistory = const {},
    this.movesWithoutCapture = 0,
    this.activeEffects = const [],
    this.collapsedPositions = const {},
    this.usedPowerUps = const {
      PlayerTurn.tiger: {},
      PlayerTurn.goat: {},
    },
  });

  /// Create initial game state for a level
  factory GameState.initial(BoardLevel level, {GameTimer? timer}) {
    final tigers = <Piece>[];

    // Place tigers at corners based on board level
    switch (level) {
      case BoardLevel.pyramid:
        // 3 tigers at the three corners of the pyramid
        tigers.addAll([
          const Piece(type: PieceType.tiger, position: Position(0, 2), id: 'tiger_0'),
          const Piece(type: PieceType.tiger, position: Position(4, 0), id: 'tiger_1'),
          const Piece(type: PieceType.tiger, position: Position(4, 4), id: 'tiger_2'),
        ]);
        break;
      case BoardLevel.square:
        // 4 tigers at corners
        tigers.addAll([
          const Piece(type: PieceType.tiger, position: Position(0, 0), id: 'tiger_0'),
          const Piece(type: PieceType.tiger, position: Position(0, 4), id: 'tiger_1'),
          const Piece(type: PieceType.tiger, position: Position(4, 0), id: 'tiger_2'),
          const Piece(type: PieceType.tiger, position: Position(4, 4), id: 'tiger_3'),
        ]);
        break;
      case BoardLevel.traditional:
        // 5 tigers: 4 corners + 1 center anchor (2, 2)
        tigers.addAll([
          const Piece(type: PieceType.tiger, position: Position(0, 0), id: 'tiger_0'),
          const Piece(type: PieceType.tiger, position: Position(0, 4), id: 'tiger_1'),
          const Piece(type: PieceType.tiger, position: Position(4, 0), id: 'tiger_2'),
          const Piece(type: PieceType.tiger, position: Position(4, 4), id: 'tiger_3'),
          const Piece(type: PieceType.tiger, position: Position(2, 2), id: 'tiger_4'),
        ]);
        break;
    }

    final initial = GameState(
      level: level,
      pieces: tigers,
      currentTurn: PlayerTurn.goat, // Goats always move first
      phase: GamePhase.placement,
      winner: GameWinner.none,
      drawReason: DrawReason.none,
      goatsPlaced: 0,
      goatsCaptured: 0,
      moveHistory: const [],
      tigerTimeRemaining: timer?.hasLimit == true ? timer!.duration : null,
      goatTimeRemaining: timer?.hasLimit == true ? timer!.duration : null,
      positionHistory: const {},
      movesWithoutCapture: 0,
      activeEffects: const [],
      collapsedPositions: const {},
      usedPowerUps: const {
        PlayerTurn.tiger: {},
        PlayerTurn.goat: {},
      },
    );

    return initial.copyWith(
      positionHistory: {initial.stateSignature: 1},
    );
  }

  /// Get canonical state signature for threefold repetition
  String get stateSignature {
    final tigerPos = tigers.map((t) => '${t.position.row},${t.position.col}').toList()..sort();
    final goatPos = goatsOnBoard.map((g) => '${g.position.row},${g.position.col}').toList()..sort();
    return '${currentTurn.name}|${phase.name}|$goatsToPlace|T:[${tigerPos.join(';')}]|G:[${goatPos.join(';')}]';
  }

  /// Get all active tigers
  List<Piece> get tigers => pieces
      .where((p) => p.type == PieceType.tiger && !p.isCaptured)
      .toList();

  /// Get all active goats on board
  List<Piece> get goatsOnBoard => pieces
      .where((p) => p.type == PieceType.goat && !p.isCaptured)
      .toList();

  /// Get total goats remaining (placed - captured)
  int get goatsRemaining => goatsPlaced - goatsCaptured;

  /// Get goats waiting to be placed
  int get goatsToPlace => level.goatCount - goatsPlaced;

  /// Check if all goats have been placed
  bool get allGoatsPlaced => goatsPlaced >= level.goatCount;

  /// Check if a position has an active boulder
  bool isBoulderAt(Position pos) =>
      activeEffects.any((e) => e.type == PowerUpType.boulder && e.targetPosition == pos);

  /// Check if a goat is shielded
  bool isGoatShielded(Position pos) =>
      activeEffects.any((e) => e.type == PowerUpType.hornShield && e.targetPosition == pos);

  /// Check if a goat is frozen/stunned
  bool isGoatStunned(Position pos) =>
      activeEffects.any((e) => e.type == PowerUpType.tigerRoar && e.targetPosition == pos);

  /// Check if a position has collapsed (Sudden Death)
  bool isPositionCollapsed(Position pos) => collapsedPositions.contains(pos);

  /// Get piece at position
  Piece? getPieceAt(Position pos) {
    for (final piece in pieces) {
      if (piece.position == pos && !piece.isCaptured) {
        return piece;
      }
    }
    return null;
  }

  /// Check if position is empty (no piece, no boulder, and not collapsed)
  bool isPositionEmpty(Position pos) =>
      getPieceAt(pos) == null && !isBoulderAt(pos) && !isPositionCollapsed(pos);

  /// Check if it's game over
  bool get isGameOver => winner != GameWinner.none;

  /// Create copy with modifications
  GameState copyWith({
    BoardLevel? level,
    List<Piece>? pieces,
    PlayerTurn? currentTurn,
    GamePhase? phase,
    GameWinner? winner,
    DrawReason? drawReason,
    int? goatsPlaced,
    int? goatsCaptured,
    List<Move>? moveHistory,
    Duration? tigerTimeRemaining,
    Duration? goatTimeRemaining,
    bool? isPaused,
    Map<String, int>? positionHistory,
    int? movesWithoutCapture,
    List<ActiveEffect>? activeEffects,
    Set<Position>? collapsedPositions,
    Map<PlayerTurn, Set<PowerUpType>>? usedPowerUps,
  }) {
    return GameState(
      level: level ?? this.level,
      pieces: pieces ?? this.pieces,
      currentTurn: currentTurn ?? this.currentTurn,
      phase: phase ?? this.phase,
      winner: winner ?? this.winner,
      drawReason: drawReason ?? this.drawReason,
      goatsPlaced: goatsPlaced ?? this.goatsPlaced,
      goatsCaptured: goatsCaptured ?? this.goatsCaptured,
      moveHistory: moveHistory ?? this.moveHistory,
      tigerTimeRemaining: tigerTimeRemaining ?? this.tigerTimeRemaining,
      goatTimeRemaining: goatTimeRemaining ?? this.goatTimeRemaining,
      isPaused: isPaused ?? this.isPaused,
      positionHistory: positionHistory ?? this.positionHistory,
      movesWithoutCapture: movesWithoutCapture ?? this.movesWithoutCapture,
      activeEffects: activeEffects ?? this.activeEffects,
      collapsedPositions: collapsedPositions ?? this.collapsedPositions,
      usedPowerUps: usedPowerUps ?? this.usedPowerUps,
    );
  }

  @override
  List<Object?> get props => [
        level,
        pieces,
        currentTurn,
        phase,
        winner,
        drawReason,
        goatsPlaced,
        goatsCaptured,
        moveHistory,
        tigerTimeRemaining,
        goatTimeRemaining,
        isPaused,
        positionHistory,
        movesWithoutCapture,
        activeEffects,
        collapsedPositions,
        usedPowerUps,
      ];
}
