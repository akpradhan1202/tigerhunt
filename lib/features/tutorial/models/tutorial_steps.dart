import 'package:flutter/material.dart';
import '../../game/models/game_models.dart';
import '../../game/models/game_state.dart';

/// A single tutorial step
class TutorialStep {
  final String title;
  final String description;
  final String? tip;
  final GameState? setupState;
  final Position? highlightPosition;
  final List<Move>? highlightMoves;
  final bool showHand;
  final Position? handTarget;
  final Rect? overlayArea;

  const TutorialStep({
    required this.title,
    required this.description,
    this.tip,
    this.setupState,
    this.highlightPosition,
    this.highlightMoves,
    this.showHand = false,
    this.handTarget,
    this.overlayArea,
  });
}

/// All tutorial steps
class TutorialSteps {
  static List<TutorialStep> get allSteps => [
        // Step 1: Introduction
        const TutorialStep(
          title: 'Welcome to TigerHunt! 🐯🐐',
          description:
              'TigerHunt is an ancient Indian strategy game also known as '
              'Bagh-Chal (बाघ छाल). One player controls 4 tigers, '
              'the other controls 20 goats.',
          tip: 'This game has been played in Nepal for centuries!',
        ),

        // Step 2: The Board
        const TutorialStep(
          title: 'The Game Board',
          description:
              'The board has 25 intersection points connected by lines. '
              'Pieces move along these lines from one intersection to another.',
          tip: 'The diagonal lines allow for more strategic movement!',
        ),

        // Step 3: Tigers Starting Position
        TutorialStep(
          title: 'Tigers Start at Corners',
          description:
              'The 4 tigers begin at the four corners of the board. '
              'They\'re ready to hunt!',
          setupState: GameState.initial(BoardLevel.traditional),
          tip: 'Tigers are powerful but surrounded!',
        ),

        // Step 4: Goats Enter First
        TutorialStep(
          title: 'Goats Move First',
          description:
              'The goat player places one goat per turn on any empty intersection. '
              'All 20 goats must be placed before they can move.',
          setupState: GameState.initial(BoardLevel.traditional),
          showHand: true,
          handTarget: const Position(2, 2),
          tip: 'Place goats strategically to block tigers!',
        ),

        // Step 5: Tiger Movement
        TutorialStep(
          title: 'How Tigers Move',
          description:
              'Tigers can move to any adjacent empty intersection along a line. '
              'They can move diagonally where diagonal lines exist.',
          setupState: _createTigerMoveDemo(),
          highlightPosition: const Position(0, 0),
          highlightMoves: [
            const Move(
              from: Position(0, 0),
              to: Position(0, 1),
              pieceType: PieceType.tiger,
            ),
            const Move(
              from: Position(0, 0),
              to: Position(1, 0),
              pieceType: PieceType.tiger,
            ),
            const Move(
              from: Position(0, 0),
              to: Position(1, 1),
              pieceType: PieceType.tiger,
            ),
          ],
        ),

        // Step 6: Tiger Capture (The Hunt!)
        TutorialStep(
          title: 'Tigers Hunt by Jumping! 🎯',
          description:
              'A tiger captures a goat by jumping over it to an empty space. '
              'Just like in checkers! The captured goat is removed.',
          setupState: _createCaptureDemo(),
          highlightPosition: const Position(2, 2),
          highlightMoves: [
            const Move(
              from: Position(2, 2),
              to: Position(2, 4),
              capturedAt: Position(2, 3),
              pieceType: PieceType.tiger,
            ),
          ],
          tip: 'Tigers can capture in any direction with a line!',
        ),

        // Step 7: Capture Rules
        const TutorialStep(
          title: 'Capture Rules',
          description:
              '• Tigers can capture from their very first move\n'
              '• Only one goat can be captured per turn\n'
              '• The landing space must be empty\n'
              '• Capturing is optional (not forced)',
          tip: 'Unlike checkers, you don\'t HAVE to capture!',
        ),

        // Step 8: Goat Movement
        TutorialStep(
          title: 'How Goats Move',
          description:
              'After all 20 goats are placed, goats can move. '
              'They move like tigers - one step along a line - but they CANNOT jump!',
          setupState: _createGoatMoveDemo(),
          highlightPosition: const Position(2, 2),
          highlightMoves: [
            const Move(
              from: Position(2, 2),
              to: Position(2, 1),
              pieceType: PieceType.goat,
            ),
            const Move(
              from: Position(2, 2),
              to: Position(1, 2),
              pieceType: PieceType.goat,
            ),
            const Move(
              from: Position(2, 2),
              to: Position(2, 3),
              pieceType: PieceType.goat,
            ),
            const Move(
              from: Position(2, 2),
              to: Position(3, 2),
              pieceType: PieceType.goat,
            ),
          ],
        ),

        // Step 9: Winning - Tigers
        const TutorialStep(
          title: 'Tigers Win By Hunting',
          description:
              'Tigers win if they capture 5 goats. '
              'That\'s enough to weaken the herd and escape!',
          tip: 'Even 1-2 early captures give tigers a big advantage.',
        ),

        // Step 10: Winning - Goats
        TutorialStep(
          title: 'Goats Win By Trapping',
          description:
              'Goats win if they surround ALL 4 tigers so none can move. '
              'Work together to corner them!',
          setupState: _createTrappedTigerDemo(),
          tip: 'Sacrifice a few goats to trap the tigers!',
        ),

        // Step 11: Strategy Tips - Tigers
        const TutorialStep(
          title: 'Tiger Strategy 🐯',
          description:
              '• Stay mobile - don\'t get cornered\n'
              '• Look for capture opportunities\n'
              '• Keep tigers working together\n'
              '• Control the center of the board',
          tip: 'Early captures make winning much easier!',
        ),

        // Step 12: Strategy Tips - Goats
        const TutorialStep(
          title: 'Goat Strategy 🐐',
          description:
              '• Place goats to limit tiger movement\n'
              '• Don\'t leave goats isolated (easy targets)\n'
              '• Build walls of goats together\n'
              '• Push tigers toward corners',
          tip: 'Work as a team - no goat left behind!',
        ),

        // Step 13: Ready to Play
        const TutorialStep(
          title: 'You\'re Ready! 🎮',
          description:
              'You now know everything to play TigerHunt!\n\n'
              'Start with Easy AI to practice, then challenge harder '
              'opponents or play online with friends!',
          tip: 'Try both sides - Tigers AND Goats play very differently!',
        ),
      ];

