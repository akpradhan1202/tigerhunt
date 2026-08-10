import 'dart:async';
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
/// NOTE: This is a stub implementation. Firebase integration coming soon.
class MultiplayerService {
  MultiplayerService();

  /// Create a new match (waiting for opponent)
  /// Returns null - online multiplayer not yet implemented
  Future<OnlineMatch?> createMatch({
    required String playerId,
    required BoardLevel level,
    required GameTimer timer,
    bool playAsTiger = true,
    String? inviteCode,
  }) async {
    // TODO: Implement with Firebase when ready
    return null;
  }

  /// Find a random match to join
  /// Returns null - online multiplayer not yet implemented
  Future<OnlineMatch?> findRandomMatch({
    required String playerId,
    required BoardLevel level,
    required GameTimer timer,
  }) async {
    // TODO: Implement with Firebase when ready
    return null;
  }

  /// Join a match by invite code
  /// Returns null - online multiplayer not yet implemented
  Future<OnlineMatch?> joinByInviteCode({
    required String playerId,
    required String inviteCode,
  }) async {
    // TODO: Implement with Firebase when ready
    return null;
  }

  /// Listen to match updates
  Stream<OnlineMatch?> watchMatch(String matchId) {
    // Return empty stream - online multiplayer not yet implemented
    return const Stream.empty();
  }

  /// Send a move to the match
  Future<void> sendMove({
    required String matchId,
    required Move move,
    required GameState newState,
  }) async {
    // TODO: Implement with Firebase when ready
  }

  /// Listen to moves in real-time
  Stream<Move> watchMoves(String matchId) {
    // Return empty stream - online multiplayer not yet implemented
    return const Stream.empty();
  }

  /// Cancel a waiting match
  Future<void> cancelMatch(String matchId) async {
    // TODO: Implement with Firebase when ready
  }

  /// Complete a match with results
  Future<void> completeMatch({
    required String matchId,
    required GameWinner winner,
  }) async {
    // TODO: Implement with Firebase when ready
  }

  /// Get leaderboard
  Future<List<UserProfile>> getLeaderboard({int limit = 50}) async {
    // TODO: Implement with Firebase when ready
    return [];
  }

  /// Update user stats after a game
  Future<void> updateUserStats({
    required String odStatsId,
    required PlayerStats newStats,
  }) async {
    // TODO: Implement with Firebase when ready
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
