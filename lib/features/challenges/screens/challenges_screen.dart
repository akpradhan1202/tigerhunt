import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/challenge_models.dart';
import '../widgets/challenge_card.dart';
import '../widgets/puzzle_card.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
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
          'Challenges',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.terracotta,
          labelColor: AppTheme.terracotta,
          unselectedLabelColor: AppTheme.charcoal.withOpacity(0.5),
          tabs: const [
            Tab(text: 'Daily', icon: Icon(Icons.today, size: 20)),
            Tab(text: 'Puzzles', icon: Icon(Icons.extension, size: 20)),
            Tab(text: 'Streak', icon: Icon(Icons.local_fire_department, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTab(),
          _buildPuzzlesTab(),
          _buildStreakTab(),
        ],
      ),
    );
  }

  Widget _buildDailyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's challenge banner
          _buildTodayBanner(),

          const SizedBox(height: 24),

          // Daily challenges list
          Text(
            'Today\'s Challenges',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.charcoal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          ChallengeCard(
            title: '🐯 Tiger Mastery',
            description: 'Capture 3 goats in a single game',
            difficulty: ChallengeDifficulty.easy,
            reward: 50,
            progress: 1,
            target: 3,
            isCompleted: false,
            onTap: () {},
          ),

          const SizedBox(height: 12),

          ChallengeCard(
            title: '🐐 Goat Guardian',
            description: 'Trap 2 tigers in one game',
            difficulty: ChallengeDifficulty.medium,
            reward: 100,
            progress: 0,
            target: 2,
            isCompleted: false,
            onTap: () {},
          ),

          const SizedBox(height: 12),

          ChallengeCard(
            title: '⚡ Speed Demon',
            description: 'Win a game in under 5 minutes',
            difficulty: ChallengeDifficulty.hard,
            reward: 200,
            progress: 0,
            target: 1,
            isCompleted: false,
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Weekly challenge
          Text(
            'Weekly Challenge',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.charcoal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          ChallengeCard(
            title: '🏆 Champion',
            description: 'Win 10 games this week',
            difficulty: ChallengeDifficulty.expert,
            reward: 500,
            progress: 6,
            target: 10,
            isCompleted: false,
            isWeekly: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTodayBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.terracotta, AppTheme.saffron],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.terracotta.withOpacity(0.4),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('📅', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Challenge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Complete all 3 challenges to earn bonus XP!',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.33,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1/3 Completed',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzlesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puzzle rating
          _buildPuzzleRatingCard(),

          const SizedBox(height: 24),

          // Beginner puzzles
          _buildPuzzleSection(
            'Beginner Puzzles',
            '🌱',
            PuzzleLibrary.beginnerPuzzles,
          ),

          const SizedBox(height: 24),

          // Intermediate puzzles
          _buildPuzzleSection(
            'Intermediate Puzzles',
            '⭐',
            PuzzleLibrary.intermediatePuzzles,
          ),

          const SizedBox(height: 24),

          // Advanced puzzles
          _buildPuzzleSection(
            'Advanced Puzzles',
            '🔥',
            PuzzleLibrary.advancedPuzzles,
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleRatingCard() {
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.peacockBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🧩', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Puzzle Rating',
                  style: TextStyle(
                    color: AppTheme.charcoal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      '1,250',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.peacockBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.forestGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+25 today',
                        style: TextStyle(
                          color: AppTheme.forestGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.peacockBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Play', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleSection(String title, String emoji, List<Puzzle> puzzles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.charcoal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...puzzles.map((puzzle) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PuzzleCard(
                puzzle: puzzle,
                onTap: () => _openPuzzle(puzzle),
              ),
            )),
      ],
    );
  }

  Widget _buildStreakTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Streak counter
          _buildStreakCard(),

          const SizedBox(height: 24),

          // Calendar view
          _buildStreakCalendar(),

          const SizedBox(height: 24),

          // Streak rewards
          Text(
            'Streak Rewards',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.charcoal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          _buildStreakReward(3, 'Bronze Streak', 50, true),
          _buildStreakReward(7, 'Silver Streak', 150, false),
          _buildStreakReward(14, 'Gold Streak', 400, false),
          _buildStreakReward(30, 'Diamond Streak', 1000, false),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.saffron, AppTheme.turmeric],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.saffron.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          const Text(
            '5 Day Streak!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep playing daily to maintain your streak',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '2 days until Silver Streak!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar() {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          final isToday = day.day == today.day;
          final hasPlayed = day.day != today.day || day.weekday <= 5;

          return Column(
            children: [
              Text(
                _weekdayShort(day.weekday),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.charcoal.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasPlayed
                      ? AppTheme.forestGreen
                      : (isToday
                          ? AppTheme.terracotta.withOpacity(0.2)
                          : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: AppTheme.terracotta, width: 2)
                      : null,
                ),
                child: Center(
                  child: hasPlayed
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isToday
                                ? AppTheme.terracotta
                                : AppTheme.charcoal.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStreakReward(int days, String title, int reward, bool claimed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: claimed
              ? AppTheme.forestGreen
              : AppTheme.sandalwood.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: claimed
                  ? AppTheme.forestGreen.withOpacity(0.15)
                  : AppTheme.sandalwood.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: claimed ? AppTheme.forestGreen : AppTheme.charcoal,
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
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: claimed ? AppTheme.forestGreen : AppTheme.charcoal,
                  ),
                ),
                Text(
                  '$reward XP',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.charcoal.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (claimed)
            const Icon(Icons.check_circle, color: AppTheme.forestGreen)
          else
            Icon(
              Icons.lock_outline,
              color: AppTheme.charcoal.withOpacity(0.3),
            ),
        ],
      ),
    );
  }

  void _openPuzzle(Puzzle puzzle) {
    // Navigate to puzzle screen
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