  // Helper methods to create demo game states
  static GameState _createTigerMoveDemo() {
    return GameState.initial(BoardLevel.traditional);
  }

  static GameState _createCaptureDemo() {
    // Setup: Tiger at (2,2), Goat at (2,3), empty at (2,4)
    final tigers = [
      const Piece(type: PieceType.tiger, position: Position(2, 2), id: 'tiger_0'),
      const Piece(type: PieceType.tiger, position: Position(0, 4), id: 'tiger_1'),
      const Piece(type: PieceType.tiger, position: Position(4, 0), id: 'tiger_2'),
      const Piece(type: PieceType.tiger, position: Position(4, 4), id: 'tiger_3'),
    ];
    final goats = [
      const Piece(type: PieceType.goat, position: Position(2, 3), id: 'goat_0'),
    ];

    return GameState(
      level: BoardLevel.traditional,
      pieces: [...tigers, ...goats],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 1,
      goatsCaptured: 0,
      moveHistory: const [],
    );
  }

  static GameState _createGoatMoveDemo() {
    final tigers = [
      const Piece(type: PieceType.tiger, position: Position(0, 0), id: 'tiger_0'),
      const Piece(type: PieceType.tiger, position: Position(0, 4), id: 'tiger_1'),
      const Piece(type: PieceType.tiger, position: Position(4, 0), id: 'tiger_2'),
      const Piece(type: PieceType.tiger, position: Position(4, 4), id: 'tiger_3'),
    ];
    final goats = [
      const Piece(type: PieceType.goat, position: Position(2, 2), id: 'goat_0'),
    ];

    return GameState(
      level: BoardLevel.traditional,
      pieces: [...tigers, ...goats],
      currentTurn: PlayerTurn.goat,
      phase: GamePhase.movement,
      winner: GameWinner.none,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: const [],
    );
  }

  static GameState _createTrappedTigerDemo() {
    // All tigers trapped in corner
    final tigers = [
      const Piece(type: PieceType.tiger, position: Position(0, 0), id: 'tiger_0'),
      const Piece(type: PieceType.tiger, position: Position(0, 1), id: 'tiger_1'),
      const Piece(type: PieceType.tiger, position: Position(1, 0), id: 'tiger_2'),
      const Piece(type: PieceType.tiger, position: Position(1, 1), id: 'tiger_3'),
    ];
    final goats = [
      const Piece(type: PieceType.goat, position: Position(0, 2), id: 'goat_0'),
      const Piece(type: PieceType.goat, position: Position(1, 2), id: 'goat_1'),
      const Piece(type: PieceType.goat, position: Position(2, 0), id: 'goat_2'),
      const Piece(type: PieceType.goat, position: Position(2, 1), id: 'goat_3'),
      const Piece(type: PieceType.goat, position: Position(2, 2), id: 'goat_4'),
    ];

    return GameState(
      level: BoardLevel.traditional,
      pieces: [...tigers, ...goats],
      currentTurn: PlayerTurn.tiger,
      phase: GamePhase.movement,
      winner: GameWinner.goats,
      goatsPlaced: 20,
      goatsCaptured: 0,
      moveHistory: const [],
    );
  }
}
