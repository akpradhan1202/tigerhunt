import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/challenges/screens/challenges_screen.dart';
import '../../features/history/screens/game_history_screen.dart';
import '../../features/play/screens/play_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../features/tournaments/screens/tournaments_screen.dart';
import '../../features/tutorial/screens/tutorial_screen.dart';
import '../../features/rules/screens/game_rules_screen.dart';
import '../../features/game/screens/game_screen.dart';
import '../../features/game/screens/game_setup_screen.dart';
import '../../features/game/models/game_models.dart';
import '../../features/multiplayer/screens/online_play_screen.dart';
import '../../features/challenges/models/challenge_models.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../services/auth_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // Login
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final name = state.uri.queryParameters['name'] ?? extra['name'] as String?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: LoginScreen(name: name),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),

      // Play (game hub / landing screen)
      GoRoute(
        path: '/play',
        name: 'play',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final name = state.uri.queryParameters['name'] ?? extra['name'] as String?;
          if (name != null && name.trim().isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final auth = ref.read(authServiceProvider);
              if (!auth.isAuthenticated || (auth.isGuest && auth.user?.displayName != name.trim())) {
                ref.read(authServiceProvider.notifier).signInAsGuest(name: name.trim());
              }
            });
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: const PlayScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),

      // Game Setup
      GoRoute(
        path: '/setup',
        name: 'setup',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: GameSetupScreen(
              isVsAI: extra['isVsAI'] as bool? ?? true,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),

      // Puzzles
      GoRoute(
        path: '/puzzles',
        name: 'puzzles',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChallengesScreen(initialTab: 1),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Learn (Tutorial)
      GoRoute(
        path: '/learn',
        name: 'learn',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TutorialScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Rules & Info
      GoRoute(
        path: '/rules',
        name: 'rules',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GameRulesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Stats
      GoRoute(
        path: '/stats',
        name: 'stats',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StatsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Tournaments
      GoRoute(
        path: '/tournaments',
        name: 'tournaments',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TournamentsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Game History
      GoRoute(
        path: '/history',
        name: 'history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GameHistoryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Game
      GoRoute(
        path: '/game',
        name: 'game',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final name = state.uri.queryParameters['name'] ?? extra['name'] as String?;
          if (name != null && name.trim().isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final auth = ref.read(authServiceProvider);
              if (!auth.isAuthenticated || (auth.isGuest && auth.user?.displayName != name.trim())) {
                ref.read(authServiceProvider.notifier).signInAsGuest(name: name.trim());
              }
            });
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: GameScreen(
              level: extra['level'] as BoardLevel? ?? BoardLevel.square,
              mode: extra['mode'] as GameMode? ?? GameMode.offline,
              timer: extra['timer'] as GameTimer? ?? GameTimer.unlimited,
              aiDifficulty: extra['aiDifficulty'] as AIDifficulty?,
              playerRole: extra['playerRole'] as PieceType?,
              matchId: extra['matchId'] as String?,
              puzzle: extra['puzzle'] as Puzzle?,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              final tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),

      // Play Online
      GoRoute(
        path: '/online',
        name: 'online',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialTab = extra?['tab'] as int? ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: OnlinePlayScreen(initialTab: initialTab),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),

      // Leaderboard
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _PlaceholderScreen(title: 'Leaderboard'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _PlaceholderScreen(title: 'Profile'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    ],
  );
});

// Placeholder screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$title\nComing Soon!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
