import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/core/services/auth_service.dart';
import 'package:tigerhunt/features/auth/models/user_profile.dart';
import 'package:tigerhunt/features/auth/screens/login_screen.dart';
import 'package:tigerhunt/core/router/app_router.dart';

void main() {
  group('Guest User Model & Optional Name', () {
    test('AppUser.guest() defaults to Guest Player', () {
      final guest = AppUser.guest();
      expect(guest.displayName, 'Guest Player');
      expect(guest.isGuest, isTrue);
      expect(guest.authType, AuthType.guest);
    });

    test('AppUser.guest(name: "TigerHunter") uses custom name', () {
      final guest = AppUser.guest(name: 'TigerHunter');
      expect(guest.displayName, 'TigerHunter');
      expect(guest.isGuest, isTrue);
    });

    test('AppUser.guest(name: "   ") ignores whitespace-only and defaults to Guest Player', () {
      final guest = AppUser.guest(name: '   ');
      expect(guest.displayName, 'Guest Player');
    });

    test('AppUser.guest(name: "  Akela  ") trims whitespace', () {
      final guest = AppUser.guest(name: '  Akela  ');
      expect(guest.displayName, 'Akela');
    });

    test('UserProfile.guest() defaults to Guest Player', () {
      final profile = UserProfile.guest();
      expect(profile.displayName, 'Guest Player');
      expect(profile.isGuest, isTrue);
      expect(profile.authProvider, AuthProvider.guest);
    });

    test('UserProfile.guest(name: "Baloo") uses custom name', () {
      final profile = UserProfile.guest(name: 'Baloo');
      expect(profile.displayName, 'Baloo');
    });
  });

  group('AuthService signInAsGuest with Optional Name', () {
    test('signInAsGuest() with no params signs in as Guest Player', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final success =
          await container.read(authServiceProvider.notifier).signInAsGuest();

      expect(success, isTrue);
      final authState = container.read(authServiceProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.isGuest, isTrue);
      expect(authState.user?.displayName, 'Guest Player');
    });

    test('signInAsGuest(name: "SherKhan") signs in with custom name', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final success = await container
          .read(authServiceProvider.notifier)
          .signInAsGuest(name: 'SherKhan');

      expect(success, isTrue);
      final authState = container.read(authServiceProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.isGuest, isTrue);
      expect(authState.user?.displayName, 'SherKhan');
    });
  });

  group('LoginScreen with Optional Guest Name', () {
    testWidgets('renders guest name field and Play as Guest button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Guest name (optional)'), findsOneWidget);
      expect(find.text('Play as Guest'), findsOneWidget);
    });

    testWidgets('pre-fills guest name field when initial name is passed', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(name: 'PreFilledGuest'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('PreFilledGuest'), findsOneWidget);
    });

    testWidgets('entering a name updates the text field and signs in with that name', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      // Enter a custom name into the guest name text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'ChampionTiger');
      await tester.pump();

      // Ensure Play as Guest button is scrolled into view and tap it
      final guestButton = find.text('Play as Guest');
      await tester.ensureVisible(guestButton);
      await tester.pumpAndSettle();

      await tester.tap(guestButton);
      await tester.pump(const Duration(milliseconds: 350));

      final authState = container.read(authServiceProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.user?.displayName, 'ChampionTiger');
    });
  });

  group('Router with Optional Guest Name', () {
    testWidgets('navigating to /login?name=TigerGuest pre-populates name field', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      router.go('/login?name=TigerGuest');
      await tester.pumpAndSettle();

      expect(find.text('TigerGuest'), findsOneWidget);
    });

    testWidgets('navigating to /play?name=TigerMaster logs in as guest with that name', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      router.go('/play?name=TigerMaster');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final auth = container.read(authServiceProvider);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isGuest, isTrue);
      expect(auth.user?.displayName, 'TigerMaster');
    });
  });
}
