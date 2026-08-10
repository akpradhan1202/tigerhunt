import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/game/screens/game_screen.dart';
import '../../features/game/models/game_models.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // Login
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Home
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
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
          return CustomTransitionPage(
            key: state.pageKey,
            child: GameScreen(
              level: extra['level'] as BoardLevel? ?? BoardLevel.traditional,
              mode: extra['mode'] as GameMode? ?? GameMode.offline,
              timer: extra['timer'] as GameTimer? ?? GameTimer.unlimited,
              aiDifficulty: extra['aiDifficulty'] as AIDifficulty?,
              playerRole: extra['playerRole'] as PieceType?,
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
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _PlaceholderScreen(title: 'Play Online'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
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
          child: const _PlaceholderScreen(title: 'Settings'),
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
