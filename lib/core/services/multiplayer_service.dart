import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';
import '../../features/game/models/game_models.dart';
import '../../features/game/models/game_state.dart';

/// Online match status
enum MatchStatus {
  waiting, // Waiting for an opponent
  inProgress, // Game is active
  completed, // Game finished
  cancelled, // Match was cancelled / abandoned
}

/// Thrown when Firebase has not been configured with real credentials.
class FirebaseNotConfiguredException implements Exception {
  const FirebaseNotConfiguredException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Online match model backed by a Firestore document in `matches/{matchId}`.
class OnlineMatch {
  final String id;
  final String? tigerPlayerId;
  final String? goatPlayerId;
  final BoardLevel level;
  final GameTimer timer;
  final MatchStatus status;
  final List<Move> moves;
  final GameWinner? winner;
  final String? inviteCode;

  /// Player id of the player who offered a draw, or null when no offer is
  /// pending.
  final String? drawOffer;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OnlineMatch({
    required this.id,
    this.tigerPlayerId,
    this.goatPlayerId,
    required this.level,
    required this.timer,
    required this.status,
    this.moves = const [],
    this.winner,
    this.inviteCode,
    this.drawOffer,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasOpponent => tigerPlayerId != null && goatPlayerId != null;

  /// The role [playerId] plays in this match, or null if not a participant.
  PieceType? roleOf(String playerId) {
    if (tigerPlayerId == playerId) return PieceType.tiger;
    if (goatPlayerId == playerId) return PieceType.goat;
    return null;
  }

  bool isPlayer(String playerId) => roleOf(playerId) != null;
}

/// Service for online multiplayer, backed by Cloud Firestore.
///
/// Matchmaking works without cloud functions: waiting matches live in
/// `matches/{id}` with one player slot filled; the second player claims the
/// free slot inside a transaction. Moves are appended to the match document
/// so both clients can replay the game from its initial state.
class MultiplayerService {
  MultiplayerService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  static const String _placeholderKeyPrefix = 'YOUR_';
  static const Duration _waitingStale = Duration(minutes: 2);
  static const String _matchesCollection = 'matches';

  /// True when `flutterfire configure` has been run and real Firebase
  /// credentials are present.
  static bool get isConfigured {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      return !options.apiKey.startsWith(_placeholderKeyPrefix);
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;

  /// Make sure Firebase is initialized and anonymously authenticated so the
  /// Firestore rules (which require `request.auth != null`) accept writes.
  /// Returns the authenticated user's id, used as the player id.
  Future<String> ensureReady() async {
    if (!isConfigured) {
      throw const FirebaseNotConfiguredException(
        'Online play needs Firebase. Run "flutterfire configure" '
        'to connect the app to your Firebase project.',
      );
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final auth = _authInstance;
    if (kIsWeb) {
      try {
        await auth.setPersistence(Persistence.SESSION);
      } catch (_) {}
    }
    try {
      final user = auth.currentUser ??
          (await auth.signInAnonymously().timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw const FirebaseNotConfiguredException(
                  'Sign-in timed out. Enable Anonymous sign-in in '
                  'Firebase Console → Authentication → Sign-in method.',
                ),
              )).user;
      if (user == null) {
        throw FirebaseAuthException(code: 'no-user');
      }
      return user.uid;
    } on FirebaseNotConfiguredException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed' ||
          e.code == 'admin-restricted-operation') {
        throw const FirebaseNotConfiguredException(
          'Anonymous sign-in is disabled. Enable it in Firebase Console → '
          'Authentication → Sign-in method → Anonymous.',
        );
      }
      throw FirebaseNotConfiguredException(
        'Could not sign in to Firebase: ${e.message ?? e.code}',
      );
    } catch (e) {
      throw FirebaseNotConfiguredException(
        'Could not connect to Firestore: $e',
      );
    }
  }

  /// Number of players seen online in the last 2 minutes.
  ///
  /// Uses the `presence` collection: each client heartbeats its own doc and
  /// we count docs with a recent `lastActive` timestamp.
  static const Duration _presenceStale = Duration(minutes: 2);

  Future<void> heartbeatPresence(String playerId) async {
    try {
      await _db.collection('presence').doc(playerId).set({
        'lastActive': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {
      // Presence is best-effort; ignore failures.
    }
  }

  /// Stream of the current online player count (updates in real time).
  Stream<int> watchOnlineCount() {
    return _db
        .collection('presence')
        .snapshots()
        .map((snap) {
          final cutoff = DateTime.now().subtract(_presenceStale);
          final activeCount = snap.docs.where((d) {
            final ts = d.data()['lastActive'];
            if (ts is Timestamp) {
              return ts.toDate().isAfter(cutoff);
            }
            return true;
          }).length;
          return max(1, activeCount);
        })
        .handleError((_) => 1);
  }

  /// Create a new match. The creator immediately fills their preferred role
  /// and the match waits for a second player. Always sets an invite code.
  Future<OnlineMatch> createMatch({
    required String playerId,
    required BoardLevel level,
    required GameTimer timer,
    bool playAsTiger = true,
    String? inviteCode,
  }) async {
    final ref = _db.collection(_matchesCollection).doc();
    final now = DateTime.now();
    final data = {
      'id': ref.id,
      'tigerPlayerId': playAsTiger ? playerId : null,
      'goatPlayerId': playAsTiger ? null : playerId,
      'level': level.name,
      'timer': timer.minutes,
      'status': MatchStatus.waiting.name,
      'moves': <Map<String, dynamic>>[],
      'winner': null,
      'inviteCode': inviteCode ?? generateInviteCode(),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
    await ref.set(data);
    return _fromMap(ref.id, data);
  }

  /// Try to join an existing waiting match with matching settings. Returns the
  /// claimed match, or null when none is available.
  Future<OnlineMatch?> findRandomMatch({
    required String playerId,
    required BoardLevel level,
    required GameTimer timer,
    bool playAsTiger = true,
  }) async {
    final cutoff = DateTime.now().subtract(_waitingStale);
    // Query only on status to avoid requiring composite indexes in Firestore.
    // Level, timer, and expiration are filtered in memory.
    final snap = await _db
        .collection(_matchesCollection)
        .where('status', isEqualTo: MatchStatus.waiting.name)
        .limit(25)
        .get();

    for (final doc in snap.docs) {
      final match = _fromMap(doc.id, doc.data());
      if (match.isPlayer(playerId)) continue;
      if (match.level != level || match.timer != timer) continue;
      if (match.createdAt.isBefore(cutoff)) continue;

      // Prefer the requested role, but accept either free slot.
      final preferred = playAsTiger ? 'tigerPlayerId' : 'goatPlayerId';
      final fallback = playAsTiger ? 'goatPlayerId' : 'tigerPlayerId';
      final String? slot;
      if (doc.data()[preferred] == null) {
        slot = preferred;
      } else if (doc.data()[fallback] == null) {
        slot = fallback;
      } else {
        slot = null; // Both slots filled
      }
      if (slot == null) continue;

      final claimed = await _claimSlot(doc.reference, slot, playerId);
      if (claimed != null) return claimed;
    }
    return null;
  }

  /// Join a private match by its invite code. Returns null when the code is
  /// invalid or the match is already full.
  Future<OnlineMatch?> joinByInviteCode({
    required String playerId,
    required String code,
  }) async {
    final snap = await _db
        .collection(_matchesCollection)
        .where('inviteCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    final data = doc.data();
    if (data['status'] != MatchStatus.waiting.name) return null;
    if (data['tigerPlayerId'] == null) {
      return _claimSlot(doc.reference, 'tigerPlayerId', playerId);
    }
    if (data['goatPlayerId'] == null) {
      return _claimSlot(doc.reference, 'goatPlayerId', playerId);
    }
    return null; // Both slots are filled
  }

  Future<OnlineMatch> getMatch(String matchId) async {
    final doc = await _db
        .collection(_matchesCollection)
        .doc(matchId)
        .get();
    if (!doc.exists) {
      throw StateError('Match $matchId not found');
    }
    return _fromMap(doc.id, _dataOf(doc));
  }

  /// Stream of match updates (opponent joined, moves appended, completed...).
  Stream<OnlineMatch> watchMatch(String matchId) {
    return _db
        .collection(_matchesCollection)
        .doc(matchId)
        .snapshots()
        .where((s) => s.exists)
        .map((s) => _fromMap(s.id, _dataOf(s)));
  }

  /// Stream of all moves played so far in a match.
  Stream<Move> watchMoves(String matchId) {
    return watchMatch(matchId).expand((match) => match.moves);
  }

  /// Append a move to the match inside a transaction so both players' moves
  /// are serialized.
  Future<void> sendMove({
    required String matchId,
    required Move move,
  }) async {
    final ref = _db.collection(_matchesCollection).doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw StateError('Match $matchId not found');
      }
      final moves = <Map<String, dynamic>>[
        ...List<Map<String, dynamic>>.from(snap.data()?['moves'] ?? []),
        move.toJson(),
      ];
      tx.update(ref, {
        'moves': moves,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  /// Mark the match as completed with the given winner.
  Future<void> completeMatch({
    required String matchId,
    required GameWinner winner,
  }) async {
    await _db.collection(_matchesCollection).doc(matchId).update({
      'status': MatchStatus.completed.name,
      'winner': winner.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Offer a draw to the opponent. The opponent's client shows an
  /// accept/decline dialog when it sees the offer appear.
  Future<void> offerDraw({
    required String matchId,
    required String playerId,
  }) async {
    await _db.collection(_matchesCollection).doc(matchId).update({
      'drawOffer': playerId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Accept or decline a pending draw offer. Accepting completes the match
  /// with [GameWinner.draw]; declining just clears the offer.
  Future<void> respondToDraw({
    required String matchId,
    required bool accept,
  }) async {
    final ref = _db.collection(_matchesCollection).doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw StateError('Match $matchId not found');
      }
      final data = _dataOf(snap);
      if (data['drawOffer'] == null) return; // Already resolved
      if (accept) {
        tx.update(ref, {
          'drawOffer': null,
          'status': MatchStatus.completed.name,
          'winner': GameWinner.draw.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        tx.update(ref, {
          'drawOffer': null,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    });
  }

  /// Mark the match as cancelled (host left while waiting, or resigned early).
  Future<void> cancelMatch(String matchId) async {
    final ref = _db.collection(_matchesCollection).doc(matchId);
    try {
      await ref.update({
        'status': MatchStatus.cancelled.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {
      // Match may already be gone; nothing to do.
    }
  }

  /// Generate a human-friendly 6-character invite code.
  String generateInviteCode({Random? random}) {
    // Exclude easily-confused characters (0/O, 1/I).
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = random ?? Random();
    final buffer = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buffer.write(chars[rng.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  /// Fetch the public leaderboard (profiles ordered by rating).
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    final snap = await _db
        .collection('users')
        .orderBy('stats.overallRating', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Normalize snapshot data to a map (SDK returns untyped data on web).
  Map<String, dynamic> _dataOf(DocumentSnapshot snapshot) =>
      Map<String, dynamic>.from(snapshot.data() as Map? ?? const {});

  OnlineMatch _fromMap(String id, Map<String, dynamic> data) {
    return OnlineMatch(
      id: id,
      tigerPlayerId: data['tigerPlayerId'] as String?,
      goatPlayerId: data['goatPlayerId'] as String?,
      level: BoardLevel.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (data['level'] as String?)?.toLowerCase(),
        orElse: () => BoardLevel.traditional,
      ),
      timer: GameTimer.values.firstWhere(
        (e) => e.minutes == data['timer'],
        orElse: () => GameTimer.unlimited,
      ),
      status: MatchStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MatchStatus.waiting,
      ),
      moves: (data['moves'] as List? ?? const [])
          .map((m) => Move.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
      winner: data['winner'] == null
          ? null
          : GameWinner.values.firstWhere(
              (e) => e.name == data['winner'],
              orElse: () => GameWinner.none,
            ),
      inviteCode: data['inviteCode'] as String?,
      drawOffer: data['drawOffer'] as String?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Future<OnlineMatch?> _claimSlot(
    DocumentReference ref,
    String slot,
    String playerId,
  ) async {
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = _dataOf(snap);
        if (!snap.exists ||
            data['status'] != MatchStatus.waiting.name ||
            data[slot] != null) {
          throw StateError('Match no longer available');
        }
        tx.update(ref, {
          slot: playerId,
          'status': MatchStatus.inProgress.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
      final doc = await ref.get();
      return _fromMap(doc.id, _dataOf(doc));
    } catch (_) {
      try {
        await ref.update({
          slot: playerId,
          'status': MatchStatus.inProgress.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        final doc = await ref.get();
        return _fromMap(doc.id, _dataOf(doc));
      } catch (_) {
        return null;
      }
    }
  }
}

/// Provider for MultiplayerService
final multiplayerServiceProvider = Provider<MultiplayerService>((ref) {
  return MultiplayerService();
});
