import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/game_record.dart';
import '../../game/models/game_models.dart';

/// Card displaying a game history entry
class GameHistoryCard extends StatelessWidget {
  final GameRecord record;
  final String currentUserId;
  final VoidCallback onTap;

  const GameHistoryCard({
    super.key,
    required this.record,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final didWin = record.didWin(currentUserId);
    final role = record.getPlayerRole(currentUserId);
    final opponentName = record.getOpponentName(currentUserId);
    final ratingChange = role == PieceType.tiger
        ? record.tigerRatingChange
        : record.goatRatingChange;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: didWin
                ? AppTheme.forestGreen.withOpacity(0.3)
                : record.winner == GameWinner.draw
                    ? AppTheme.sandalwood
                    : Colors.red.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkBrown.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top row: Result and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Result badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: didWin
                        ? AppTheme.forestGreen.withOpacity(0.15)
                        : record.winner == GameWinner.draw
                            ? AppTheme.sandalwood.withOpacity(0.3)
                            : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        didWin ? '🏆' : record.winner == GameWinner.draw ? '🤝' : '❌',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        didWin ? 'Victory' : record.winner == GameWinner.draw ? 'Draw' : 'Defeat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: didWin
                              ? AppTheme.forestGreen
                              : record.winner == GameWinner.draw
                                  ? AppTheme.henna
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time ago
                Text(
                  _formatTimeAgo(record.playedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.charcoal.withOpacity(0.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Middle row: Players
            Row(
              children: [
                // You
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        role == PieceType.tiger ? '🐯' : '🐐',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'You',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.charcoal,
                              ),
                            ),
                            Text(
                              role == PieceType.tiger ? 'Tigers' : 'Goats',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.charcoal.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // VS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'vs',
                    style: TextStyle(
                      color: AppTheme.charcoal.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Opponent
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              opponentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.charcoal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              role == PieceType.tiger ? 'Goats' : 'Tigers',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.charcoal.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        role == PieceType.tiger ? '🐐' : '🐯',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Bottom row: Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.timer_outlined,
                  value: _formatDuration(record.gameDuration),
                  label: 'Duration',
                ),
                _StatItem(
                  icon: Icons.touch_app,
                  value: '${record.totalMoves}',
                  label: 'Moves',
                ),
                _StatItem(
                  icon: Icons.trending_up,
                  value: '${ratingChange >= 0 ? '+' : ''}$ratingChange',
                  label: 'Rating',
                  valueColor: ratingChange >= 0
                      ? AppTheme.forestGreen
                      : Colors.red,
                ),
                _StatItem(
                  icon: Icons.grid_view,
                  value: record.level.name,
                  label: 'Board',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.charcoal.withOpacity(0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.charcoal,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.charcoal.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
