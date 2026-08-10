import 'package:equatable/equatable.dart';
import '../../game/models/game_models.dart';
import '../../game/models/game_state.dart';

/// Types of challenges
enum ChallengeType {
  trapTiger('Trap the Tiger', 'Trap the specified tiger in X moves'),
  captureGoats('Capture Goats', 'Capture X goats as Tiger'),
  surviveAsGoat('Survive', 'Don\'t lose any goats for X moves'),
  winInMoves('Quick Win', 'Win the game in X moves or less'),
  puzzle('Puzzle', 'Find the winning move');

  final String name;
  final String description;

  const ChallengeType(this.name, this.description);
}

/// Difficulty of challenges
enum ChallengeDifficulty {
  easy(1, 'Easy', 50),
  medium(2, 'Medium', 100),
  hard(3, 'Hard', 200),
  expert(4, 'Expert', 500);

  final int level;
  final String name;
  final int baseReward;

  const ChallengeDifficulty(this.level, this.name, this.baseReward);
}

/// A daily challenge
class DailyChallenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final GameState initialState;
  final int targetMoves;
  final int rewardPoints;
  final DateTime date;
  final List<Position>? highlightPositions;
  final String? hint;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.initialState,
    required this.targetMoves,
    required this.rewardPoints,
    required this.date,
    this.highlightPositions,
    this.hint,
  });

  @override
  List<Object?> get props => [id, date];
}

/// User's progress on a challenge
class ChallengeProgress {
  final String odStatsId;
  final String odStatsId;
  final bool completed;
  final int attemptsUsed;
  final int movesTaken;
  final DateTime? completedAt;

  const ChallengeProgress({
    required this.odStatsId,
    required this.odStatsId,
    required this.completed,
    required this.attemptsUsed,
    this.movesTaken = 0,
    this.completedAt,
  });
}

/// Puzzle (tactical position to solve)
class Puzzle extends Equatable {
  final String id;
  final String title;
  final String description;
  final GameState position;
  final PieceType playerRole;
  final List<Move> solution;
  final ChallengeDifficulty difficulty;
  final int rating; // Puzzle rating for matching
  final String? explanation;

  const Puzzle({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.playerRole,
    required this.solution,
    required this.difficulty,
    required this.rating,
    this.explanation,
  });

  int get solutionLength => solution.length;

  @override
  List<Object?> get props => [id];
}

/// Pre-defined puzzles
class PuzzleLibrary {
  static List<Puzzle> get beginnerPuzzles => [
    Puzzle(
      id: 'puzzle_001',
      title: 'First Capture',
      description: 'Find the move to capture a goat',
      position: _createCapturePosition1(),
      playerRole: PieceType.tiger,
      solution: [
        const Move(
          from: Position(2, 2),
          to: Position(2, 4),
          capturedAt: Position(2, 3),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.easy,
      rating: 800,
      explanation: 'The tiger at (2,2) can jump over the goat at (2,3) to capture it!',
    ),
    Puzzle(
      id: 'puzzle_002',
      title: 'Double Threat',
      description: 'Set up a position where tiger threatens two captures',
      position: _createDoubleThreatPosition(),
      playerRole: PieceType.tiger,
      solution: [
        const Move(
          from: Position(1, 1),
          to: Position(2, 2),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.easy,
      rating: 900,
      explanation: 'Moving to the center creates threats in multiple directions!',
    ),
  ];

  static List<Puzzle> get intermediatePuzzles => [
    Puzzle(
      id: 'puzzle_101',
      title: 'Escape the Trap',
      description: 'Find the only move that keeps the tiger free',
      position: _createEscapePosition(),
      playerRole: PieceType.tiger,
      solution: [
        const Move(
          from: Position(0, 0),
          to: Position(1, 1),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.medium,
      rating: 1200,
      explanation: 'Moving diagonally is the only way to maintain mobility!',
    ),
  ];

  static List<Puzzle> get advancedPuzzles => [
    Puzzle(
      id: 'puzzle_201',
      title: 'Perfect Trap',
      description: 'Place a goat to completely trap the tiger',
      position: _createTrapSetupPosition(),
      playerRole: PieceType.goat,
      solution: [
        const Move(
          from: Position(-1, -1),
          to: Position(1, 2),
          pieceType: PieceType.goat,
        ),
      ],
      difficulty: ChallengeDifficulty.hard,
      rating: 1500,
      explanation: 'This placement blocks all escape routes!',
    ),
  ];

  // Helper methods to create puzzle positions
  static GameState _createCapturePosition1() {
    return GameState(
      level: BoardLevel.traditional,
      pieces: [
        const Piece(type: PieceType.tiger, position: Position(2, 2), id: 't0'),
        const Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        const Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        const Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        const Piece(type: PieceType.goat, position: Position(2, 3), id: 'g0'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createDoubleThreatPosition() {
    return GameState(
      level: BoardLevel.traditional,
      pieces: [
        const Piece(type: PieceType.tiger, position: Position(1, 1), id: 't0'),
        const Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        const Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        const Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        const Piece(type: PieceType.goat, position: Position(2, 1), id: 'g0'),
        const Piece(type: PieceType.goat, position: Position(2, 3), id: 'g1'),
        const Piece(type: PieceType.goat, position: Position(1, 2), id: 'g2'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createEscapePosition() {
    return GameState(
      level: BoardLevel.traditional,
      pieces: [
        const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        const Piece(type: PieceType.tiger, position: Position(2, 2), id: 't1'),
        const Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        const Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        const Piece(type: PieceType.goat, position: Position(0, 1), id: 'g0'),
        const Piece(type: PieceType.goat, position: Position(1, 0), id: 'g1'),
        const Piece(type: PieceType.goat, position: Position(0, 2), id: 'g2'),
        const Piece(type: PieceType.goat, position: Position(2, 0), id: 'g3'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createTrapSetupPosition() {
    return GameState(
      level: BoardLevel.traditional,
      pieces: [
        const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        const Piece(type: PieceType.tiger, position: Position(2, 2), id: 't1'),
        const Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        const Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        const Piece(type: PieceType.goat, position: Position(0, 1), id: 'g0'),
        const Piece(type: PieceType.goat, position: Position(1, 0), id: 'g1'),
        const Piece(type: PieceType.goat, position: Position(1, 1), id: 'g2'),
      ],
      currentTurn: PlayerTurn.goat,
      phase: GamePhase.placement,
      winner: GameWinner.none,
      goatsPlaced: 3,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }
}
