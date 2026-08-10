import 'package:equatable/equatable.dart';

/// User profile model
class UserProfile extends Equatable {
  final String id;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final AuthProvider authProvider;
  final PlayerStats stats;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isGuest;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.authProvider,
    required this.stats,
    required this.createdAt,
    required this.lastLoginAt,
    this.isGuest = false,
  });

  factory UserProfile.guest() {
    final now = DateTime.now();
    return UserProfile(
      id: 'guest_${now.millisecondsSinceEpoch}',
      displayName: 'Guest Player',
      authProvider: AuthProvider.guest,
      stats: PlayerStats.initial(),
      createdAt: now,
      lastLoginAt: now,
      isGuest: true,
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    PlayerStats? stats,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      authProvider: authProvider,
      stats: stats ?? this.stats,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isGuest: isGuest,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'authProvider': authProvider.name,
        'stats': stats.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt.toIso8601String(),
        'isGuest': isGuest,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      authProvider: AuthProvider.values.firstWhere(
        (e) => e.name == json['authProvider'],
        orElse: () => AuthProvider.guest,
      ),
      stats: PlayerStats.fromJson(json['stats'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      isGuest: json['isGuest'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, displayName, email, stats];
}

/// Authentication providers
enum AuthProvider {
  google('Google'),
  apple('Apple'),
  email('Email'),
  guest('Guest');

  final String displayName;
  const AuthProvider(this.displayName);
}

/// Player statistics and ratings
class PlayerStats extends Equatable {
  // Overall stats
  final int totalGames;
  final int wins;
  final int losses;
  final int draws;

  // Role-specific stats
  final int tigerWins;
  final int tigerLosses;
  final int goatWins;
  final int goatLosses;

  // ELO ratings (separate for tiger and goat)
  final int overallRating;
  final int tigerRating;
  final int goatRating;
  final int peakRating;

  // Streaks
  final int currentWinStreak;
  final int bestWinStreak;

  // Points (like chess.com XP)
  final int totalPoints;
  final int level;

  // Achievements
  final List<String> achievements;

  const PlayerStats({
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.tigerWins,
    required this.tigerLosses,
    required this.goatWins,
    required this.goatLosses,
    required this.overallRating,
    required this.tigerRating,
    required this.goatRating,
    required this.peakRating,
    required this.currentWinStreak,
    required this.bestWinStreak,
    required this.totalPoints,
    required this.level,
    required this.achievements,
  });

  factory PlayerStats.initial() => const PlayerStats(
        totalGames: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        tigerWins: 0,
        tigerLosses: 0,
        goatWins: 0,
        goatLosses: 0,
        overallRating: 1200, // Starting ELO
        tigerRating: 1200,
        goatRating: 1200,
        peakRating: 1200,
        currentWinStreak: 0,
        bestWinStreak: 0,
        totalPoints: 0,
        level: 1,
        achievements: [],
      );

  double get winRate => totalGames > 0 ? (wins / totalGames) * 100 : 0;
  double get tigerWinRate =>
      (tigerWins + tigerLosses) > 0 ? (tigerWins / (tigerWins + tigerLosses)) * 100 : 0;
  double get goatWinRate =>
      (goatWins + goatLosses) > 0 ? (goatWins / (goatWins + goatLosses)) * 100 : 0;

  String get rank => RatingTier.fromRating(overallRating).name;
  RatingTier get tier => RatingTier.fromRating(overallRating);

  /// Points needed for next level
  int get pointsForNextLevel => (level * 100) + ((level - 1) * 50);
  int get pointsInCurrentLevel => totalPoints - _totalPointsForLevel(level - 1);
  double get levelProgress => pointsInCurrentLevel / pointsForNextLevel;

  int _totalPointsForLevel(int lvl) {
    if (lvl <= 0) return 0;
    int total = 0;
    for (int i = 1; i <= lvl; i++) {
      total += (i * 100) + ((i - 1) * 50);
    }
    return total;
  }

  PlayerStats copyWith({
    int? totalGames,
    int? wins,
    int? losses,
    int? draws,
    int? tigerWins,
    int? tigerLosses,
    int? goatWins,
    int? goatLosses,
    int? overallRating,
    int? tigerRating,
    int? goatRating,
    int? peakRating,
    int? currentWinStreak,
    int? bestWinStreak,
    int? totalPoints,
    int? level,
    List<String>? achievements,
  }) {
    return PlayerStats(
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      tigerWins: tigerWins ?? this.tigerWins,
      tigerLosses: tigerLosses ?? this.tigerLosses,
      goatWins: goatWins ?? this.goatWins,
      goatLosses: goatLosses ?? this.goatLosses,
      overallRating: overallRating ?? this.overallRating,
      tigerRating: tigerRating ?? this.tigerRating,
      goatRating: goatRating ?? this.goatRating,
      peakRating: peakRating ?? this.peakRating,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      bestWinStreak: bestWinStreak ?? this.bestWinStreak,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      achievements: achievements ?? this.achievements,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalGames': totalGames,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'tigerWins': tigerWins,
        'tigerLosses': tigerLosses,
        'goatWins': goatWins,
        'goatLosses': goatLosses,
        'overallRating': overallRating,
        'tigerRating': tigerRating,
        'goatRating': goatRating,
        'peakRating': peakRating,
        'currentWinStreak': currentWinStreak,
        'bestWinStreak': bestWinStreak,
        'totalPoints': totalPoints,
        'level': level,
        'achievements': achievements,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      totalGames: json['totalGames'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      tigerWins: json['tigerWins'] as int? ?? 0,
      tigerLosses: json['tigerLosses'] as int? ?? 0,
      goatWins: json['goatWins'] as int? ?? 0,
      goatLosses: json['goatLosses'] as int? ?? 0,
      overallRating: json['overallRating'] as int? ?? 1200,
      tigerRating: json['tigerRating'] as int? ?? 1200,
      goatRating: json['goatRating'] as int? ?? 1200,
      peakRating: json['peakRating'] as int? ?? 1200,
      currentWinStreak: json['currentWinStreak'] as int? ?? 0,
      bestWinStreak: json['bestWinStreak'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
        totalGames,
        wins,
        overallRating,
        totalPoints,
        level,
      ];
}

/// Rating tiers (like Chess.com)
enum RatingTier {
  beginner(0, 800, 'Beginner', '🌱'),
  novice(800, 1000, 'Novice', '🎯'),
  intermediate(1000, 1200, 'Intermediate', '⭐'),
  skilled(1200, 1400, 'Skilled', '🌟'),
  advanced(1400, 1600, 'Advanced', '💫'),
  expert(1600, 1800, 'Expert', '🔥'),
  master(1800, 2000, 'Master', '👑'),
  grandmaster(2000, 2200, 'Grandmaster', '🏆'),
  legend(2200, 9999, 'Legend', '💎');

  final int minRating;
  final int maxRating;
  final String displayName;
  final String icon;

  const RatingTier(this.minRating, this.maxRating, this.displayName, this.icon);

  static RatingTier fromRating(int rating) {
    for (final tier in RatingTier.values) {
      if (rating >= tier.minRating && rating < tier.maxRating) {
        return tier;
      }
    }
    return RatingTier.beginner;
  }

  /// Progress within this tier (0.0 - 1.0)
  double progressInTier(int rating) {
    if (rating < minRating) return 0;
    if (rating >= maxRating) return 1;
    return (rating - minRating) / (maxRating - minRating);
  }
}
