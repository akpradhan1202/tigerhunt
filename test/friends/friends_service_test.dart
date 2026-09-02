import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tigerhunt/features/friends/models/friend.dart';
import 'package:tigerhunt/features/friends/services/friends_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Friend model', () {
    test('toJson and fromJson work correctly', () {
      final now = DateTime(2026, 9, 1, 12, 0, 0);
      final friend = Friend(
        id: 'user_123',
        displayName: 'TigerKing',
        email: 'tiger@example.com',
        addedAt: now,
        isOnline: true,
      );

      final json = friend.toJson();
      expect(json['id'], 'user_123');
      expect(json['displayName'], 'TigerKing');
      expect(json['email'], 'tiger@example.com');
      expect(json['addedAt'], now.toIso8601String());

      final reconstituted = Friend.fromJson(json, isOnline: true);
      expect(reconstituted.id, friend.id);
      expect(reconstituted.displayName, friend.displayName);
      expect(reconstituted.email, friend.email);
      expect(reconstituted.isOnline, isTrue);
    });

    test('copyWith updates isOnline flag without modifying id', () {
      final friend = Friend(
        id: 'user_abc',
        displayName: 'GoatMaster',
        email: 'goat@example.com',
        addedAt: DateTime.now(),
        isOnline: false,
      );

      final onlineFriend = friend.copyWith(isOnline: true);
      expect(onlineFriend.isOnline, isTrue);
      expect(onlineFriend.id, 'user_abc');
      expect(onlineFriend.displayName, 'GoatMaster');
    });
  });

  group('FriendsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('adds and retrieves friends from local storage', () async {
      final service = FriendsService();
      const userId = 'my_player_1';

      final friend1 = Friend(
        id: 'friend_1',
        displayName: 'Hunter99',
        email: 'hunter99@test.com',
        addedAt: DateTime.now(),
      );

      final listAfterAdd = await service.addFriend(userId, friend1);
      expect(listAfterAdd.length, 1);
      expect(listAfterAdd.first.id, 'friend_1');

      final fetched = await service.getFriends(userId);
      expect(fetched.length, 1);
      expect(fetched.first.displayName, 'Hunter99');
    });

    test('removes friend successfully', () async {
      final service = FriendsService();
      const userId = 'my_player_2';

      final friend1 = Friend(
        id: 'friend_1',
        displayName: 'Alpha',
        email: 'alpha@test.com',
        addedAt: DateTime.now(),
      );
      final friend2 = Friend(
        id: 'friend_2',
        displayName: 'Beta',
        email: 'beta@test.com',
        addedAt: DateTime.now(),
      );

      await service.addFriend(userId, friend1);
      await service.addFriend(userId, friend2);

      final listBefore = await service.getFriends(userId);
      expect(listBefore.length, 2);

      final listAfter = await service.removeFriend(userId, 'friend_1');
      expect(listAfter.length, 1);
      expect(listAfter.first.id, 'friend_2');
    });

    test('does not add duplicates of the same friend', () async {
      final service = FriendsService();
      const userId = 'my_player_3';

      final friend = Friend(
        id: 'friend_unique',
        displayName: 'Champion',
        email: 'champ@test.com',
        addedAt: DateTime.now(),
      );

      await service.addFriend(userId, friend);
      final listSecondAdd = await service.addFriend(userId, friend);
      expect(listSecondAdd.length, 1);
    });
  });
}
