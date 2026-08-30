import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/features/play/screens/play_screen.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PlayScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wide screens show the persistent sidebar and side-by-side cards',
      (tester) async {
    await pumpAt(tester, const Size(1200, 800));

    // Desktop top bar with search (mobile layout doesn't show it).
    expect(find.text('Search...'), findsOneWidget);
    // No hamburger menu on wide screens.
    expect(find.byTooltip('Menu'), findsNothing);

    // Game cards sit side by side (same vertical position).
    final playOnlineY = tester.getTopLeft(find.text('Play Online')).dy;
    final passPlayY = tester.getTopLeft(find.text('Pass & Play')).dy;
    expect(playOnlineY, closeTo(passPlayY, 1.0));

    // Board level cards side by side too.
    final pyramidY = tester.getTopLeft(find.text('Pyramid')).dy;
    final traditionalY = tester.getTopLeft(find.text('Traditional')).dy;
    expect(pyramidY, closeTo(traditionalY, 1.0));
  });

  testWidgets('narrow screens use an app bar + drawer and stack the cards',
      (tester) async {
    await pumpAt(tester, const Size(400, 800));

    // No desktop search bar; hamburger menu instead.
    expect(find.text('Search...'), findsNothing);
    expect(find.byTooltip('Menu'), findsOneWidget);

    // Cards stack vertically (different vertical positions).
    final playOnlineY = tester.getTopLeft(find.text('Play Online')).dy;
    final passPlayY = tester.getTopLeft(find.text('Pass & Play')).dy;
    expect(passPlayY, greaterThan(playOnlineY));

    final pyramidY = tester.getTopLeft(find.text('Pyramid')).dy;
    final traditionalY = tester.getTopLeft(find.text('Traditional')).dy;
    expect(traditionalY, greaterThan(pyramidY));

    // No Home nav item anywhere.
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('the mobile drawer contains every nav item and the profile',
      (tester) async {
    await pumpAt(tester, const Size(400, 800));

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    // 'Play' appears twice (drawer nav item + the game-cards section header),
    // so target the drawer nav item by its icon.
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    for (final label in [
      'Puzzles',
      'Learn',
      'Stats',
      'Tournaments',
      'Game History',
      // No user is signed in inside this bare ProviderScope, so the profile
      // card falls back to the guest label instead of a hardcoded name.
      'Guest Player',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'drawer should show $label');
    }
    expect(find.text('Home'), findsNothing);
  });
}
