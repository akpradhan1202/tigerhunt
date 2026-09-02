import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/multiplayer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../game/models/game_models.dart';
import '../../friends/models/friend.dart';
import '../../friends/services/friends_service.dart';

class OnlinePlayScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const OnlinePlayScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<OnlinePlayScreen> createState() => _OnlinePlayScreenState();
}

class _OnlinePlayScreenState extends ConsumerState<OnlinePlayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  BoardLevel _selectedLevel = BoardLevel.square;
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
  Timer? _searchTicker;
  int _searchSeconds = 0;
  int _onlineCount = 1;
  bool _dialogVisible = false;
  final TextEditingController _friendEmailController = TextEditingController();
  final TextEditingController _searchFriendController = TextEditingController();

  bool _isGuest = false;
  late final FriendsService _friendsService;
  List<Friend> _searchResults = [];
  bool _isSearchingFriends = false;
  List<Friend> _friendsList = [];
  bool _isLoadingFriends = false;

  late final MultiplayerService _service;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authServiceProvider);
    _isGuest = auth.user?.isGuest ?? true;
    _tabController = TabController(
      length: _isGuest ? 1 : 2,
      vsync: this,
      initialIndex: _isGuest ? 0 : widget.initialTab.clamp(0, 1),
    );
    _service = ref.read(multiplayerServiceProvider);
    _friendsService = ref.read(friendsServiceProvider);
    _connectPresence();
    if (!_isGuest) {
      _loadFriends();
    }
  }

  /// Connect to Firebase and start the presence heartbeat + online counter.
  Future<void> _connectPresence() async {
    try {
      final playerId = await _ensurePlayer();
      if (!mounted) return;
      setState(() => _playerId = playerId);
      final auth = ref.read(authServiceProvider);
      final displayName = auth.user?.displayName;
      final email = auth.user?.email;
      await _service.heartbeatPresence(playerId, displayName: displayName, email: email);
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        _service.heartbeatPresence(playerId, displayName: displayName, email: email);
      });
      _onlineCountSub = _service.watchOnlineCount().listen((count) {
        if (mounted) setState(() => _onlineCount = count);
      });
    } catch (_) {
      // Online count is best-effort; the screen still works without it.
    }
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoadingFriends = true);
    final auth = ref.read(authServiceProvider);
    final uid = auth.user?.id ?? '';
    final friends = await _friendsService.getFriends(uid);
    if (mounted) {
      setState(() {
        _friendsList = friends;
        _isLoadingFriends = false;
      });
    }
  }

  Future<void> _onSearchFriends(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearchingFriends = true);
    final results = await _friendsService.searchUsers(
      q,
      currentUserId: _playerId,
    );
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearchingFriends = false;
      });
    }
  }

  Future<void> _onAddFriend(Friend friend) async {
    final auth = ref.read(authServiceProvider);
    final uid = auth.user?.id ?? '';
    final updated = await _friendsService.addFriend(uid, friend);
    if (mounted) {
      setState(() {
        _friendsList = updated;
        _searchResults.removeWhere((r) => r.id == friend.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${friend.displayName} to friends!')),
      );
    }
  }

  Future<void> _onRemoveFriend(String friendId, String name) async {
    final auth = ref.read(authServiceProvider);
    final uid = auth.user?.id ?? '';
    final updated = await _friendsService.removeFriend(uid, friendId);
    if (mounted) {
      setState(() => _friendsList = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed $name from friends.')),
      );
    }
  }

  @override
  void dispose() {
    _friendEmailController.dispose();
    _searchFriendController.dispose();
    _subscription?.cancel();
    _onlineCountSub?.cancel();
    _heartbeatTimer?.cancel();
    _searchTicker?.cancel();
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
        bottom: _isGuest
            ? null
            : TabBar(
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
      body: _isGuest
          ? _buildFindMatchTab()
          : TabBarView(
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
                : 'Looking for a player ($_searchSeconds\s elapsed)...',
            style: TextStyle(
              color: AppTheme.charcoal.withValues(alpha: 0.6),
            ),
          ),
          if (_searchSeconds >= 6) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                _cancelSearch();
                context.go('/game', extra: {
                  'level': _selectedLevel,
                  'mode': GameMode.offline,
                  'timer': _selectedTimer,
                  'aiDifficulty': AIDifficulty.medium,
                  'playerRole': _playAsTiger ? PieceType.tiger : PieceType.goat,
                });
              },
              icon: const Icon(Icons.smart_toy, size: 16),
              label: Text(
                _playAsTiger ? 'Match with Goat Bot 🐐' : 'Match with Tiger Bot 🐯',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.forestGreen,
                side: const BorderSide(color: AppTheme.forestGreen),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: _cancelSearch,
            child: const Text('Cancel Search'),
          ),
        ],
      ),
    );
  }



  Future<void> _startSearching() async {
    _searchTicker?.cancel();
    _searchSeconds = 0;
    _searchTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isSearching) {
        setState(() => _searchSeconds++);
      }
    });
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
        _searchTicker?.cancel();
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
          _searchTicker?.cancel();
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
          _searchTicker?.cancel();
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
      _searchTicker?.cancel();
      setState(() => _isSearching = false);
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _searchTicker?.cancel();
      setState(() => _isSearching = false);
      _showError(_friendlyError(e, 'Could not find a match'));
    }
  }

  void _cancelSearch() {
    _searchTicker?.cancel();
    _searchSeconds = 0;
    _subscription?.cancel();
    _subscription = null;
    _cancelWaitingMatch();
    setState(() => _isSearching = false);
  }

  // ================= PLAY WITH FRIEND (CHESS.COM STYLE) =================

  Widget _buildPlayWithFriendTab() {
    return StreamBuilder<List<OnlinePlayer>>(
      stream: _service.watchOnlinePlayers(currentUserId: _playerId),
      builder: (context, snapshot) {
        final onlinePlayers = snapshot.data ?? [];
        final onlineIds = onlinePlayers.map((p) => p.id).toSet();
        final onlineEmails = onlinePlayers.map((p) => p.email.toLowerCase()).toSet();

        final friendsWithStatus = _friendsList.map((f) {
          final isOnline = onlineIds.contains(f.id) ||
              (f.email.isNotEmpty && onlineEmails.contains(f.email.toLowerCase()));
          return f.copyWith(isOnline: isOnline);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Find Friend
              _buildSectionTitle('Find Friends 🔍'),
              const SizedBox(height: 10),
              _buildFindFriendCard(onlinePlayers),

              const SizedBox(height: 28),

              // 2. List of Added Friends
              _buildSectionTitle('Added Friends (${friendsWithStatus.length}) 👥'),
              const SizedBox(height: 10),
              _buildAddedFriendsCard(friendsWithStatus),

              const SizedBox(height: 28),

              // 3. Custom Challenge & Invite
              _buildSectionTitle('Custom Challenge / Invite ✉️'),
              const SizedBox(height: 10),
              _buildCustomChallengeCard(),

              const SizedBox(height: 24),
              _buildSectionTitle('Join Game with Code'),
              const SizedBox(height: 10),
              _buildJoinGameCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFindFriendCard(List<OnlinePlayer> onlinePlayers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sandalwood),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchFriendController,
            decoration: InputDecoration(
              hintText: 'Search by username or email...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.peacockBlue),
              suffixIcon: _searchFriendController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchFriendController.clear();
                        _onSearchFriends('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.sandalwood),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchFriends,
            onSubmitted: _onSearchFriends,
          ),
          if (_isSearchingFriends) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ] else if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Search Results',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
            ),
            const SizedBox(height: 8),
            for (final user in _searchResults)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.parchment,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.tigerOrange,
                      child: Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '🐯',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          if (user.email.isNotEmpty)
                            Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _onAddFriend(user),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppTheme.peacockBlue,
                        side: const BorderSide(color: AppTheme.peacockBlue),
                      ),
                      child: const Text('Add Friend', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () => _createEmailGame(user.email.isNotEmpty ? user.email : user.displayName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greenAccent,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Play ⚔️', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              ),
          ] else if (onlinePlayers.isNotEmpty && _searchFriendController.text.isEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('Players Online Now', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.charcoal)),
              ],
            ),
            const SizedBox(height: 8),
            for (final p in onlinePlayers.take(4))
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.parchment.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.tigerOrange.withValues(alpha: 0.2),
                      child: Text(
                        p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '🐯',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.tigerOrange, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    OutlinedButton(
                      onPressed: () => _onAddFriend(Friend(
                        id: p.id,
                        displayName: p.displayName,
                        email: p.email,
                        addedAt: DateTime.now(),
                      )),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        side: const BorderSide(color: AppTheme.peacockBlue),
                      ),
                      child: const Text('Add Friend', style: TextStyle(fontSize: 11, color: AppTheme.peacockBlue)),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () => _createEmailGame(p.email.isNotEmpty ? p.email : p.displayName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greenAccent,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: const Text('Play ⚔️', style: TextStyle(fontSize: 11, color: Colors.white)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddedFriendsCard(List<Friend> friends) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sandalwood),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingFriends)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (friends.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'No friends added yet',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find friends above to challenge them anytime!',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final f in friends)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.parchment.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.sandalwood.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.tigerOrange,
                          child: Text(
                            f.displayName.isNotEmpty ? f.displayName[0].toUpperCase() : '🐯',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: f.isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Row(
                            children: [
                              Text(
                                f.isOnline ? 'Online now' : 'Offline',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: f.isOnline ? Colors.green.shade700 : Colors.grey.shade500,
                                  fontWeight: f.isOnline ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (f.email.isNotEmpty) ...[
                                const Text(' • ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Expanded(
                                  child: Text(
                                    f.email,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _createEmailGame(f.email.isNotEmpty ? f.email : f.displayName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.peacockBlue,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Play ⚔️', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                      tooltip: 'Remove friend',
                      onPressed: () => _onRemoveFriend(f.id, f.displayName),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCustomChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sandalwood),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Board Level Selector
          const Text('Board Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
          const SizedBox(height: 8),
          SegmentedButton<BoardLevel>(
            segments: const [
              ButtonSegment(value: BoardLevel.square, label: Text('Square (Default)')),
              ButtonSegment(value: BoardLevel.traditional, label: Text('Traditional')),
              ButtonSegment(value: BoardLevel.pyramid, label: Text('Pyramid')),
            ],
            selected: {_selectedLevel},
            onSelectionChanged: (set) => setState(() => _selectedLevel = set.first),
          ),
          const SizedBox(height: 16),

          // Timer Selector
          const Text('Time Control', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              GameTimer.bullet,
              GameTimer.blitz,
              GameTimer.five,
              GameTimer.ten,
              GameTimer.unlimited,
            ]
                .map((GameTimer t) => ChoiceChip(
                      label: Text(t.label),
                      selected: _selectedTimer == t,
                      selectedColor: AppTheme.peacockBlue.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _selectedTimer = t),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Play as Tiger or Goat
          const Text('Play As', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Tigers 🐯'),
                  selected: _playAsTiger,
                  selectedColor: AppTheme.tigerOrange.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _playAsTiger = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Goats 🐐'),
                  selected: !_playAsTiger,
                  selectedColor: AppTheme.greenAccent.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _playAsTiger = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Divider(color: Colors.black12),
          const SizedBox(height: 12),

          // Direct Email Challenge
          const Text('Direct Challenge by Email:', style: TextStyle(fontSize: 12, color: AppTheme.charcoal)),
          const SizedBox(height: 8),
          TextField(
            controller: _friendEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'friend@example.com',
              prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.peacockBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.sandalwood),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              label: const Text('Send Challenge & Wait', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: () => _createEmailGame(_friendEmailController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.peacockBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share, size: 18, color: AppTheme.peacockBlue),
              label: const Text('Generate Shareable Code', style: TextStyle(color: AppTheme.peacockBlue, fontWeight: FontWeight.bold)),
              onPressed: _createPrivateGame,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppTheme.peacockBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createEmailGame(String targetEmail) async {
    final email = targetEmail.trim();
    if (email.isEmpty) {
      _showError('Please enter an email address or player name.');
      return;
    }
    try {
      final playerId = await _ensurePlayer();
      final match = await _service.createEmailChallenge(
        playerId: playerId,
        targetEmail: email,
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
        builder: (context) => _InviteCodeDialog(
          code: match.inviteCode ?? '',
          title: 'Challenge for $email',
          subtitle: 'Waiting for friend to accept. Or share code:',
        ),
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
      _showError(_friendlyError(e, 'Could not create challenge'));
    }
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
  final String title;
  final String subtitle;

  const _InviteCodeDialog({
    required this.code,
    this.title = 'Invite Friend',
    this.subtitle = 'Share this code with your friend:',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            subtitle,
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
