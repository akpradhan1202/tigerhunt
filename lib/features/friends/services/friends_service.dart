import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/friend.dart';

final friendsServiceProvider = Provider<FriendsService>((ref) {
  return FriendsService();
});

class FriendsService {
  final FirebaseFirestore? _db;
  static const String _prefPrefix = 'tigerhunt_friends_';

  FriendsService({FirebaseFirestore? firestore}) : _db = firestore;

  FirebaseFirestore? get _firestore {
    if (_db != null) return _db;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Fetch saved friends list for a user from local storage and sync with Firestore.
  Future<List<Friend>> getFriends(String userId) async {
    if (userId.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_prefPrefix$userId');
    final localFriends = <Friend>[];

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
        for (final item in list) {
          localFriends.add(Friend.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Error parsing local friends: $e');
      }
    }

    // Attempt to sync from Firestore in the background
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('users')
            .doc(userId)
            .collection('friends')
            .get();

        if (snap.docs.isNotEmpty) {
          final remoteFriends = snap.docs
              .map((doc) => Friend.fromJson(doc.data()))
              .toList();

          // Merge remote friends with local
          final map = {for (final f in localFriends) f.id: f};
          for (final rf in remoteFriends) {
            map[rf.id] = rf;
          }
          final merged = map.values.toList();
          await _saveLocal(userId, merged);
          return merged;
        }
      } catch (_) {
        // Offline / permission best-effort fallback
      }
    }

    return localFriends;
  }

  /// Add a friend to the user's friend list.
  Future<List<Friend>> addFriend(String userId, Friend friend) async {
    if (userId.isEmpty || friend.id.isEmpty) return [];

    final current = await getFriends(userId);
    if (!current.any((f) => f.id == friend.id)) {
      current.add(friend);
      await _saveLocal(userId, current);

      final fs = _firestore;
      if (fs != null) {
        try {
          await fs
              .collection('users')
              .doc(userId)
              .collection('friends')
              .doc(friend.id)
              .set(friend.toJson());
        } catch (_) {}
      }
    }
    return current;
  }

  /// Remove a friend from the user's friend list.
  Future<List<Friend>> removeFriend(String userId, String friendId) async {
    if (userId.isEmpty || friendId.isEmpty) return [];

    final current = await getFriends(userId);
    current.removeWhere((f) => f.id == friendId);
    await _saveLocal(userId, current);

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection('users')
            .doc(userId)
            .collection('friends')
            .doc(friendId)
            .delete();
      } catch (_) {}
    }

    return current;
  }

  /// Search available registered users or presence by username or email.
  Future<List<Friend>> searchUsers(String query, {String? currentUserId}) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final results = <Friend>[];

    final fs = _firestore;
    if (fs != null) {
      try {
        // Query recent presence documents
        final snap = await fs.collection('presence').get();
        for (final doc in snap.docs) {
          if (doc.id == currentUserId) continue;

          final data = doc.data();
          final name = (data['displayName'] as String? ?? '').toLowerCase();
          final email = (data['email'] as String? ?? '').toLowerCase();

          if (name.contains(cleanQuery) || email.contains(cleanQuery)) {
            results.add(Friend(
              id: doc.id,
              displayName: data['displayName'] as String? ?? 'Tiger Player',
              email: data['email'] as String? ?? '',
              addedAt: DateTime.now(),
              isOnline: true,
            ));
          }
        }
      } catch (_) {}
    }

    return results;
  }

  Future<void> _saveLocal(String userId, List<Friend> friends) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = friends.map((f) => f.toJson()).toList();
      await prefs.setString('$_prefPrefix$userId', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving friends locally: $e');
    }
  }
}
