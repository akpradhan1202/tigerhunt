import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/multiplayer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../game/models/game_models.dart';

class OnlinePlayScreen extends ConsumerStatefulWidget {
  const OnlinePlayScreen({super.key});

  @override
  ConsumerState<OnlinePlayScreen> createState() => _OnlinePlayScreenState();
}

class _OnlinePlayScreenState extends ConsumerState<OnlinePlayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  BoardLevel _selectedLevel = BoardLevel.traditional;
  GameTimer _selectedTimer = GameTimer.ten;
  bool _playAsTiger = true;
  String _inviteCode = '';
  bool _isSearching = false;
  bool _isJoining = false;

  String? _playerId;
  OnlineMatch? _waitingMatch;
  StreamSubscription<OnlineMatch>? _subscription;
  StreamSubscription<int>? _onlineCountSub;
  Timer? _heartbeatTimer;
  int _onlineCount = 1;
  bool _dialogVisible = false;

  late final MultiplayerService _service;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = ref.read(multiplayerServiceProvider);
    _connectPresence();
  }

  /// Connect to Firebase and start the presence heartbeat + online counter.
  Future<void> _connectPresence() async {
    try {
      final playerId = await _ensurePlayer();
      if (!mounted) return;
      await _service.heartbeatPresence(playerId);
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        _service.heartbeatPresence(playerId);
      });
      _onlineCountSub = _service.watchOnlineCount().listen((count) {
        if (mounted) setState(() => _onlineCount = count);
      });
    } catch (_) {
      // Online count is best-effort; the screen still works without it.
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _onlineCountSub?.cancel();
    _heartbeatTimer?.cancel();
    _cancelWaitingMatch();
    _tabController.dispose();
    super.dispose();
  }

  /// Cancel the match we created while waiting, so it does not linger.
  void _cancelWaitingMatch() {
    final matchId = _waitingMatch?.id;
    if (matchId != null) {
      _service.cancelMatch(matchId);
    }
    _waitingMatch = null;
  }

  Future<String> _ensurePlayer() async {
    return _playerId ??= await _service.ensureReady();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.terracotta,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Turn a raw exception into an actionable, human-readable message. Firestore
  /// surfaces backend setup problems as [FirebaseException]s with a `code`;
  /// translate the common ones so the user sees a fix instead of a stack trace.
  String _friendlyError(Object error, String action) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Online play is blocked by your Firestore security rules. '
              'Publish rules that allow signed-in users to read/write.';
        case 'failed-precondition':
          return error.message != null && error.message!.isNotEmpty
              ? '$action: ${error.message}'
              : 'Failed precondition. Check if Cloud Firestore database is created in Firebase Console.';
        case 'unavailable':
          return 'Can\'t reach the game servers. Check your connection and '
              'that Cloud Firestore is enabled for this project.';
        case 'unauthenticated':
          return 'You need to be signed in to play online. Enable Anonymous '
              'sign-in in Firebase Console → Authentication.';
        case 'not-found':
          return 'No Cloud Firestore database found. Create one in Firebase '
              'Console → Firestore Database.';
      }
      return '$action: ${error.message ?? error.code}';
    }
    return '$action: $error';
  }

  void _launchGame(OnlineMatch match) {
    if (!mounted) return;
    final myRole = match.roleOf(_playerId ?? '') ?? PieceType.goat;
    context.go('/game', extra: {
      'level': match.level,
      'mode': GameMode.online,
      'timer': match.timer,
      'aiDifficulty': null,
      'playerRole': myRole,
      'matchId': match.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    // Without real Firebase credentials there is nothing to connect to.
    if (!MultiplayerService.isConfigured) {
      return _buildNotConfigured();
    }

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
          'Play Online',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.forestGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_onlineCount online',
                      style: const TextStyle(
                        color: AppTheme.forestGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.terracotta,
          labelColor: AppTheme.terracotta,
          unselectedLabelColor: AppTheme.charcoal.withValues(alpha: 0.5),
          tabs: const [
            Tab(text: 'Find Match'),
            Tab(text: 'Play with Friend'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFindMatchTab(),
          _buildPlayWithFriendTab(),
        ],
      ),
    );
  }

  Widget _buildNotConfigured() {
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
          'Play Online',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 72,
                color: AppTheme.sandalwood,
              ),
              const SizedBox(height: 20),
              const Text(
                'Online play needs Firebase',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Online multiplayer connects through Cloud Firestore, which is '
                'not configured yet. Connect the app to your Firebase project '
                'to unlock matchmaking and invite games.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.charcoal.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.peacockBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.peacockBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '1. Run:  flutterfire configure\n'
                  '2. Pick your Firebase project\n'
                  '3. Restart the app',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: AppTheme.charcoal,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FIND MATCH =================

  Widget _buildFindMatchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Time Control'),
          const SizedBox(height: 12),
          _buildTimerSelection(),
          const SizedBox(height: 24),
          _buildSectionTitle('Board Level'),
          const SizedBox(height: 12),
          _buildLevelSelection(),
          const SizedBox(height: 24),
          _buildSectionTitle('Play As'),
          const SizedBox(height: 12),
          _buildRoleSelection(),
          const SizedBox(height: 32),
          if (_isSearching)
            _buildSearchingState()
          else
            _buildFindMatchButton(),
        ],
      ),
    );
  }

  Widget _buildFindMatchButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startSearching,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.terracotta,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Find Match',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchingState() {
    final waitingMatch = _waitingMatch;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.terracotta.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.terracotta.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.terracotta,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            waitingMatch == null
                ? 'Finding opponent...'
                : 'Searching for opponent...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            waitingMatch == null
                ? 'Connecting to game server...'
                : 'Looking for a random player with matching settings...',
            style: TextStyle(
              color: AppTheme.charcoal.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _cancelSearch,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }



  Future<void> _startSearching() async {
    setState(() => _isSearching = true);
    Timer? searchTimeout;
    try {
      final playerId = await _ensurePlayer();

      // Try to join an existing waiting match first.
      final existing = await _service.findRandomMatch(
        playerId: playerId,
        level: _selectedLevel,
        timer: _selectedTimer,
        playAsTiger: _playAsTiger,
      );
      if (existing != null) {
        if (!mounted) return;
        setState(() => _isSearching = false);
        _launchGame(existing);
        return;
      }

      // No one is waiting: create our own match and wait for an opponent.
      final created = await _service.createMatch(
        playerId: playerId,
        level: _selectedLevel,
        timer: _selectedTimer,
        playAsTiger: _playAsTiger,
      );
      if (!mounted) return;
      setState(() => _waitingMatch = created);

      // Auto-cancel after 60 seconds if no opponent joins
      searchTimeout = Timer(const Duration(seconds: 60), () {
        if (mounted && _isSearching) {
          _cancelSearch();
          _showError('No opponent found. Try again or create a private game.');
        }
      });

      _subscription = _service.watchMatch(created.id).listen((match) {
        if (!mounted) return;
        if (match.status == MatchStatus.inProgress) {
          searchTimeout?.cancel();
          _subscription?.cancel();
          _subscription = null;
          setState(() {
            _isSearching = false;
            _waitingMatch = null;
          });
          _launchGame(match);
        } else if (match.status == MatchStatus.cancelled ||
            match.status == MatchStatus.completed) {
          searchTimeout?.cancel();
          _subscription?.cancel();
          _subscription = null;
          setState(() {
            _isSearching = false;
            _waitingMatch = null;
          });
        }
      });
    } on FirebaseNotConfiguredException catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      _showError(_friendlyError(e, 'Could not find a match'));
    }
  }

  void _cancelSearch() {
    _subscription?.cancel();
    _subscription = null;
    _cancelWaitingMatch();
    setState(() => _isSearching = false);
  }

  // ================= PLAY WITH FRIEND =================

  Widget _buildPlayWithFriendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Create Game'),
          const SizedBox(height: 12),
          _buildCreateGameCard(),
          const SizedBox(height: 32),
          _buildSectionTitle('Join Game'),
          const SizedBox(height: 12),
          _buildJoinGameCard(),
        ],
      ),
    );
  }

  Widget _buildCreateGameCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sandalwood),
      ),
      child: Column(
        children: [
          const Icon(Icons.share, size: 48, color: AppTheme.peacockBlue),
          const SizedBox(height: 12),
          const Text(
            'Create a private game and share\nthe code with your friend',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.charcoal),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createPrivateGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.peacockBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Game',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinGameCard() {
    final canJoin = _inviteCode.length == 6 && !_isJoining;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sandalwood),
      ),
      child: Column(
        children: [
          const Text(
            'Enter invite code',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.sandalwood),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.forestGreen, width: 2),
              ),
            ),
            onChanged: (value) => setState(() {
              _inviteCode = value.toUpperCase();
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canJoin ? _joinWithCode : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isJoining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Join Game',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createPrivateGame() async {
    try {
      final playerId = await _ensurePlayer();
      final match = await _service.createMatch(
        playerId: playerId,
        level: _selectedLevel,
        timer: _selectedTimer,
        playAsTiger: _playAsTiger,
      );
      if (!mounted) return;
      _waitingMatch = match;
      _dialogVisible = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _InviteCodeDialog(code: match.inviteCode ?? ''),
      ).whenComplete(() => _dialogVisible = false);

      _subscription = _service.watchMatch(match.id).listen((updated) {
        if (!mounted) return;
        if (updated.status == MatchStatus.inProgress) {
          _subscription?.cancel();
          _subscription = null;
          _waitingMatch = null;
          if (_dialogVisible) Navigator.of(context).pop();
          _launchGame(updated);
        } else if (updated.status == MatchStatus.cancelled ||
            updated.status == MatchStatus.completed) {
          _subscription?.cancel();
          _subscription = null;
          _waitingMatch = null;
          if (_dialogVisible) Navigator.of(context).pop();
        }
      });
    } on FirebaseNotConfiguredException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(_friendlyError(e, 'Could not create game'));
    }
  }

  Future<void> _joinWithCode() async {
    setState(() => _isJoining = true);
    try {
      final playerId = await _ensurePlayer();
      final match = await _service.joinByInviteCode(
        playerId: playerId,
        code: _inviteCode,
      );
      if (!mounted) return;
      setState(() => _isJoining = false);
      if (match != null) {
        _launchGame(match);
      } else {
        _showError('Invalid or full game. Check the code and try again.');
      }
    } on FirebaseNotConfiguredException catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      _showError(_friendlyError(e, 'Could not join game'));
    }
  }



  // ================= SHARED UI =================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.charcoal,
      ),
    );
  }

  Widget _buildTimerSelection() {
    const timers = [
      GameTimer.five,
      GameTimer.ten,
      GameTimer.fifteen,
      GameTimer.thirty,
      GameTimer.sixty,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: timers.map((timer) {
        final isSelected = _selectedTimer == timer;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimer = timer),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.terracotta : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.terracotta : AppTheme.sandalwood,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.terracotta.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: isSelected ? Colors.white : AppTheme.charcoal,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  timer.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.charcoal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLevelSelection() {
    return Row(
      children: BoardLevel.values.map((level) {
        final isSelected = _selectedLevel == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedLevel = level),
            child: Container(
              margin: EdgeInsets.only(
                right: level != BoardLevel.traditional ? 10 : 0,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.forestGreen.withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.forestGreen
                      : AppTheme.sandalwood,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    level == BoardLevel.pyramid
                        ? '🔺'
                        : level == BoardLevel.square
                            ? '⬛'
                            : '✦',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    level.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.forestGreen
                          : AppTheme.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoleSelection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _playAsTiger = true),
            child: _RoleCard(
              emoji: '🐯',
              label: 'Tigers',
              description: 'Hunt the goats',
              isSelected: _playAsTiger,
              color: AppTheme.terracotta,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _playAsTiger = false),
            child: _RoleCard(
              emoji: '🐐',
              label: 'Goats',
              description: 'Trap the tigers',
              isSelected: !_playAsTiger,
              color: AppTheme.forestGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final bool isSelected;
  final Color color;

  const _RoleCard({
    required this.emoji,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : AppTheme.sandalwood,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? color : AppTheme.charcoal,
            ),
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? color.withValues(alpha: 0.8)
                  : AppTheme.charcoal.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Waiting dialog shown to the host of a private game. Auto-dismisses (and the
/// game starts) when the friend joins via the code.
class _InviteCodeDialog extends StatelessWidget {
  final String code;

  const _InviteCodeDialog({required this.code});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Invite Friend',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Share this code with your friend:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.peacockBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.peacockBlue),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: AppTheme.peacockBlue,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppTheme.peacockBlue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Waiting for opponent...',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
