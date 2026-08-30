import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/features/challenges/models/challenge_models.dart';
import 'package:tigerhunt/features/game/models/game_engine.dart';
import 'package:tigerhunt/features/game/models/game_models.dart';
import 'package:tigerhunt/features/game/models/game_state.dart';

void main() {
  final allPuzzles = <Puzzle>[
    ...PuzzleLibrary.beginnerPuzzles,
    ...PuzzleLibrary.intermediatePuzzles,
    ...PuzzleLibrary.advancedPuzzles,
  ];

  group('PuzzleLibrary', () {
    test('every puzzle has a unique id', () {
      final ids = allPuzzles.map((p) => p.id).toSet();
      expect(ids.length, allPuzzles.length);
    });

    test('sections contain puzzles', () {
      expect(PuzzleLibrary.beginnerPuzzles.length, greaterThanOrEqualTo(2));
      expect(PuzzleLibrary.intermediatePuzzles.length, greaterThanOrEqualTo(1));
      expect(PuzzleLibrary.advancedPuzzles.length, greaterThanOrEqualTo(1));
    });

    test('solutions match player role', () {
      for (final puzzle in allPuzzles) {
        for (final move in puzzle.solution) {
          expect(move.pieceType, puzzle.playerRole,
              reason: '${puzzle.id} solution uses a piece type that does not '
                  'match its player role');
        }
      }
    });

    for (final puzzle in allPuzzles) {
      test('${puzzle.id} solution is playable', () {
        final engine = GameEngine(puzzle.position.level);
        var state = puzzle.position;

        for (final move in puzzle.solution) {
          final turn = puzzle.playerRole == PieceType.tiger
              ? PlayerTurn.tiger
              : PlayerTurn.goat;
          expect(engine.isValidMove(state.copyWith(currentTurn: turn), move),
              isTrue,
              reason: '${puzzle.id} move $move is not valid from '
                  '${state.pieces}');
          state = engine.executeMove(state, move);
          // The engine alternates turns; force the tactical line to stay on
          // the puzzle player so capture chains can be verified in sequence.
          state = state.copyWith(
            currentTurn: turn,
          );
        }
      });
    }

    test('puzzle_202 Final Capture wins the game', () {
      final puzzle = allPuzzles.firstWhere((p) => p.id == 'puzzle_202');
      final engine = GameEngine(puzzle.position.level);
      final state = engine.executeMove(puzzle.position, puzzle.solution.first);
      expect(state.winner, GameWinner.tigers);
    });

    test('puzzle_203 Silent Death traps the corner tiger', () {
      final puzzle = allPuzzles.firstWhere((p) => p.id == 'puzzle_203');
      final engine = GameEngine(puzzle.position.level);
      final state = engine.executeMove(puzzle.position, puzzle.solution.first);

      final tiger = state.getPieceAt(const Position(0, 0));
      expect(tiger, isNotNull);
      expect(tiger!.type, PieceType.tiger);

      // No neighbour of the corner tiger is empty and no capture is possible.
      for (final neighbor in engine.connections.getNeighbors(tiger.position)) {
        expect(state.getPieceAt(neighbor), isNotNull,
            reason: 'corner tiger neighbour $neighbor is still empty');
        final piece = state.getPieceAt(neighbor)!;
        if (piece.type == PieceType.goat) {
          final jumpDest = engine.connections
              .getJumpDestination(tiger.position, neighbor);
          if (jumpDest != null) {
            expect(state.getPieceAt(jumpDest), isNotNull,
                reason: 'corner tiger could still capture via $jumpDest');
          }
        }
      }
    });

    test('puzzle_204 Mastermind is a two-move capture chain', () {
      final puzzle = allPuzzles.firstWhere((p) => p.id == 'puzzle_204');
      expect(puzzle.solution.length, 2);
      expect(puzzle.solution.every((m) => m.isCapture), isTrue);
    });

    test('harder tiers contain multi-move solutions', () {
      expect(
        PuzzleLibrary.intermediatePuzzles
            .where((p) => p.solution.length >= 2)
            .length,
        greaterThanOrEqualTo(2),
        reason: 'Intermediate should offer multi-move tactical lines',
      );
      expect(
        PuzzleLibrary.advancedPuzzles
            .where((p) => p.solution.length >= 3)
            .length,
        greaterThanOrEqualTo(2),
        reason: 'Advanced should offer 3+ move forced sequences',
      );
    });

    test('advanced puzzles rate higher than beginner puzzles', () {
      final beginnerMax = PuzzleLibrary.beginnerPuzzles
          .map((p) => p.rating)
          .reduce((a, b) => a > b ? a : b);
      final advancedMin = PuzzleLibrary.advancedPuzzles
          .map((p) => p.rating)
          .reduce((a, b) => a < b ? a : b);
      expect(advancedMin, greaterThan(beginnerMax));
    });
  });
}