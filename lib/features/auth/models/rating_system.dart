import 'dart:math';

/// ELO Rating calculation system
class RatingSystem {
  // K-factor determines how much ratings change per game
  static const int kFactorNew = 40;      // New players (< 30 games)
  static const int kFactorNormal = 20;   // Normal players
  static const int kFactorHigh = 10;     // High rated players (> 2000)

  /// Calculate new ratings after a game
  static RatingResult calculateNewRatings({
    required int winnerRating,
    required int loserRating,
    required int winnerGames,
    required int loserGames,
    bool isDraw = false,
  }) {
    final winnerK = _getKFactor(winnerRating, winnerGames);
    final loserK = _getKFactor(loserRating, loserGames);

    // Expected scores
    final winnerExpected = _expectedScore(winnerRating, loserRating);
    final loserExpected = 1 - winnerExpected;

    // Actual scores
    final winnerActual = isDraw ? 0.5 : 1.0;
    final loserActual = isDraw ? 0.5 : 0.0;

    // New ratings
    final winnerNewRating = (winnerRating + winnerK * (winnerActual - winnerExpected)).round();
    final loserNewRating = (loserRating + loserK * (loserActual - loserExpected)).round();

    // Points earned (bonus for beating higher rated players)
    final ratingDiff = loserRating - winnerRating;
    final basePoints = isDraw ? 5 : 15;
    final bonusPoints = isDraw ? 0 : max(0, (ratingDiff / 50).round());

    return RatingResult(
      winnerNewRating: max(100, winnerNewRating),
      loserNewRating: max(100, loserNewRating),
      winnerRatingChange: winnerNewRating - winnerRating,
      loserRatingChange: loserNewRating - loserRating,
      winnerPointsEarned: basePoints + bonusPoints,
      loserPointsEarned: isDraw ? 5 : 2, // Participation points
    );
  }

  /// Calculate expected score (probability of winning)
  static double _expectedScore(int playerRating, int opponentRating) {
    return 1 / (1 + pow(10, (opponentRating - playerRating) / 400));
  }

  /// Get K-factor based on rating and experience
  static int _getKFactor(int rating, int games) {
    if (games < 30) return kFactorNew;
    if (rating > 2000) return kFactorHigh;
    return kFactorNormal;
  }

  /// Calculate points for beating AI
  static int pointsForAIWin(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 5;
      case 'medium':
        return 10;
      case 'hard':
        return 15;
      case 'expert':
        return 20;
      default:
        return 5;
    }
  }

  /// Calculate level from total points
  static int levelFromPoints(int points) {
    int level = 1;
    int required = 100;
    int total = 0;

    while (total + required <= points) {
      total += required;
      level++;
      required = (level * 100) + ((level - 1) * 50);
    }

    return level;
  }
}

/// Result of a rating calculation
class RatingResult {
  final int winnerNewRating;
  final int loserNewRating;
  final int winnerRatingChange;
  final int loserRatingChange;
  final int winnerPointsEarned;
  final int loserPointsEarned;

  const RatingResult({
    required this.winnerNewRating,
    required this.loserNewRating,
    required this.winnerRatingChange,
    required this.loserRatingChange,
    required this.winnerPointsEarned,
    required this.loserPointsEarned,
  });
}

/// Achievements system
class Achievements {
  static const List<Achievement> all = [
    // Beginner achievements
    Achievement(
      id: 'first_win',
      name: 'First Victory',
      description: 'Win your first game',
      icon: '🎉',
      points: 10,
    ),
    Achievement(
      id: 'first_tiger_win',
      name: 'Fierce Hunter',
      description: 'Win a game as Tigers',
      icon: '🐯',
      points: 10,
    ),
    Achievement(
      id: 'first_goat_win',
      name: 'United We Stand',
      description: 'Win a game as Goats',
      icon: '🐐',
      points: 10,
    ),

    // Progress achievements
    Achievement(
      id: 'wins_10',
      name: 'Rising Star',
      description: 'Win 10 games',
      icon: '⭐',
      points: 25,
    ),
    Achievement(
      id: 'wins_50',
      name: 'Veteran',
      description: 'Win 50 games',
      icon: '🌟',
      points: 50,
    ),
    Achievement(
      id: 'wins_100',
      name: 'Champion',
      description: 'Win 100 games',
      icon: '🏆',
      points: 100,
    ),

    // Streak achievements
    Achievement(
      id: 'streak_3',
      name: 'Hot Streak',
      description: 'Win 3 games in a row',
      icon: '🔥',
      points: 15,
    ),
    Achievement(
      id: 'streak_5',
      name: 'Unstoppable',
      description: 'Win 5 games in a row',
      icon: '💪',
      points: 30,
    ),
    Achievement(
      id: 'streak_10',
      name: 'Legendary',
      description: 'Win 10 games in a row',
      icon: '👑',
      points: 75,
    ),

    // Rating achievements
    Achievement(
      id: 'rating_1400',
      name: 'Skilled Player',
      description: 'Reach 1400 rating',
      icon: '📈',
      points: 25,
    ),
    Achievement(
      id: 'rating_1600',
      name: 'Expert',
      description: 'Reach 1600 rating',
      icon: '🎯',
      points: 50,
    ),
    Achievement(
      id: 'rating_1800',
      name: 'Master',
      description: 'Reach 1800 rating',
      icon: '🎖️',
      points: 100,
    ),
    Achievement(
      id: 'rating_2000',
      name: 'Grandmaster',
      description: 'Reach 2000 rating',
      icon: '💎',
      points: 200,
    ),

    // Special achievements
    Achievement(
      id: 'quick_win',
      name: 'Swift Victory',
      description: 'Win a game in under 2 minutes',
      icon: '⚡',
      points: 20,
    ),
    Achievement(
      id: 'comeback',
      name: 'Comeback King',
      description: 'Win after losing 4 goats',
      icon: '🦸',
      points: 30,
    ),
    Achievement(
      id: 'perfect_trap',
      name: 'Perfect Trap',
      description: 'Trap all tigers without losing a goat',
      icon: '🎯',
      points: 50,
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int points;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.points,
  });
}
