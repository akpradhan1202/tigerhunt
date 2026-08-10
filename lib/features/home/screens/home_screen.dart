import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_profile.dart';
import '../widgets/game_mode_card.dart';
import '../widgets/player_stats_card.dart';
import '../widgets/quick_action_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get actual user from provider
    final user = UserProfile.guest().copyWith(
      displayName: 'Player123',
      stats: PlayerStats.initial().copyWith(
        overallRating: 1350,
        totalGames: 47,
        wins: 28,
        losses: 15,
        draws: 4,
        currentWinStreak: 3,
        totalPoints: 850,
        level: 5,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar with profile
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.cream,
              elevation: 0,
              title: Row(
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🐯', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TigerHunt',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.terracotta,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                // Notifications
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                  color: AppTheme.charcoal,
                ),
                // Settings
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {},
                  color: AppTheme.charcoal,
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Player stats card
                  PlayerStatsCard(user: user),

                  const SizedBox(height: 24),

                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'Quick Play',
                          color: AppTheme.forestGreen,
                          onTap: () => context.go('/setup', extra: {'isVsAI': true}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.people_outline,
                          label: 'With Friend',
                          color: AppTheme.peacockBlue,
                          onTap: () => context.go('/setup', extra: {'isVsAI': false}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section title
                  Text(
                    'Play',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Game mode cards
                  GameModeCard(
                    icon: Icons.wifi,
                    title: 'Play Online',
                    subtitle: 'Challenge players worldwide',
                    color: AppTheme.terracotta,
                    badge: 'LIVE',
                    onTap: () {},
                  ),

                  const SizedBox(height: 12),

                  GameModeCard(
                    icon: Icons.smart_toy_outlined,
                    title: 'Play Bots',
                    subtitle: 'Practice against AI opponents',
                    color: AppTheme.forestGreen,
                    levels: ['Easy', 'Medium', 'Hard', 'Expert'],
                    onTap: () => context.go('/setup', extra: {'isVsAI': true}),
                  ),

                  const SizedBox(height: 12),

                  GameModeCard(
                    icon: Icons.people,
                    title: 'Pass & Play',
                    subtitle: 'Two players, one device',
                    color: AppTheme.peacockBlue,
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),

                  // Section title
                  Text(
                    'Learn',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  GameModeCard(
                    icon: Icons.school_outlined,
                    title: 'Tutorial',
                    subtitle: 'Learn the rules and strategies',
                    color: AppTheme.turmeric,
                    badge: 'NEW',
                    onTap: () {},
                  ),

                  const SizedBox(height: 12),

                  GameModeCard(
                    icon: Icons.auto_stories_outlined,
                    title: 'History',
                    subtitle: 'Discover the origins of Bagh-Chal',
                    color: AppTheme.henna,
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),

                  // Board levels section
                  Text(
                    'Board Levels',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Level selection cards
                  Row(
                    children: [
                      Expanded(
                        child: _BoardLevelCard(
                          name: 'Pyramid',
                          level: '1',
                          description: 'Beginner',
                          icon: '🔺',
                          isUnlocked: true,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BoardLevelCard(
                          name: 'Square',
                          level: '2',
                          description: 'Intermediate',
                          icon: '⬛',
                          isUnlocked: true,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BoardLevelCard(
                          name: 'Classic',
                          level: '3',
                          description: 'Advanced',
                          icon: '✦',
                          isUnlocked: false,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkBrown.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.terracotta,
          unselectedItemColor: AppTheme.charcoal.withOpacity(0.5),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Games',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardLevelCard extends StatelessWidget {
  final String name;
  final String level;
  final String description;
  final String icon;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _BoardLevelCard({
    required this.name,
    required this.level,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? AppTheme.terracotta.withOpacity(0.3)
                : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: AppTheme.inkBrown.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  icon,
                  style: TextStyle(
                    fontSize: 32,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
                if (!isUnlocked)
                  const Icon(
                    Icons.lock,
                    color: Colors.grey,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUnlocked ? AppTheme.charcoal : Colors.grey,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isUnlocked
                    ? AppTheme.charcoal.withOpacity(0.6)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
