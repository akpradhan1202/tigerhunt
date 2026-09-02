import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/features/game/models/game_models.dart';
import 'package:tigerhunt/features/game/screens/game_screen.dart';
import 'package:tigerhunt/features/game/widgets/game_board.dart';
import 'package:tigerhunt/features/rules/screens/game_rules_screen.dart';

void main() {
  group('Mobile Device Screen Layout Tests', () {
    final mobileSizes = [
      ('Compact Phone (360x640)', const Size(360, 640)),
      ('Standard Phone (390x844)', const Size(390, 844)),
      ('Large Phone (412x915)', const Size(412, 915)),
    ];

    for (final (label, size) in mobileSizes) {
      group('$label ($size)', () {
        testWidgets('Level 1 Pyramid renders without overflow on $label',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: GameScreen(
                  level: BoardLevel.pyramid,
                  mode: GameMode.offline,
                  playerRole: PieceType.goat,
                  timer: GameTimer.five,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(GameBoard), findsOneWidget);
          expect(find.text('Pyramid'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('Level 2 Square renders without overflow on $label',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: GameScreen(
                  level: BoardLevel.square,
                  mode: GameMode.offline,
                  playerRole: PieceType.goat,
                  timer: GameTimer.five,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(GameBoard), findsOneWidget);
          expect(find.text('Square'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('Level 3 Traditional (5 Tigers) renders without overflow on $label',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: GameScreen(
                  level: BoardLevel.traditional,
                  mode: GameMode.offline,
                  playerRole: PieceType.goat,
                  timer: GameTimer.five,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(GameBoard), findsOneWidget);
          expect(find.text('Traditional'), findsOneWidget);
          // Verify bottom controls & player bars render
          expect(find.text('You'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('GameRulesScreen renders and scrolls cleanly on $label',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const MaterialApp(
              home: GameRulesScreen(),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Game Rules & Info'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      });
    }
  });
}
