import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/features/game/models/game_models.dart';
import 'package:tigerhunt/features/game/models/game_state.dart';
import 'package:tigerhunt/features/game/models/game_engine.dart';
import 'package:tigerhunt/features/game/providers/game_timer_provider.dart';

void main() {
  group('Anti-Repetition & Move-Limit Rules', () {
    test('Threefold repetition triggers Draw', () {
      final engine = GameEngine(BoardLevel.square);
      var state = GameState.initial(BoardLevel.square);

      final pieces = <Piece>[
        const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        const Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
        const Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
        const Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
        const Piece(type: PieceType.goat, position: Position(2, 2), id: 'g0'),
      ];

      state = state.copyWith(
        pieces: pieces,
        goatsPlaced: 16,
        phase: GamePhase.movement,
        currentTurn: PlayerTurn.goat,
      );

      final sig = state.stateSignature;

      // Manually set 2 prior occurrences of the resulting state signature
      // Target state after goat moves (2, 3) -> (2, 2) has turn: PlayerTurn.tiger
      final targetState = state.copyWith(currentTurn: PlayerTurn.tiger);
      final targetSig = targetState.stateSignature;

      final intermediate = state.copyWith(
        pieces: [
          const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
          const Piece(type: PieceType.tiger, position: Position(0, 4), id: 't1'),
          const Piece(type: PieceType.tiger, position: Position(4, 0), id: 't2'),
          const Piece(type: PieceType.tiger, position: Position(4, 4), id: 't3'),
          const Piece(type: PieceType.goat, position: Position(2, 3), id: 'g0'),
        ],
        positionHistory: {targetSig: 2},
        currentTurn: PlayerTurn.goat,
      );

      final nextState = engine.executeMove(
        intermediate,
        const Move(
          from: Position(2, 3),
          to: Position(2, 2),
          pieceType: PieceType.goat,
        ),
      );

      expect(nextState.positionHistory[targetSig], 3);
      expect(nextState.winner, GameWinner.draw);
      expect(nextState.drawReason, DrawReason.threefoldRepetition);
    });

    test('40-move stagnation limit triggers Draw', () {
      final engine = GameEngine(BoardLevel.square);
      var state = GameState.initial(BoardLevel.square);

      state = state.copyWith(
        pieces: [
          const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
          const Piece(type: PieceType.goat, position: Position(2, 2), id: 'g0'),
        ],
        goatsPlaced: 16,
        phase: GamePhase.movement,
        currentTurn: PlayerTurn.goat,
        movesWithoutCapture: 39,
      );

      // Make a move without capture
      final nextState = engine.executeMove(
        state,
        const Move(
          from: Position(2, 2),
          to: Position(2, 3),
          pieceType: PieceType.goat,
        ),
      );

      expect(nextState.movesWithoutCapture, 40);
      expect(nextState.winner, GameWinner.draw);
      expect(nextState.drawReason, DrawReason.stagnation);
    });

    test('Anti-oscillation filters 3rd repetitive ping-pong move when other moves exist', () {
      final engine = GameEngine(BoardLevel.square);
      var state = GameState.initial(BoardLevel.square);

      state = state.copyWith(
        phase: GamePhase.movement,
        currentTurn: PlayerTurn.tiger,
        moveHistory: const [
          Move(from: Position(0, 0), to: Position(0, 1), pieceType: PieceType.tiger),
          Move(from: Position(2, 0), to: Position(2, 1), pieceType: PieceType.goat),
          Move(from: Position(0, 1), to: Position(0, 0), pieceType: PieceType.tiger),
          Move(from: Position(2, 1), to: Position(2, 0), pieceType: PieceType.goat),
        ],
      );

      final moves = engine.getValidMoves(state);
      final movesTo01 = moves.where((m) => m.from == const Position(0, 0) && m.to == const Position(0, 1));

      expect(movesTo01.isEmpty, isTrue);
    });
  });

  group('Tactical Power-Ups', () {
    test('Tiger Roar freezes goat for 1 turn', () {
      final engine = GameEngine(BoardLevel.square);
      var state = GameState.initial(BoardLevel.square);

      const goatPos = Position(1, 0);
      state = state.copyWith(
        pieces: [
          const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
          const Piece(type: PieceType.goat, position: goatPos, id: 'g0'),
        ],
        phase: GamePhase.movement,
        currentTurn: PlayerTurn.tiger,
      );

      state = engine.applyPowerUp(state, powerUp: PowerUpType.tigerRoar, target: goatPos);
      expect(state.isGoatStunned(goatPos), isTrue);

      final goatState = state.copyWith(currentTurn: PlayerTurn.goat);
      final goatMoves = engine.getValidMoves(goatState);
      expect(goatMoves.where((m) => m.from == goatPos).isEmpty, isTrue);
    });

    test('Horn Shield prevents tiger capture for 2 turns', () {
      final engine = GameEngine(BoardLevel.square);
      var state = GameState.initial(BoardLevel.square);

      const goatPos = Position(0, 1);
      state = state.copyWith(
        pieces: [
          const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
          const Piece(type: PieceType.goat, position: goatPos, id: 'g0'),
        ],
        phase: GamePhase.movement,
        currentTurn: PlayerTurn.goat,
      );

      state = engine.applyPowerUp(state, powerUp: PowerUpType.hornShield, target: goatPos);
      expect(state.isGoatShielded(goatPos), isTrue);

      final tigerState = state.copyWith(currentTurn: PlayerTurn.tiger);
      final tigerMoves = engine.getValidMoves(tigerState);
      final captures = tigerMoves.where((m) => m.isCapture && m.capturedAt == goatPos);
      expect(captures.isEmpty, isTrue);
    });

    test('Boulder blocks intersection for movement and jumping', () {
      final engine = GameEngine(BoardLevel.square);
      var state = GameState.initial(BoardLevel.square);

      const boulderPos = Position(0, 1);
      state = state.copyWith(
        pieces: [
          const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
        ],
        phase: GamePhase.movement,
        currentTurn: PlayerTurn.goat,
      );

      state = engine.applyPowerUp(state, powerUp: PowerUpType.boulder, target: boulderPos);
      expect(state.isBoulderAt(boulderPos), isTrue);
      expect(state.isPositionEmpty(boulderPos), isFalse);

      final tigerState = state.copyWith(currentTurn: PlayerTurn.tiger);
      final tigerMoves = engine.getValidMoves(tigerState);
      expect(tigerMoves.any((m) => m.to == boulderPos), isFalse);
    });
  });

  group('Sudden Death & Shrinking Arena', () {
    test('Collapsing nodes fairly relocates both goats and tigers without capturing', () {
      final engine = GameEngine(BoardLevel.square);
      var state = GameState.initial(BoardLevel.square);

      state = state.copyWith(
        pieces: [
          const Piece(type: PieceType.tiger, position: Position(0, 0), id: 't0'),
          const Piece(type: PieceType.goat, position: Position(0, 4), id: 'g0'),
          const Piece(type: PieceType.goat, position: Position(2, 2), id: 'g1'),
        ],
        phase: GamePhase.movement,
        currentTurn: PlayerTurn.goat,
      );

      final collapsing = {const Position(0, 0), const Position(0, 4)};
      final collapsedState = engine.triggerArenaCollapse(state, collapsing);

      expect(collapsedState.isPositionCollapsed(const Position(0, 0)), isTrue);
      expect(collapsedState.isPositionCollapsed(const Position(0, 4)), isTrue);

      // Goat g0 is safely relocated, not captured!
      final g0 = collapsedState.pieces.firstWhere((p) => p.id == 'g0');
      expect(g0.isCaptured, isFalse);
      expect(g0.position, isNot(const Position(0, 4)));
      expect(collapsedState.isPositionCollapsed(g0.position), isFalse);
      expect(collapsedState.goatsCaptured, 0);

      // Tiger t0 is safely relocated
      final t0 = collapsedState.pieces.firstWhere((p) => p.id == 't0');
      expect(t0.position, isNot(const Position(0, 0)));
      expect(collapsedState.isPositionCollapsed(t0.position), isFalse);
    });
  });

  group('Fischer Time Increment', () {
    test('GameTimerNotifier adds increment on turn change', () {
      final notifier = GameTimerNotifier(
        initialTime: const Duration(minutes: 5),
        increment: const Duration(seconds: 2),
      );

      expect(notifier.state.tigerTime, const Duration(minutes: 5));
      expect(notifier.state.goatTime, const Duration(minutes: 5));

      notifier.addIncrement(PlayerTurn.tiger);
      expect(notifier.state.tigerTime, const Duration(minutes: 5, seconds: 2));

      notifier.addIncrement(PlayerTurn.goat);
      expect(notifier.state.goatTime, const Duration(minutes: 5, seconds: 2));
    });
  });
}
