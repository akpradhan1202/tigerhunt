import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/auth_service.dart';
import '../../game/models/game_models.dart';
import '../../game/models/game_state.dart';
import '../models/rating_system.dart';
import '../models/user_profile.dart';

/// Nominal ELO ratings used as the "opponent" when playing the AI, so beating a
/// harder AI moves your rating more than beating an easy one.
const Map<AIDifficulty, int> _aiRatings = {
  AIDifficulty.easy: 1000,
  AIDifficulty.medium: 1200,
  AIDifficulty.hard: 1500,
  AIDifficulty.expert: 1800,
};

/// Holds the signed-in user's [UserProfile] (display name, photo, rating and
/// stats), loaded from and persisted to local storage. `null` when signed out.
///
/// This is the single source of truth the home/play/stats screens read so the
/// profile card reflects the real account instead of a hardcoded placeholder.
class ProfileService extends StateNotifier<UserProfile?> {
  ProfileService() : super(null);

  static const String _keyPrefix = 'profile_';

  SharedPreferences? _prefs;
  String? _currentKey;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Storage key for a user. Guests share one stable key so their local
  /// progress survives across guest sessions (guest ids are random each run).
  String _keyFor(AppUser user) =>
      '$_keyPrefix${user.isGuest ? 'guest' : user.id}';

  static AuthProvider _providerFor(AuthType type) {
    switch (type) {
      case AuthType.google:
        return AuthProvider.google;
      case AuthType.apple:
        return AuthProvider.apple;
      case AuthType.guest:
        return AuthProvider.guest;
    }
  }

  UserProfile _freshProfile(AppUser user) {
    final now = DateTime.now();
    return UserProfile(
      id: user.id,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoUrl,
      authProvider: _providerFor(user.authType),
      stats: PlayerStats.initial(),
      createdAt: now,
      lastLoginAt: now,
      isGuest: user.isGuest,
    );
  }

  /// Load the stored profile for [user], creating a fresh one (starting rating
  /// 1200) on first sign-in. Refreshes name/photo/email from the account in
  /// case they changed. Signing out ([user] == null) clears the profile.
  Future<void> loadForUser(AppUser? user) async {
    if (user == null) {
      _currentKey = null;
      state = null;
      return;
    }
    _currentKey = _keyFor(user);
    try {
      final store = await _store;
      final raw = store.getString(_currentKey!);
      final UserProfile profile;
      if (raw != null) {
        profile = UserProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        ).copyWith(
          displayName: user.displayName,
          email: user.email,
          photoUrl: user.photoUrl,
          lastLoginAt: DateTime.now(),
        );
      } else {
        profile = _freshProfile(user);
      }
      state = profile;
      await _persist();
    } catch (_) {
      // Storage unavailable (e.g. in widget tests): still surface the real
      // account in memory so the UI shows the signed-in name, not a fallback.
      state = _freshProfile(user);
    }
  }

  Future<void> _persist() async {
    final key = _currentKey;
    final profile = state;
    if (key == null || profile == null) return;
    try {
      final store = await _store;
      await store.setString(key, jsonEncode(profile.toJson()));
    } catch (_) {
      // Best-effort persistence.
    }
  }

  /// Update the signed-in player's rating and stats after a finished game.
  ///
  /// ELO is applied for games against the AI (offline mode with a difficulty);
  /// the AI's nominal rating scales with difficulty. Local pass-and-play and
  /// online games are ignored here for now (no reliable opponent rating is
  /// available in this context).
  Future<void> recordGameResult({
    required GameWinner winner,
    required PieceType playerRole,
    required GameMode mode,
    AIDifficulty? aiDifficulty,
  }) async {
    final profile = state;
    if (profile == null) return;
    if (winner == GameWinner.none) return;
    if (mode != GameMode.offline || aiDifficulty == null) return;

    final s = profile.stats;
    final bool isDraw = winner == GameWinner.draw;
    final bool playerWon =
        (playerRole == PieceType.tiger && winner == GameWinner.tigers) ||
            (playerRole == PieceType.goat && winner == GameWinner.goats);
    final bool isTiger = playerRole == PieceType.tiger;

    final int opponentRating = _aiRatings[aiDifficulty] ?? 1200;
    final int myRating = s.overallRating;

    // Feed the player into the winner slot on a win/draw, the loser slot on a
    // loss, so the ELO math is from the player's perspective.
    final bool playerInWinnerSlot = playerWon || isDraw;
    final RatingResult r = RatingSystem.calculateNewRatings(
      winnerRating: playerInWinnerSlot ? myRating : opponentRating,
      loserRating: playerInWinnerSlot ? opponentRating : myRating,
      winnerGames: playerInWinnerSlot ? s.totalGames : 30,
      loserGames: playerInWinnerSlot ? 30 : s.totalGames,
      isDraw: isDraw,
    );

    final int newRating =
        playerInWinnerSlot ? r.winnerNewRating : r.loserNewRating;
    final int pointsEarned =
        playerInWinnerSlot ? r.winnerPointsEarned : r.loserPointsEarned;
    final int newStreak = playerWon ? s.currentWinStreak + 1 : 0;
    final int newTotalPoints = s.totalPoints + pointsEarned;

    final newStats = s.copyWith(
      totalGames: s.totalGames + 1,
      wins: s.wins + (playerWon ? 1 : 0),
      losses: s.losses + (!playerWon && !isDraw ? 1 : 0),
      draws: s.draws + (isDraw ? 1 : 0),
      tigerWins: s.tigerWins + (isTiger && playerWon ? 1 : 0),
      tigerLosses: s.tigerLosses + (isTiger && !playerWon && !isDraw ? 1 : 0),
      goatWins: s.goatWins + (!isTiger && playerWon ? 1 : 0),
      goatLosses: s.goatLosses + (!isTiger && !playerWon && !isDraw ? 1 : 0),
      overallRating: newRating,
      tigerRating: isTiger ? newRating : s.tigerRating,
      goatRating: !isTiger ? newRating : s.goatRating,
      peakRating: newRating > s.peakRating ? newRating : s.peakRating,
      currentWinStreak: newStreak,
      bestWinStreak: newStreak > s.bestWinStreak ? newStreak : s.bestWinStreak,
      totalPoints: newTotalPoints,
      level: RatingSystem.levelFromPoints(newTotalPoints),
    );

    state = profile.copyWith(stats: newStats);
    await _persist();
  }
}

/// Current signed-in user's profile, kept in sync with [authServiceProvider].
final profileProvider =
    StateNotifierProvider<ProfileService, UserProfile?>((ref) {
  final service = ProfileService();
  ref.listen<AuthState>(
    authServiceProvider,
    (previous, next) => service.loadForUser(next.user),
    fireImmediately: true,
  );
  return service;
});
