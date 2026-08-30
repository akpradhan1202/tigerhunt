import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/rating_system.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/providers/profile_provider.dart';
import '../../home/widgets/player_stats_card.dart';

/// Player statistics screen (Chess.com-style profile)
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  /// Fallback profile shown only when no one is signed in (e.g. previewing
  /// the screen directly). Real users come from [profileProvider].
  static final UserProfile _fallbackUser = UserProfile(
    id: 'guest',
    displayName: 'Guest Player',
    authProvider: AuthProvider.guest,
    stats: PlayerStats.initial(),
    createdAt: DateTime(2026, 1, 1),
    lastLoginAt: DateTime.now(),
    isGuest: true,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider) ?? _fallbackUser;
    final stats = user.stats;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.charcoal),
          tooltip: 'Back to Play',
          onPressed: () => context.go('/play'),
        ),
        title: const Text(
          'Stats',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile + overall stats card
            PlayerStatsCard(user: user),

            const SizedBox(height: 24),

            // Role-specific ratings
            Text(
              'Role Ratings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.charcoal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildRoleRatingCard(
              emoji: '🐯',
              title: 'Tigers',
              rating: stats.tigerRating,
              winRate: stats.tigerWinRate,
              wins: stats.tigerWins,
              losses: stats.tigerLosses,
              color: AppTheme.tigerOrange,
            ),
            const SizedBox(height: 12),
            _buildRoleRatingCard(
              emoji: '🐐',
              title: 'Goats',
              rating: stats.goatRating,
              winRate: stats.goatWinRate,
              wins: stats.goatWins,
              losses: stats.goatLosses,
              color: AppTheme.forestGreen,
            ),

            const SizedBox(height: 24),

            // Record summary
            Text(
              'Overall Record',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.charcoal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildRecordRow(stats),

            const SizedBox(height: 24),

            // Achievements
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.charcoal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${stats.achievements.length} of ${Achievements.all.length} unlocked',
              style: TextStyle(
                color: AppTheme.charcoal.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            ...Achievements.all.map((a) => _buildAchievementCard(a, stats)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleRatingCard({
    required String emoji,
    required String title,
    required int rating,
    required double winRate,
    required int wins,
    required int losses,
    required Color color,
  }) {
    final tier = RatingTier.fromRating(rating);
    final nextTierIndex = tier.index + 1;
    final hasNextTier = nextTierIndex < RatingTier.values.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    Text(
                      '$wins Wins · $losses Losses · ${winRate.toStringAsFixed(0)}% win rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.charcoal.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$rating',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '${tier.icon} ${tier.displayName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.charcoal.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress toward next tier
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: tier.progressInTier(rating),
                    backgroundColor: AppTheme.sandalwood.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                hasNextTier
                    ? '${RatingTier.values[nextTierIndex].displayName} at ${RatingTier.values[nextTierIndex].minRating}'
                    : 'Max tier reached!',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.charcoal.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(PlayerStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildRecordItem('Wins', '${stats.wins}', AppTheme.forestGreen),
          _buildRecordItem('Losses', '${stats.losses}', AppTheme.terracotta),
          _buildRecordItem('Draws', '${stats.draws}', AppTheme.sandalwood),
          _buildRecordItem(
            'Peak',
            '${stats.peakRating}',
            AppTheme.turmeric,
          ),
          _buildRecordItem(
            'Best Streak',
            '${stats.bestWinStreak}🔥',
            AppTheme.peacockBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.charcoal.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement, PlayerStats stats) {
    final unlocked = stats.achievements.contains(achievement.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? AppTheme.forestGreen.withValues(alpha: 0.3)
              : AppTheme.sandalwood.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: unlocked ? 1.0 : 0.35,
            child: Text(achievement.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: unlocked
                        ? AppTheme.charcoal
                        : AppTheme.charcoal.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.charcoal.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${achievement.points} XP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: unlocked
                  ? AppTheme.forestGreen
                  : AppTheme.charcoal.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            size: 18,
            color: unlocked
                ? AppTheme.forestGreen
                : AppTheme.charcoal.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
