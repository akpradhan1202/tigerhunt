import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tigerhunt/core/services/auth_service.dart';
import 'package:tigerhunt/features/auth/widgets/phone_login_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUser Phone Auth', () {
    test('serializes and deserializes phone user accurately', () {
      final now = DateTime(2026, 9, 1, 14, 30);
      final user = AppUser(
        id: 'phone_user_001',
        displayName: 'TigerStriker',
        phoneNumber: '+919876543210',
        authType: AuthType.phone,
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['id'], 'phone_user_001');
      expect(map['displayName'], 'TigerStriker');
      expect(map['phoneNumber'], '+919876543210');
      expect(map['authType'], 'phone');

      final deserialized = AppUser.fromMap(map);
      expect(deserialized.id, user.id);
      expect(deserialized.displayName, user.displayName);
      expect(deserialized.phoneNumber, user.phoneNumber);
      expect(deserialized.authType, AuthType.phone);
      expect(deserialized.isGuest, isFalse);
    });
  });

  group('AuthService Direct Phone Login', () {
    test('signInWithPhone creates deterministic user from phone number', () async {
      final authService = AuthService();
      expect(authService.state.isAuthenticated, isFalse);

      final success = await authService.signInWithPhone(
        phoneNumber: '+919876543210',
        passcode: '123456',
        displayName: 'BaghMaster',
      );

      expect(success, isTrue);
      expect(authService.state.isAuthenticated, isTrue);
      expect(authService.state.user?.displayName, 'BaghMaster');
      expect(authService.state.user?.authType, AuthType.phone);
      expect(authService.state.user?.phoneNumber, '+919876543210');
      // Deterministic ID: same phone = same ID
      expect(authService.state.user?.id, 'phone_919876543210');
    });

    test('same phone number produces same user ID', () async {
      final auth1 = AuthService();
      final auth2 = AuthService();

      await auth1.signInWithPhone(phoneNumber: '+919876543210', passcode: '123456');
      await auth2.signInWithPhone(phoneNumber: '+919876543210', passcode: '123456');

      expect(auth1.state.user?.id, auth2.state.user?.id);
    });

    test('auto-generates player name from last 4 digits when no name given', () async {
      final authService = AuthService();

      await authService.signInWithPhone(phoneNumber: '+919876543210', passcode: '123456');

      expect(authService.state.user?.displayName, 'Player 3210');
    });
  });

  group('PhoneLoginSheet Widget', () {
    testWidgets('renders phone input and login button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PhoneLoginSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Login with Mobile'), findsOneWidget);
      expect(find.text('Login 🚀'), findsOneWidget);
      // Phone field + Passcode field (Name field is hidden by default since _isLogin = true)
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });
}
