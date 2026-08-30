import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tigerhunt/main.dart';

void main() {
  testWidgets('TigerHunt app boots to the login screen', (tester) async {
    // Mirror main(): TigerHuntApp requires a ProviderScope ancestor
    await tester.pumpWidget(const ProviderScope(child: TigerHuntApp()));
    await tester.pump(const Duration(seconds: 2));

    // Login screen should render the game title and guest option
    expect(find.text('TigerHunt'), findsOneWidget);
    expect(find.text('Play as Guest'), findsOneWidget);
  });
}
