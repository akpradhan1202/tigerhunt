import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../features/game/models/game_models.dart';
import '../../features/game/models/game_state.dart';
import '../../features/auth/models/user_profile.dart';

/// Online match status
enum MatchStatus {
  waiting,      // Waiting for opponent
  inProgress,   // Game is active
  completed,    // Game finished
  cancelled,    // Match was cancelled
}

/// Online match model
class OnlineMatch {
  final String id;
  final String tigerPlayerId;
  final String? goatPlayerId;
  final BoardLevel level;
  final GameTimer timer;
  final MatchStatus status;
  final GameState? gameState;
  final DateTime createdAt;
  final String? inviteCode;

  OnlineMatch({
    required this.id,
    required this.tigerPlayerId,
    this.goatPlayerId,
    required this.level,
    required this.timer,
    required this.status,
    this.gameState,
    required this.createdAt,
    this.inviteCode,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tigerPlayerId': tigerPlayerId,
    'goatPlayerId': goatPlayerId,
    'level': level.name,
    'timer': timer.minutes,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'inviteCode': inviteCode,
  };

  factory OnlineMatch.fromJson(Map<String, dynamic> json) {
    return OnlineMatch(
      id: json['id'] as String,
      tigerPlayerId: json['tigerPlayerId'] as String,
      goatPlayerId: json['goatPlayerId'] as String?,
      level: BoardLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => BoardLevel.traditional,
      ),
      timer: GameTimer.values.firstWhere(
        (e) => e.minutes == json['timer'],
        orElse: () => GameTimer.unlimited,
      ),
      status: MatchStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MatchStatus.waiting,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      inviteCode: json['inviteCode'] as String?,
    );
  }
}

/// Service for handling online multiplayer
class MultiplayerService {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;

  MultiplayerService({
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database ?? FirebaseDatabase.instance;

  // Collection references
  CollectionReference get _matchesCollection =>
      _firestore.collection('matches');

  CollectionReference get _usersCollection =>
      _firestore.collection('users');

  DatabaseReference get _activeGamesRef =>
      _database.ref('active_games');

  /// Create a new match (waiting for opponent)
  Future<OnlineMatch> createMatch({
    required String playerId,
    required BoardLevel level,
    required GameTimer timer,
    bool playAsTiger = true,
    String? inviteCode,
  }) async {
    final matchId = _matchesCollection.doc().id;

    final match = OnlineMatch(
      id: matchId,
      tigerPlayerId: playAsTiger ? playerId : '',
      goatPlayerId: playAsTiger ? null : playerId,
      level: level,
      timer: timer,
      status: MatchStatus.waiting,
      createdAt: DateTime.now(),
      inviteCode: inviteCode,
    );

    await _matchesCollection.doc(matchId).set(match.toJson());

    return match;
  }

  /// Find a random match to join
  Future<OnlineMatch?> findRandomMatch({
    required String playerId,
    required BoardLevel level,
    required GameTimer timer,
  }) async {
    // Find waiting matches with same settings
    final query = await _matchesCollection
        .where('status', isEqualTo: MatchStatus.waiting.name)
        .where('level', isEqualTo: level.name)
        .where('timer', isEqualTo: timer.minutes)
        .where('tigerPlayerId', isNotEqualTo: playerId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final matchDoc = query.docs.first;
    final match = OnlineMatch.fromJson(
      matchDoc.data() as Map<String, dynamic>,
    );

    // Join the match as goat player
    await matchDoc.reference.update({
      'goatPlayerId': playerId,
      'status': MatchStatus.inProgress.name,
    });

    return match;
  }

  /// Join a match by invite code
  Future<OnlineMatch?> joinByInviteCode({
    required String playerId,
    required String inviteCode,
  }) async {
    final query = await _matchesCollection
        .where('inviteCode', isEqualTo: inviteCode)
        .where('status', isEqualTo: MatchStatus.waiting.name)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final matchDoc = query.docs.first;
    final match = OnlineMatch.fromJson(
      matchDoc.data() as Map<String, dynamic>,
    );

    // Don't allow joining own match
    if (match.tigerPlayerId == playerId) return null;

    // Join the match
    await matchDoc.reference.update({
      'goatPlayerId': playerId,
      'status': MatchStatus.inProgress.name,
    });

    return match;
  }

  /// Listen to match updates
  Stream<OnlineMatch?> watchMatch(String matchId) {
    return _matchesCollection.doc(matchId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return OnlineMatch.fromJson(snapshot.data() as Map<String, dynamic>);
    });
  }

  /// Send a move to the match
  Future<void> sendMove({
    required String matchId,
    required Move move,
    required GameState newState,
  }) async {
    await _activeGamesRef.child(matchId).child('moves').push().set({
      'from': {'row': move.from.row, 'col': move.from.col},
      'to': {'row': move.to.row, 'col': move.to.col},
      'capturedAt': move.capturedAt != null
          ? {'row': move.capturedAt!.row, 'col': move.capturedAt!.col}
          : null,
      'pieceType': move.pieceType.name,
      'timestamp': ServerValue.timestamp,
    });

    // Update game state
    await _activeGamesRef.child(matchId).child('state').set({
      'currentTurn': newState.currentTurn.name,
      'phase': newState.phase.name,
      'goatsPlaced': newState.goatsPlaced,
      'goatsCaptured': newState.goatsCaptured,
      'winner': newState.winner.name,
    });
  }

  /// Listen to moves in real-time
  Stream<Move> watchMoves(String matchId) {
    return _activeGamesRef
        .child(matchId)
        .child('moves')
        .onChildAdded
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return Move(
        from: Position(
          (data['from']['row'] as num).toInt(),
          (data['from']['col'] as num).toInt(),
        ),
        to: Position(
          (data['to']['row'] as num).toInt(),
          (data['to']['col'] as num).toInt(),
        ),
        capturedAt: data['capturedAt'] != null
            ? Position(
                (data['capturedAt']['row'] as num).toInt(),
                (data['capturedAt']['col'] as num).toInt(),
              )
            : null,
        pieceType: PieceType.values.firstWhere(
          (e) => e.name == data['pieceType'],
        ),
      );
    });
  }

  /// Cancel a waiting match
  Future<void> cancelMatch(String matchId) async {
    await _matchesCollection.doc(matchId).update({
      'status': MatchStatus.cancelled.name,
    });
  }

  /// Complete a match with results
  Future<void> completeMatch({
    required String matchId,
    required GameWinner winner,
  }) async {
    await _matchesCollection.doc(matchId).update({
      'status': MatchStatus.completed.name,
      'winner': winner.name,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Clean up real-time data
    await _activeGamesRef.child(matchId).remove();
  }

  /// Get leaderboard
  Future<List<UserProfile>> getLeaderboard({int limit = 50}) async {
    final query = await _usersCollection
        .orderBy('stats.overallRating', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) {
      return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  /// Update user stats after a game
  Future<void> updateUserStats({
    required String odStatsId,
    required PlayerStats newStats,
  }) async {
    await _usersCollection.doc(userId).update({
      'stats': newStats.toJson(),
    });
  }

  /// Generate a unique invite code
  String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (var i = 0; i < 6; i++) {
      code += chars[(random + i * 7) % chars.length];
    }
    return code;
  }
}

// Helper extension
extension on String {
  String get userId => this;
}
