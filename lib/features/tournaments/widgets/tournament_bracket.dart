import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/tournament_models.dart';

/// Tournament bracket visualization for knockout tournaments
class TournamentBracket extends StatelessWidget {
  final List<TournamentMatch> matches;
  final int totalRounds;
  final String? currentUserId;
  final Function(TournamentMatch)? onMatchTap;

  const TournamentBracket({
    super.key,
    required this.matches,
    required this.totalRounds,
    this.currentUserId,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(totalRounds, (roundIndex) {
              final roundMatches = matches
                  .where((m) => m.round == roundIndex + 1)
                  .toList();

              return _buildRound(
                context,
                roundIndex + 1,
                roundMatches,
                totalRounds,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildRound(
    BuildContext context,
    int round,
    List<TournamentMatch> roundMatches,
    int totalRounds,
  ) {
    final roundTitle = _getRoundTitle(round, totalRounds);

    // Calculate spacing based on round
    final verticalSpacing = 20.0 * (1 << (round - 1)); // Exponential spacing

    return Column(
      children: [
        // Round header
        Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: round == totalRounds
                ? AppTheme.turmeric.withValues(alpha: 0.2)
                : AppTheme.parchment,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: round == totalRounds
                  ? AppTheme.turmeric
                  : AppTheme.sandalwood,
            ),
          ),
          child: Text(
            roundTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: round == totalRounds
                  ? AppTheme.turmeric
                  : AppTheme.charcoal,
            ),
          ),
        ),

        // Matches
        ...List.generate(roundMatches.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? verticalSpacing / 2 : 0,
              bottom: verticalSpacing,
            ),
            child: Row(
              children: [
                _buildMatchCard(roundMatches[index]),
                if (round < totalRounds)
                  _buildConnector(round, index, roundMatches.length),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    final isUserMatch = currentUserId != null &&
        (match.player1Id == currentUserId || match.player2Id == currentUserId);

    return GestureDetector(
      onTap: onMatchTap != null ? () => onMatchTap!(match) : null,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUserMatch
                ? AppTheme.terracotta
                : AppTheme.sandalwood.withValues(alpha: 0.5),
            width: isUserMatch ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkBrown.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildPlayerSlot(
              playerId: match.player1Id,
              score: match.player1Score,
              isWinner: match.winnerId == match.player1Id,
              isCurrentUser: match.player1Id == currentUserId,
              isTop: true,
            ),
            Container(
              height: 1,
              color: AppTheme.sandalwood.withValues(alpha: 0.3),
            ),
            _buildPlayerSlot(
              playerId: match.player2Id,
              score: match.player2Score,
              isWinner: match.winnerId == match.player2Id,
              isCurrentUser: match.player2Id == currentUserId,
              isTop: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSlot({
    required String? playerId,
    required int? score,
    required bool isWinner,
    required bool isCurrentUser,
    required bool isTop,
  }) {
    final isBye = playerId == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isWinner
            ? AppTheme.forestGreen.withValues(alpha: 0.1)
            : isCurrentUser
                ? AppTheme.terracotta.withValues(alpha: 0.05)
                : Colors.transparent,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(11) : Radius.zero,
          bottom: !isTop ? const Radius.circular(11) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          // Player avatar
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isBye
                  ? AppTheme.sandalwood.withValues(alpha: 0.3)
                  : isCurrentUser
                      ? AppTheme.terracotta.withValues(alpha: 0.2)
                      : AppTheme.peacockBlue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isBye
                  ? const Text('-', style: TextStyle(color: Colors.grey))
                  : Text(
                      _getInitials(playerId),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser
                            ? AppTheme.terracotta
                            : AppTheme.peacockBlue,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // Player name
          Expanded(
            child: Text(
              isBye ? 'BYE' : _getPlayerName(playerId),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isBye
                    ? Colors.grey
                    : isWinner
                        ? AppTheme.forestGreen
                        : AppTheme.charcoal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Score
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isWinner
                    ? AppTheme.forestGreen.withValues(alpha: 0.2)
                    : AppTheme.sandalwood.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                score.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? AppTheme.forestGreen : AppTheme.charcoal,
                ),
              ),
            ),

          // Winner indicator
          if (isWinner) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.emoji_events,
              size: 14,
              color: AppTheme.turmeric,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnector(int round, int matchIndex, int totalMatchesInRound) {
    const connectorWidth = 40.0;
    final spacing = 20.0 * (1 << (round - 1));

    return SizedBox(
      width: connectorWidth,
      height: spacing * 2,
      child: CustomPaint(
        painter: _ConnectorPainter(
          matchIndex: matchIndex,
          totalMatches: totalMatchesInRound,
          spacing: spacing,
        ),
      ),
    );
  }

  String _getRoundTitle(int round, int totalRounds) {
    if (round == totalRounds) return '🏆 Final';
    if (round == totalRounds - 1) return 'Semi-Finals';
    if (round == totalRounds - 2) return 'Quarter-Finals';
    return 'Round $round';
  }

  String _getInitials(String playerId) {
    // In real app, fetch from user profile
    return playerId.substring(0, 2).toUpperCase();
  }

  String _getPlayerName(String playerId) {
    // In real app, fetch from user profile
    return 'Player ${playerId.substring(0, 4)}';
  }
}

class _ConnectorPainter extends CustomPainter {
  final int matchIndex;
  final int totalMatches;
  final double spacing;

  _ConnectorPainter({
    required this.matchIndex,
    required this.totalMatches,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.sandalwood
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final startY = size.height / 2;
    final midX = size.width / 2;
    final endY = size.height / 2 + (matchIndex.isEven ? spacing / 2 : -spacing / 2);

    // Draw horizontal line from match
    canvas.drawLine(
      Offset(0, startY),
      Offset(midX, startY),
      paint,
    );

    // Draw vertical connector
    if (matchIndex % 2 == 0) {
      canvas.drawLine(
        Offset(midX, startY),
        Offset(midX, startY + spacing),
        paint,
      );
    }

    // Draw horizontal line to next round
    canvas.drawLine(
      Offset(midX, endY),
      Offset(size.width, endY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Swiss pairing standings table
class SwissStandingsTable extends StatelessWidget {
  final List<TournamentStanding> standings;
  final String? currentUserId;

  const SwissStandingsTable({
    super.key,
    required this.standings,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkBrown.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.peacockBlue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 32, child: Text('#', style: _headerStyle)),
                Expanded(flex: 3, child: Text('Player', style: _headerStyle)),
                SizedBox(width: 50, child: Text('W', style: _headerStyle)),
                SizedBox(width: 50, child: Text('D', style: _headerStyle)),
                SizedBox(width: 50, child: Text('L', style: _headerStyle)),
                SizedBox(width: 60, child: Text('Pts', style: _headerStyle)),
              ],
            ),
          ),

          // Standings rows
          ...standings.asMap().entries.map((entry) {
            final index = entry.key;
            final standing = entry.value;
            final isCurrentUser = standing.odStatsId == currentUserId;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppTheme.terracotta.withValues(alpha: 0.1)
                    : index.isOdd
                        ? AppTheme.parchment.withValues(alpha: 0.5)
                        : Colors.transparent,
                border: isCurrentUser
                    ? Border.all(color: AppTheme.terracotta)
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${standing.position}',
                      style: TextStyle(
                        fontWeight: standing.position <= 3
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _getPositionColor(standing.position),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        if (standing.position <= 3)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              ['🥇', '🥈', '🥉'][standing.position - 1],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                standing.playerName,
                                style: TextStyle(
                                  fontWeight: isCurrentUser
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${standing.playerRating}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.charcoal.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${standing.wins}',
                      style: const TextStyle(color: AppTheme.forestGreen),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${standing.draws}',
                      style: TextStyle(color: AppTheme.charcoal.withValues(alpha: 0.6)),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${standing.losses}',
                      style: const TextStyle(color: AppTheme.terracotta),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${standing.points}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.charcoal;
    }
  }

  static const _headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 12,
    color: AppTheme.peacockBlue,
  );
}

/// Arena leaderboard with live scores
class ArenaLeaderboard extends StatelessWidget {
  final List<TournamentStanding> standings;
  final String? currentUserId;
  final Duration? timeRemaining;

  const ArenaLeaderboard({
    super.key,
    required this.standings,
    this.currentUserId,
    this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Time remaining bar
        if (timeRemaining != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.terracotta,
                  AppTheme.terracotta.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(timeRemaining!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  ' remaining',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Top 3 podium
        if (standings.length >= 3) _buildPodium(standings.take(3).toList()),

        const SizedBox(height: 16),

        // Rest of leaderboard
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: standings.length > 3 ? standings.length - 3 : 0,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppTheme.sandalwood.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final standing = standings[index + 3];
              final isCurrentUser = standing.odStatsId == currentUserId;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isCurrentUser
                    ? AppTheme.terracotta.withValues(alpha: 0.1)
                    : null,
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${standing.position}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.peacockBlue.withValues(alpha: 0.2),
                      child: Text(
                        standing.playerName.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.peacockBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        standing.playerName,
                        style: TextStyle(
                          fontWeight:
                              isCurrentUser ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '${standing.gamesPlayed} games',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.charcoal.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.turmeric.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${standing.points}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.turmeric,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<TournamentStanding> top3) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        _buildPodiumSpot(top3[1], 2, 80),
        const SizedBox(width: 8),
        // 1st place
        _buildPodiumSpot(top3[0], 1, 100),
        const SizedBox(width: 8),
        // 3rd place
        _buildPodiumSpot(top3[2], 3, 60),
      ],
    );
  }

  Widget _buildPodiumSpot(TournamentStanding standing, int position, double height) {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];
    final emojis = ['🥇', '🥈', '🥉'];

    return Column(
      children: [
        // Player info
        CircleAvatar(
          radius: position == 1 ? 32 : 24,
          backgroundColor: colors[position - 1].withValues(alpha: 0.3),
          child: Text(
            standing.playerName.substring(0, 1),
            style: TextStyle(
              fontSize: position == 1 ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: colors[position - 1],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          standing.playerName,
          style: TextStyle(
            fontSize: position == 1 ? 14 : 12,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${standing.points} pts',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.turmeric,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Podium block
        Container(
          width: position == 1 ? 90 : 70,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors[position - 1],
                colors[position - 1].withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              emojis[position - 1],
              style: TextStyle(fontSize: position == 1 ? 28 : 22),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Extension for winnerId
extension TournamentMatchExt on TournamentMatch {
  String? get winnerId => odStatsId;
}
