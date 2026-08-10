import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../game/models/game_models.dart';
import '../models/tournament_models.dart';
import '../widgets/tournament_card.dart';
import '../widgets/tournament_bracket.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        title: const Text(
          'Tournaments',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateTournament,
            color: AppTheme.charcoal,
            tooltip: 'Create Tournament',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.terracotta,
          labelColor: AppTheme.terracotta,
          unselectedLabelColor: AppTheme.charcoal.withOpacity(0.5),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Upcoming'),
            Tab(text: 'My Tournaments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildUpcomingTab(),
          _buildMyTournamentsTab(),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    final tournaments = _getMockActiveTournaments();

    if (tournaments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No active tournaments',
        subtitle: 'Check upcoming tournaments or create your own!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TournamentCard(
            tournament: tournament,
            onTap: () => _openTournament(tournament),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingTab() {
    final tournaments = _getMockUpcomingTournaments();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Featured tournament banner
        _buildFeaturedBanner(),
        const SizedBox(height: 24),

        // Tournament list
        Text(
          'Upcoming Tournaments',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.charcoal,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        ...tournaments.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TournamentCard(
                tournament: t,
                onTap: () => _openTournament(t),
              ),
            )),
      ],
    );
  }

  Widget _buildMyTournamentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats summary
        _buildMyStatsCard(),
        const SizedBox(height: 24),

        Text(
          'Current Tournaments',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.charcoal,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Currently participating tournaments
        _buildMyTournamentItem(
          name: 'Weekly Arena',
          position: 12,
          totalPlayers: 64,
          status: 'Round 4 of 6',
          nextMatch: '2 hours',
        ),

        const SizedBox(height: 24),

        Text(
          'Past Results',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.charcoal,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        _buildPastTournamentItem(
          name: 'Beginner Championship',
          position: 3,
          prize: '🥉 +150 XP',
          date: 'Aug 5, 2026',
        ),
        _buildPastTournamentItem(
          name: 'Friday Blitz',
          position: 8,
          prize: '+50 XP',
          date: 'Aug 1, 2026',
        ),
      ],
    );
  }

  Widget _buildFeaturedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.peacockBlue, Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.peacockBlue.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '⭐ FEATURED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '🏆 Grand Championship',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compete for 5,000 XP prize pool',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBannerStat('Format', 'Knockout'),
              _buildBannerStat('Players', '32/64'),
              _buildBannerStat('Starts in', '2d 5h'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.peacockBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Register Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkBrown.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                '🏆',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tournament Stats',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '12 tournaments played',
                      style: TextStyle(
                        color: AppTheme.charcoal.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🥇', '2', 'Wins'),
              _buildStatItem('🥈', '3', '2nd Place'),
              _buildStatItem('🥉', '4', '3rd Place'),
              _buildStatItem('⭐', '1,250', 'XP Earned'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.charcoal.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMyTournamentItem({
    required String name,
    required int position,
    required int totalPlayers,
    required String status,
    required String nextMatch,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.terracotta.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.terracotta.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$position',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.terracotta,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.charcoal.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Next match',
                style: TextStyle(fontSize: 10),
              ),
              Text(
                nextMatch,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.terracotta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPastTournamentItem({
    required String name,
    required int position,
    required String prize,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            position <= 3 ? ['🥇', '🥈', '🥉'][position - 1] : '🎮',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.charcoal.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            prize,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.forestGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.sandalwood),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.charcoal.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _openTournament(Tournament tournament) {
    // Navigate to tournament detail screen
  }

  void _showCreateTournament() {
    // Show create tournament dialog
  }

  List<Tournament> _getMockActiveTournaments() {
    return [
      Tournament(
        id: '1',
        name: 'Daily Arena',
        description: 'Play as many games as you can in 1 hour',
        format: TournamentFormat.arena,
        status: TournamentStatus.inProgress,
        boardLevel: BoardLevel.traditional,
        timeControl: GameTimer.five,
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        maxPlayers: 100,
        currentPlayers: 45,
        prizes: const [
          TournamentPrize(position: 1, title: '1st Place', points: 500),
          TournamentPrize(position: 2, title: '2nd Place', points: 300),
          TournamentPrize(position: 3, title: '3rd Place', points: 150),
        ],
        createdBy: 'system',
      ),
    ];
  }

  List<Tournament> _getMockUpcomingTournaments() {
    return [
      Tournament(
        id: '2',
        name: 'Weekend Blitz',
        description: '32-player knockout tournament',
        format: TournamentFormat.knockout,
        status: TournamentStatus.registering,
        boardLevel: BoardLevel.traditional,
        timeControl: GameTimer.ten,
        startTime: DateTime.now().add(const Duration(hours: 5)),
        maxPlayers: 32,
        currentPlayers: 24,
        prizes: const [
          TournamentPrize(position: 1, title: '1st Place', points: 1000),
          TournamentPrize(position: 2, title: '2nd Place', points: 500),
          TournamentPrize(position: 3, title: '3rd Place', points: 250),
        ],
        createdBy: 'system',
        isFeatured: true,
      ),
      Tournament(
        id: '3',
        name: 'Beginner Friendly',
        description: 'For players rated under 1200',
        format: TournamentFormat.swiss,
        status: TournamentStatus.registering,
        boardLevel: BoardLevel.pyramid,
        timeControl: GameTimer.fifteen,
        startTime: DateTime.now().add(const Duration(days: 1)),
        maxPlayers: 16,
        currentPlayers: 8,
        maxRating: 1200,
        prizes: const [
          TournamentPrize(position: 1, title: '1st Place', points: 300),
          TournamentPrize(position: 2, title: '2nd Place', points: 150),
        ],
        createdBy: 'system',
      ),
    ];
  }
}
