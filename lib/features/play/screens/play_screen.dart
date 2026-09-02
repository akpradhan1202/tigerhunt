import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/multiplayer_service.dart';
import '../../game/models/game_models.dart';
import '../../auth/providers/profile_provider.dart';
import '../widgets/notifications_dialog.dart';

/// Landing screen after login: the game hub with the Play section selected.
/// Replaces the old Home screen - quick play, game modes and board levels
/// all live here under the "Play" nav item.
///
/// Responsive: wide screens (>= 900px) get the persistent sidebar; narrow
/// screens (phones) get a top app bar + navigation drawer and the card rows
/// stack vertically.
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  static const double _desktopBreakpoint = 900;

  int _selectedNavIndex = 0;
  OnlineMatch? _activeMatch;
  Timer? _activeMatchPoller;

  @override
  void initState() {
    super.initState();
    _checkActiveMatch();
    _activeMatchPoller = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _checkActiveMatch();
    });
  }

  @override
  void dispose() {
    _activeMatchPoller?.cancel();
    super.dispose();
  }

  Future<void> _checkActiveMatch() async {
    try {
      final service = ref.read(multiplayerServiceProvider);
      if (!MultiplayerService.isConfigured) return;
      final playerId = await service.ensureReady();
      final match = await service.getActiveMatch(playerId);
      if (mounted) {
        setState(() => _activeMatch = match);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _desktopBreakpoint;
        if (isWide) {
          return _buildDesktopLayout();
        }
        return _buildMobileLayout();
      },
    );
  }

  // =====================================================================
  // Desktop: persistent sidebar + content
  // =====================================================================

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  // =====================================================================
  // Mobile: app bar + drawer + content
  // =====================================================================

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkestBg,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.tigerOrange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('🐯', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'TigerHunt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white70),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.terracotta,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () => NotificationsDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined, color: AppTheme.tigerOrange),
            tooltip: 'Game Rules & Info',
            onPressed: () => context.go('/rules'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        top: false,
        child: _buildMainContent(),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.darkestBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.tigerOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🐯', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'TigerHunt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildNavItem(Icons.play_arrow_rounded, 'Play', 0, isExpandable: true),
            _buildNavItem(
              Icons.extension,
              'Puzzles',
              1,
              onTap: () => context.go('/puzzles'),
            ),
            _buildNavItem(
              Icons.school,
              'Learn',
              2,
              onTap: () => context.go('/learn'),
            ),
            const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
            _buildNavItem(
              Icons.leaderboard,
              'Stats',
              3,
              onTap: () => context.go('/stats'),
            ),
            _buildNavItem(
              Icons.emoji_events,
              'Tournaments',
              4,
              onTap: () => context.go('/tournaments'),
            ),
            _buildNavItem(
              Icons.history,
              'Game History',
              5,
              onTap: () => context.go('/history'),
            ),
            _buildNavItem(
              Icons.menu_book,
              'Rules & Info',
              6,
              onTap: () => context.go('/rules'),
            ),
            const Spacer(),
            _buildProfileCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: AppTheme.darkestBg,
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.tigerOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🐯', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'TigerHunt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Nav Items
          _buildNavItem(Icons.play_arrow_rounded, 'Play', 0, isExpandable: true),
          _buildNavItem(
            Icons.extension,
            'Puzzles',
            1,
            onTap: () => context.go('/puzzles'),
          ),
          _buildNavItem(
            Icons.school,
            'Learn',
            2,
            onTap: () => context.go('/learn'),
          ),

          const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),

          _buildNavItem(
            Icons.leaderboard,
            'Stats',
            3,
            onTap: () => context.go('/stats'),
          ),
          _buildNavItem(
            Icons.emoji_events,
            'Tournaments',
            4,
            onTap: () => context.go('/tournaments'),
          ),
          _buildNavItem(
            Icons.history,
            'Game History',
            5,
            onTap: () => context.go('/history'),
          ),
          _buildNavItem(
            Icons.menu_book,
            'Rules & Info',
            6,
            onTap: () => context.go('/rules'),
          ),

          const Spacer(),

          _buildProfileCard(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final profile = ref.watch(profileProvider);
    final authUser = ref.watch(authServiceProvider).user;
    final name = profile?.displayName ??
        (authUser != null && authUser.displayName.isNotEmpty
            ? authUser.displayName
            : 'Guest Player');
    final photoUrl = profile?.photoUrl ?? authUser?.photoUrl;
    final rating = profile?.stats.overallRating;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.greenAccent,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.turmeric, size: 12),
                    const SizedBox(width: 4),
                    Text(rating != null ? '$rating' : '—',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index, {
    bool isExpandable = false,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        setState(() => _selectedNavIndex = index);
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppTheme.greenAccent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.greenAccent : Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (isExpandable)
              const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: AppTheme.darkBg,
      child: Column(
        children: [
          // Top Bar (desktop only; mobile uses the AppBar)
          if (_isWide())
            _buildTopBar(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ongoing Game Banner (if match in progress)
                  _buildOngoingMatchBanner(),

                  // Quick Play Section
                  _buildQuickPlaySection(),

                  const SizedBox(height: 32),

                  // Game Cards Section
                  _buildGameCardsSection(),

                  const SizedBox(height: 32),

                  // Board Levels Section
                  _buildBoardLevelsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isWide() {
    return MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
  }

  Widget _buildOngoingMatchBanner() {
    final match = _activeMatch;
    if (match == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B2500), Color(0xFFE86A17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE86A17).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Text('🎮', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE GAME',
                        style: TextStyle(
                          color: Color(0xFF8B2500),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        match.level.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Timer: ${match.timer.label} • Match in progress',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              ref.read(multiplayerServiceProvider).cancelMatch(match.id);
              setState(() => _activeMatch = null);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white60),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            child: const Text('Dismiss'),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: () {
              final playerId = ref.read(authServiceProvider).user?.id ?? '';
              final myRole = match.roleOf(playerId) ?? PieceType.tiger;
              context.go('/game', extra: {
                'level': match.level,
                'mode': GameMode.online,
                'timer': match.timer,
                'aiDifficulty': null,
                'playerRole': myRole,
                'matchId': match.id,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF8B2500),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  void _guardNewGame(VoidCallback onProceed) {
    if (_activeMatch != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ongoing Game Active', style: TextStyle(color: Colors.white)),
          content: const Text(
            'You already have an active online match in progress. Would you like to resume it or resign first?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(multiplayerServiceProvider).cancelMatch(_activeMatch!.id);
                setState(() => _activeMatch = null);
                onProceed();
              },
              child: const Text('Abandon & Start New', style: TextStyle(color: AppTheme.terracotta)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final playerId = ref.read(authServiceProvider).user?.id ?? '';
                final myRole = _activeMatch!.roleOf(playerId) ?? PieceType.tiger;
                context.go('/game', extra: {
                  'level': _activeMatch!.level,
                  'mode': GameMode.online,
                  'timer': _activeMatch!.timer,
                  'aiDifficulty': null,
                  'playerRole': myRole,
                  'matchId': _activeMatch!.id,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenAccent),
              child: const Text('Resume Game'),
            ),
          ],
        ),
      );
      return;
    }
    onProceed();
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkerBg,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.white54, size: 20),
                  SizedBox(width: 12),
                  Text('Search...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white70),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.terracotta,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () => NotificationsDialog.show(context),
          ),

          IconButton(
            icon: const Icon(Icons.menu_book_outlined, color: AppTheme.tigerOrange),
            tooltip: 'Game Rules & Info',
            onPressed: () => context.go('/rules'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPlaySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.greenDark, AppTheme.greenAccent.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;
          final buttons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => _guardNewGame(() => context.go('/setup', extra: {'isVsAI': true})),
                icon: const Icon(Icons.smart_toy, size: 18),
                label: const Text('Play Bots'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.greenDark,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _onPlayWithFriendTapped,
                icon: const Icon(Icons.people, size: 18),
                label: const Text('Play a Friend'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          );

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready to Play?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Challenge the AI or play with a friend',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (compact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _guardNewGame(() => context.go('/setup', extra: {'isVsAI': true})),
                            icon: const Icon(Icons.smart_toy, size: 18),
                            label: const Text('Play Bots'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.greenDark,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _onPlayWithFriendTapped,
                            icon: const Icon(Icons.people, size: 18),
                            label: const Text('Play a Friend'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      )
                    else
                      buttons,
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 24),
                // Decorative tiger
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🐯', style: TextStyle(fontSize: 50)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _onPlayWithFriendTapped() {
    final auth = ref.read(authServiceProvider);
    if (auth.user?.isGuest == true) {
      _showGuestFriendPrompt();
    } else {
      _guardNewGame(() => context.go('/online', extra: {'tab': 1}));
    }
  }

  void _showGuestFriendPrompt() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.tigerOrange),
            SizedBox(width: 8),
            Text('Sign In Required', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Playing with friends, adding friends, and sending custom challenges requires a registered account.\n\nSign in or register for free to play with friends!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay as Guest', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.tigerOrange),
            child: const Text('Sign In / Register'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Play',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _buildGameCard(
                icon: Icons.wifi,
                title: 'Play Online',
                subtitle: 'Challenge players worldwide',
                color: AppTheme.peacockBlue,
                badge: 'LIVE',
                onTap: () => _guardNewGame(() => context.go('/online')),
              ),
              _buildGameCard(
                icon: Icons.smart_toy_outlined,
                title: 'Play Bots',
                subtitle: 'Practice against AI',
                color: AppTheme.greenAccent,
                onTap: () => _guardNewGame(() => context.go('/setup', extra: {'isVsAI': true})),
              ),
              _buildGameCard(
                icon: Icons.people,
                title: 'Pass & Play',
                subtitle: 'Two players, one device (Offline)',
                color: AppTheme.saffron,
                onTap: () => _guardNewGame(() => context.go('/setup', extra: {'isVsAI': false})),
              ),
            ];

            if (constraints.maxWidth >= 700) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  cards[i],
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badge != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardLevelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Board Levels',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _buildBoardLevelCard(
                name: 'Pyramid',
                level: 'Level 1',
                description: 'Beginner',
                icon: '🔺',
                color: AppTheme.turmeric,
                isUnlocked: true,
                onTap: () => _guardNewGame(() => context.go('/setup', extra: {'level': BoardLevel.pyramid, 'isVsAI': true})),
              ),
              _buildBoardLevelCard(
                name: 'Square',
                level: 'Level 2',
                description: 'Intermediate',
                icon: '⬛',
                color: AppTheme.peacockBlue,
                isUnlocked: true,
                onTap: () => _guardNewGame(() => context.go('/setup', extra: {'level': BoardLevel.square, 'isVsAI': true})),
              ),
              _buildBoardLevelCard(
                name: 'Traditional',
                level: 'Level 3',
                description: 'Advanced',
                icon: '✦',
                color: AppTheme.greenAccent,
                isUnlocked: true,
                onTap: () => _guardNewGame(() => context.go('/setup', extra: {'level': BoardLevel.traditional, 'isVsAI': true})),
              ),
            ];

            if (constraints.maxWidth >= 700) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  cards[i],
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBoardLevelCard({
    required String name,
    required String level,
    required String description,
    required String icon,
    required Color color,
    required bool isUnlocked,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isUnlocked ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? color.withValues(alpha: 0.3) : Colors.white12,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 28)),
                    if (!isUnlocked)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock, color: Colors.white54, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              level,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
