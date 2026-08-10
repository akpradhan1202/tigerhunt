import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/tournament_models.dart';

/// Tournament listing card
class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  Color get _statusColor {
    switch (tournament.status) {
      case TournamentStatus.registering:
        return AppTheme.forestGreen;
      case TournamentStatus.inProgress:
        return AppTheme.terracotta;
      case TournamentStatus.completed:
        return AppTheme.charcoal;
      default:
        return AppTheme.sandalwood;
    }
  }

  String get _statusText {
    switch (tournament.status) {
      case TournamentStatus.registering:
        return 'OPEN';
      case TournamentStatus.inProgress:
        return 'LIVE';
      case TournamentStatus.completed:
        return 'ENDED';
      case TournamentStatus.upcoming:
        return 'SOON';
      default:
        return 'CANCELLED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: tournament.isFeatured
              ? Border.all(color: AppTheme.turmeric, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkBrown.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Format icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFormatColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getFormatEmoji(),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tournament.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tournament.status == TournamentStatus.inProgress)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  _statusText,
                                  style: TextStyle(
                                    color: _statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tournament.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.charcoal.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Info row
            Row(
              children: [
                _buildInfoChip(
                  Icons.people_outline,
                  '${tournament.currentPlayers}/${tournament.maxPlayers}',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.timer_outlined,
                  tournament.timeControl.label,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.grid_view,
                  tournament.boardLevel.name,
                ),
                const Spacer(),
                // Prize
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.turmeric.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: AppTheme.turmeric,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${tournament.prizes.first.points} XP',
                        style: const TextStyle(
                          color: AppTheme.turmeric,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Time remaining (for upcoming/registering)
            if (tournament.status == TournamentStatus.registering) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.forestGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Starts in ${_formatTimeUntil(tournament.startTime)}',
                      style: const TextStyle(
                        color: AppTheme.forestGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.parchment,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.charcoal.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.charcoal.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFormatColor() {
    switch (tournament.format) {
      case TournamentFormat.knockout:
        return AppTheme.terracotta;
      case TournamentFormat.swiss:
        return AppTheme.peacockBlue;
      case TournamentFormat.roundRobin:
        return AppTheme.forestGreen;
      case TournamentFormat.arena:
        return AppTheme.turmeric;
    }
  }

  String _getFormatEmoji() {
    switch (tournament.format) {
      case TournamentFormat.knockout:
        return '🏆';
      case TournamentFormat.swiss:
        return '♟️';
      case TournamentFormat.roundRobin:
        return '🔄';
      case TournamentFormat.arena:
        return '⚔️';
    }
  }

  String _formatTimeUntil(DateTime time) {
    final diff = time.difference(DateTime.now());
    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours.remainder(24)}h';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    } else {
      return '${diff.inMinutes}m';
    }
  }
}
