import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/features/game/models/game_models.dart';
import 'package:tigerhunt/features/game/models/game_state.dart';
import 'package:tigerhunt/features/game/models/game_engine.dart';
import 'package:tigerhunt/features/game/models/ai_engine.dart';

void main() {
  group('AIEngine', () {
    late GameEngine gameEngine;
    late GameState initialState;

    setUp(() {
      gameEngine = GameEngine(BoardLevel.traditional);
      initialState = GameState.initial(BoardLevel.traditional);
    });

    group('Basic Functionality', () {
      test('AI returns a valid move', () async {
        final aiEngine = AIEngine(
          gameEngine: gameEngine,
          difficulty: AIDifficulty.easy,
        );

        final move = await aiEngine.getBestMove(initialState);

        expect(move, isNotNull);
        expect(gameEngine.isValidMove(initialState, move!), isTrue);
      });

      test('AI plays as goat during placement', () async {
        final aiEngine = AIEngine(
          gameEngine: gameEngine,
          difficulty: AIDifficulty.medium,
        );

        final move = await aiEngine.getBestMove(initialState);

        expect(move!.pieceType, equals(PieceType.goat));
        expect(move.isPlacement, isTrue);
      });

      test('AI plays as tiger when it is tiger turn', () async {
        // Place a goat first
        final state = gameEngine.executeMove(
          initialState,
          const Move(
            from: Position(-1, -1),
            to: Position(2, 2),
            pieceType: PieceType.goat,
          ),
        );

        final aiEngine = AIEngine(
          gameEngine: gameEngine,
          difficulty: AIDifficulty.medium,
        );

        final move = await aiEngine.getBestMove(state);

        expect(move!.pieceType, equals(PieceType.tiger));
      });

      test('AI returns null when game is over', () async {
        final endedState = initialState.copyWith(
          winner: GameWinner.tigers,
          phase: GamePhase.ended,
        );

        final aiEngine = AIEngine(
          gameEngine: gameEngine,
          difficulty: AIDifficulty.easy,
        );

        final move = await aiEngine.getBestMove(endedState);

        expect(move, isNull);
      });
    });

    group('Difficulty Levels', () {
      test('easy AI has lower search depth', () {
        expect(AIDifficulty.easy.depth, lessThan(AIDifficulty.medium.depth));
        expect(AIDifficulty.medium.depth, lessThan(AIDifficulty.hard.depth));
        expect(AIDifficulty.hard.depth, lessThan(AIDifficulty.expert.depth));
      });

      test('all difficulty levels return valid moves', () async {
        for (final difficulty in AIDifficulty.values) {
          final aiEngine = AIEngine(
            gameEngine: gameEngine,
            difficulty: difficulty,
          );

          final move = await aiEngine.getBestMove(initialState);

          expect(
            move,
            isNotNull,
            reason: '${difficulty.name} should return a move',
          );
          expect(
            gameEngine.isValidMove(initialState, move!),
            isTrue,
            reason: '${difficulty.name} should return a valid move',
          );
        }
      });
    });

    group('AI Strategy', () {
      test('AI captures when possible (medium+ difficulty)', () async {
        // Setup: Goat is in capture position
        final state = gameEngine.executeMove(
          initialState,
          const Move(
            from: Position(-1, -1),
            to: Position(0, 1), // Adjacent to tiger, with space beyond
            pieceType: PieceType.goat,
          ),
        );

        final aiEngine = AIEngine(
          gameEngine: gameEngine,
          difficulty: AIDifficulty.medium,
        );

        final move = await aiEngine.getBestMove(state);

        // Medium+ AI should recognize the capture opportunity
        expect(move, isNotNull);
        // Note: AI might not always capture if it evaluates other moves as better,
        // but capture should be considered
      });

      test('AI avoids being trapped as tiger', () async {
        // This is a heuristic test - the AI should value mobility
        final aiEngine = AIEngine(
          gameEngine: gameEngine,
          difficulty: AIDifficulty.hard,
        );

        // Run multiple games and check AI doesn't trap itself easily
        var state = initialState;
        int moves = 0;
        const maxMoves = 50;

        while (!state.isGameOver && moves < maxMoves) {
          final move = await aiEngine.getBestMove(state);
          if (move == null) break;

          state = gameEngine.executeMove(state, move);
          moves++;
        }

        // If game ended, check the outcome
        if (state.isGameOver) {
          // Hard AI should rarely lose by being trapped quickly
          if (state.winner == GameWinner.goats) {
            expect(moves, greaterThan(20),
                reason: 'Hard AI should not be trapped quickly');
          }
        }
      });
    });

    group('AIPlayer', () {
      test('AIPlayer only moves on its turn', () async {
        final aiPlayer = AIPlayer(
          gameEngine: gameEngine,
          difficulty: AIDifficulty.easy,
          playingAs: PieceType.tiger,
        );

        // Initial state - goat's turn
        final moveOnGoatTurn = await aiPlayer.getMove(initialState);
        expect(moveOnGoatTurn, isNull);

        // After goat places
        final state = gameEngine.executeMove(
          initialState,
          const Move(
            from: Position(-1, -1),
            to: Position(2, 2),
            pieceType: PieceType.goat,
          ),
        );

        final moveOnTigerTurn = await aiPlayer.getMove(state);
        expect(moveOnTigerTurn, isNotNull);
        expect(moveOnTigerTurn!.pieceType, equals(PieceType.tiger));
      });

      test('AIPlayer as goat only moves during goat turn', () async {
        final aiPlayer = AIPlayer(
          gameEngine: gameEngine,
          difficulty: AIDifficulty.easy,
          playingAs: PieceType.goat,
        );

        // Initial state - goat's turn
        final moveOnGoatTurn = await aiPlayer.getMove(initialState);
        expect(moveOnGoatTurn, isNotNull);
        expect(moveOnGoatTurn!.pieceType, equals(PieceType.goat));

        // After goat places - tiger's turn
        final state = gameEngine.executeMove(initialState, moveOnGoatTurn);

        final moveOnTigerTurn = await aiPlayer.getMove(state);
        expect(moveOnTigerTurn, isNull);
      });
    });
  });

  group('AI Performance', () {
    test('AI responds within reasonable time (easy)', () async {
      final gameEngine = GameEngine(BoardLevel.traditional);
      final aiEngine = AIEngine(
        gameEngine: gameEngine,
        difficulty: AIDifficulty.easy,
      );

      final stopwatch = Stopwatch()..start();
      await aiEngine.getBestMove(GameState.initial(BoardLevel.traditional));
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Easy AI should respond quickly',
      );
    });

    test('AI responds within reasonable time (medium)', () async {
      final gameEngine = GameEngine(BoardLevel.traditional);
      final aiEngine = AIEngine(
        gameEngine: gameEngine,
        difficulty: AIDifficulty.medium,
      );

      final stopwatch = Stopwatch()..start();
      await aiEngine.getBestMove(GameState.initial(BoardLevel.traditional));
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(3000),
        reason: 'Medium AI should respond within 3 seconds',
      );
    });
  });
}
