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
  final bool completed;
  final int attemptsUsed;
  final int movesTaken;
  final DateTime? completedAt;

  const ChallengeProgress({
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
      solution: const [
        Move(
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
      solution: const [
        Move(
          from: Position(1, 1),
          to: Position(2, 2),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.easy,
      rating: 900,
      explanation: 'Moving to the center creates threats in multiple directions!',
    ),
    Puzzle(
      id: 'puzzle_003',
      title: 'Corner Capture',
      description: 'Jump over the goat guarding the corner',
      position: _createCornerCapturePosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 4),
          to: Position(2, 2),
          capturedAt: Position(1, 3),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.easy,
      rating: 850,
      explanation: 'The tiger leaps along the diagonal to capture the goat at (1,3)!',
    ),
    Puzzle(
      id: 'puzzle_004',
      title: 'Straight Line',
      description: 'Capture the goat directly in front of you',
      position: _createStraightLinePosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 0),
          to: Position(2, 0),
          capturedAt: Position(1, 0),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.easy,
      rating: 850,
      explanation: 'A straight vertical jump captures the goat at (1,0)!',
    ),
    Puzzle(
      id: 'puzzle_005',
      title: 'Smart Start',
      description: 'Claim the centre square with your goat',
      position: _createSmartStartPosition(),
      playerRole: PieceType.goat,
      solution: const [
        Move(
          from: Position(-1, -1),
          to: Position(2, 2),
          pieceType: PieceType.goat,
        ),
      ],
      difficulty: ChallengeDifficulty.easy,
      rating: 750,
      explanation: 'The centre is the strongest square — it controls the whole board.',
    ),
    Puzzle(
      id: 'puzzle_006',
      title: 'Edge Capture',
      description: 'Snatch the goat on the edge of the board',
      position: _createEdgeCapturePosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(4, 0),
          to: Position(4, 2),
          capturedAt: Position(4, 1),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.easy,
      rating: 900,
      explanation: 'Along the bottom edge the tiger jumps over the goat at (4,1)!',
    ),
    Puzzle(
      id: 'puzzle_007',
      title: 'Center Strike',
      description: 'Leap straight up the middle column',
      position: _createCenterStrikePosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(4, 2),
          to: Position(2, 2),
          capturedAt: Position(3, 2),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.easy,
      rating: 850,
      explanation: 'The tiger at (4,2) jumps over the goat at (3,2) and lands on the centre!',
    ),
    Puzzle(
      id: 'puzzle_008',
      title: 'Top-Down Dip',
      description: 'Strike down the middle from the top edge',
      position: _createTopDownPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 2),
          to: Position(2, 2),
          capturedAt: Position(1, 2),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.easy,
      rating: 850,
      explanation: 'From the top-middle the tiger pounces over (1,2) onto the centre!',
    ),
    Puzzle(
      id: 'puzzle_009',
      title: 'Control the Pass',
      description: 'Anchor the left gateway with your goat',
      position: _createLeftFlankPosition(),
      playerRole: PieceType.goat,
      solution: const [
        Move(
          from: Position(-1, -1),
          to: Position(2, 0),
          pieceType: PieceType.goat,
        ),
      ],
      difficulty: ChallengeDifficulty.easy,
      rating: 780,
      explanation: 'The square (2,0) guards the whole left side of the diamond — deny it to the tigers.',
    ),
  ];

  static List<Puzzle> get intermediatePuzzles => [
    Puzzle(
      id: 'puzzle_101',
      title: 'Escape the Trap',
      description: 'Find the only move that keeps the tiger free',
      position: _createEscapePosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 0),
          to: Position(1, 1),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.medium,
      rating: 1250,
      explanation: 'Moving diagonally is the only way to maintain mobility!',
    ),
    Puzzle(
      id: 'puzzle_102',
      title: 'Hidden Threat',
      description: 'Slide into the centre to dominate the diagonals',
      position: _createHiddenThreatPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(3, 3),
          to: Position(2, 2),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.medium,
      rating: 1250,
      explanation: 'From the centre the tiger threatens every diagonal at once.',
    ),
    Puzzle(
      id: 'puzzle_103',
      title: 'Goat Defense',
      description: 'Step the threatened goat out of the tiger\'s strike line',
      position: _createGoatDefensePosition(),
      playerRole: PieceType.goat,
      solution: const [
        Move(
          from: Position(1, 1),
          to: Position(2, 1),
          pieceType: PieceType.goat,
        ),
      ],
      difficulty: ChallengeDifficulty.medium,
      rating: 1300,
      explanation: 'The goat escapes the diagonal strike aimed at the centre.',
    ),
    Puzzle(
      id: 'puzzle_104',
      title: 'Break the Net',
      description: 'Burst free from the trap with a capture',
      position: _createBreakNetPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 0),
          to: Position(2, 2),
          capturedAt: Position(1, 1),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.medium,
      rating: 1350,
      explanation: 'Hedged in on three sides, the tiger escapes by capturing the diagonal goat.',
    ),
    Puzzle(
      id: 'puzzle_105',
      title: 'The Patient Hunter',
      description: 'The direct jump is blocked — set up the capture in two moves',
      position: _createPatientHunterPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 0),
          to: Position(0, 1),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(0, 1),
          to: Position(2, 1),
          capturedAt: Position(1, 1),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.medium,
      rating: 1200,
      explanation: 'The direct jump is blocked by the goat behind — step to (0,1) first, then the diagonal capture opens up.',
    ),
    Puzzle(
      id: 'puzzle_106',
      title: 'Two-Step',
      description: 'The goat on the diagonal is shielded — sidestep, then strike',
      position: _createTwoStepPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(4, 4),
          to: Position(4, 3),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(4, 3),
          to: Position(2, 3),
          capturedAt: Position(3, 3),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.medium,
      rating: 1300,
      explanation: 'The diagonal goat is shielded by its friend — step sideways to (4,3), then leap down the column to capture.',
    ),
    Puzzle(
      id: 'puzzle_107',
      title: 'Around the Guard',
      description: 'The centre is blocked — slip right, then strike',
      position: _createAroundGuardPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(4, 2),
          to: Position(4, 3),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(4, 3),
          to: Position(2, 3),
          capturedAt: Position(3, 3),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.medium,
      rating: 1250,
      explanation: 'A goat blocks the jump to (2,2), so step sideways to (4,3) first, then leap up the column to capture at (2,3).',
    ),
    Puzzle(
      id: 'puzzle_108',
      title: 'Boomerang',
      description: 'Two captures that bend back across the board',
      position: _createBoomerangPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(4, 0),
          to: Position(2, 2),
          capturedAt: Position(3, 1),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(2, 2),
          to: Position(4, 4),
          capturedAt: Position(3, 3),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.medium,
      rating: 1350,
      explanation: 'The tiger rides the diagonal to the centre, then swings across to the far corner — two goats in two leaps.',
    ),
  ];

  static List<Puzzle> get advancedPuzzles => [
    Puzzle(
      id: 'puzzle_201',
      title: 'Perfect Trap',
      description: 'Place a goat to completely trap the tiger',
      position: _createTrapSetupPosition(),
      playerRole: PieceType.goat,
      solution: const [
        Move(
          from: Position(-1, -1),
          to: Position(1, 2),
          pieceType: PieceType.goat,
        ),
      ],
      difficulty: ChallengeDifficulty.hard,
      rating: 1550,
      explanation: 'This placement blocks all escape routes!',
    ),
    Puzzle(
      id: 'puzzle_202',
      title: 'Final Capture',
      description: 'Capture the fifth goat to win the game',
      position: _createFinalCapturePosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 0),
          to: Position(2, 2),
          capturedAt: Position(1, 1),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.hard,
      rating: 1500,
      explanation: 'Four goats already captured — this jump seals the victory!',
    ),
    Puzzle(
      id: 'puzzle_203',
      title: 'Silent Death',
      description: 'Place the final goat to seal the tiger\'s cage',
      position: _createSilentDeathPosition(),
      playerRole: PieceType.goat,
      solution: const [
        Move(
          from: Position(-1, -1),
          to: Position(2, 2),
          pieceType: PieceType.goat,
        ),
      ],
      difficulty: ChallengeDifficulty.hard,
      rating: 1600,
      explanation: 'The last goat closes the box — the corner tiger can no longer move or capture.',
    ),
    Puzzle(
      id: 'puzzle_204',
      title: 'Mastermind',
      description: 'Chain two captures down the long diagonal',
      position: _createMastermindPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 0),
          to: Position(2, 2),
          capturedAt: Position(1, 1),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(2, 2),
          to: Position(4, 4),
          capturedAt: Position(3, 3),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.expert,
      rating: 1650,
      explanation: 'Two captures in a row — the tiger feasts all the way down the diagonal.',
    ),
    Puzzle(
      id: 'puzzle_205',
      title: 'Feast on the Diagonal',
      description: 'Chain three captures down the board',
      position: _createFeastDiagonalPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 0),
          to: Position(2, 2),
          capturedAt: Position(1, 1),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(2, 2),
          to: Position(4, 4),
          capturedAt: Position(3, 3),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(4, 4),
          to: Position(2, 4),
          capturedAt: Position(3, 4),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.hard,
      rating: 1550,
      explanation: 'One capture opens the next — ride the diagonal to the corner, then double back for the final goat.',
    ),
    Puzzle(
      id: 'puzzle_206',
      title: 'The Long March',
      description: 'Three goats, three jumps — find the only opening that keeps the chain alive',
      position: _createLongMarchPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 4),
          to: Position(2, 2),
          capturedAt: Position(1, 3),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(2, 2),
          to: Position(4, 4),
          capturedAt: Position(3, 3),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(4, 4),
          to: Position(4, 2),
          capturedAt: Position(4, 3),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.expert,
      rating: 1700,
      explanation: 'A cross of captures — but only the right opening keeps all three goats in range.',
    ),
    Puzzle(
      id: 'puzzle_207',
      title: 'The Serpent',
      description: 'Three captures that slither across the board',
      position: _createSerpentPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(2, 0),
          to: Position(2, 2),
          capturedAt: Position(2, 1),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(2, 2),
          to: Position(4, 4),
          capturedAt: Position(3, 3),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(4, 4),
          to: Position(4, 2),
          capturedAt: Position(4, 3),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.hard,
      rating: 1600,
      explanation: 'A horizontal strike, a diagonal leap, then a sweep along the bottom edge — the serpent never stops moving.',
    ),
    Puzzle(
      id: 'puzzle_208',
      title: 'The Gauntlet',
      description: 'A four-move run that feints, leaps, and finishes the hunt',
      position: _createGauntletPosition(),
      playerRole: PieceType.tiger,
      solution: const [
        Move(
          from: Position(0, 2),
          to: Position(1, 2),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(1, 2),
          to: Position(3, 2),
          capturedAt: Position(2, 2),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(3, 2),
          to: Position(3, 4),
          capturedAt: Position(3, 3),
          pieceType: PieceType.tiger,
        ),
        Move(
          from: Position(3, 4),
          to: Position(1, 4),
          capturedAt: Position(2, 4),
          pieceType: PieceType.tiger,
        ),
      ],
      difficulty: ChallengeDifficulty.expert,
      rating: 1750,
      explanation: 'A quiet step to (1,2) sets up the whole run: down the column, across the row, and up the right edge — four goats, one tiger.',
    ),
  ];

  // Helper methods to create puzzle positions
  static GameState _createCapturePosition1() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(2, 2), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(2, 3), id: 'g0'),
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
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(1, 1), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(2, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(2, 3), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(1, 2), id: 'g2'),
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
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(2, 2), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(0, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(1, 0), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(0, 2), id: 'g2'),
        Piece(type: PieceType.goat, position: Position(2, 0), id: 'g3'),
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
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(2, 2), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(0, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(1, 0), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(1, 1), id: 'g2'),
      ],
      currentTurn: PlayerTurn.goat,
      phase: GamePhase.placement,
      winner: GameWinner.none,
      goatsPlaced: 3,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createCornerCapturePosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(1, 3), id: 'g0'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createStraightLinePosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(1, 0), id: 'g0'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createSmartStartPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(1, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(1, 3), id: 'g1'),
      ],
      currentTurn: PlayerTurn.goat,
      phase: GamePhase.placement,
      winner: GameWinner.none,
      goatsPlaced: 2,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createEdgeCapturePosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(4, 1), id: 'g0'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createHiddenThreatPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(3, 3), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't3'),
        Piece(type: PieceType.goat, position: Position(1, 3), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(3, 1), id: 'g1'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createGoatDefensePosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(1, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(2, 3), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(3, 1), id: 'g2'),
      ],
      currentTurn: PlayerTurn.goat,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createBreakNetPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(0, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(1, 0), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(1, 1), id: 'g2'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createFinalCapturePosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(1, 1), id: 'g0'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 4,
      moveHistory: [],
    );
  }

  static GameState _createSilentDeathPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(0, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(1, 0), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(1, 1), id: 'g2'),
        Piece(type: PieceType.goat, position: Position(0, 2), id: 'g3'),
        Piece(type: PieceType.goat, position: Position(2, 0), id: 'g4'),
      ],
      currentTurn: PlayerTurn.goat,
      phase: GamePhase.placement,
      winner: GameWinner.none,
      goatsPlaced: 5,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createMastermindPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.goat, position: Position(1, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(3, 3), id: 'g1'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createPatientHunterPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(1, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(2, 2), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(1, 2), id: 'g2'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createTwoStepPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't3'),
        Piece(type: PieceType.goat, position: Position(3, 3), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(3, 2), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(2, 2), id: 'g2'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createFeastDiagonalPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.goat, position: Position(1, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(3, 3), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(3, 4), id: 'g2'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createLongMarchPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.goat, position: Position(1, 3), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(3, 3), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(4, 3), id: 'g2'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createCenterStrikePosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(4, 2), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(3, 2), id: 'g0'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createTopDownPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 2), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(1, 2), id: 'g0'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createLeftFlankPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(1, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(1, 3), id: 'g1'),
      ],
      currentTurn: PlayerTurn.goat,
      phase: GamePhase.placement,
      winner: GameWinner.none,
      goatsPlaced: 2,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createAroundGuardPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(4, 2), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(3, 2), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(3, 3), id: 'g1'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createBoomerangPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't2'),
        Piece(type: PieceType.goat, position: Position(3, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(3, 3), id: 'g1'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createSerpentPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(2, 0), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(0, 4), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't3'),
        Piece(type: PieceType.goat, position: Position(2, 1), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(3, 3), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(4, 3), id: 'g2'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }

  static GameState _createGauntletPosition() {
    return const GameState(
      level: BoardLevel.traditional,
      pieces: [
        Piece(type: PieceType.tiger, position: Position(0, 2), id: 't0'),
        Piece(type: PieceType.tiger, position: Position(0, 0), id: 't1'),
        Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        Piece(type: PieceType.goat, position: Position(2, 2), id: 'g0'),
        Piece(type: PieceType.goat, position: Position(3, 3), id: 'g1'),
        Piece(type: PieceType.goat, position: Position(2, 4), id: 'g2'),
      ],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: [],
    );
  }
}
