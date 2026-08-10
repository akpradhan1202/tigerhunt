import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          'Play Online',
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

  Widget _buildFindMatchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time control selection
          _buildSectionTitle('Time Control'),
          const SizedBox(height: 12),
          _buildTimerSelection(),

          const SizedBox(height: 24),

          // Board level selection
          _buildSectionTitle('Board Level'),
          const SizedBox(height: 12),
          _buildLevelSelection(),

          const SizedBox(height: 24),

          // Play as selection
          _buildSectionTitle('Play As'),
          const SizedBox(height: 12),
          _buildRoleSelection(),

          const SizedBox(height: 32),

          // Find match button
          _isSearching ? _buildSearchingState() : _buildFindMatchButton(),
        ],
      ),
    );
  }

  Widget _buildPlayWithFriendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create game section
          _buildSectionTitle('Create Game'),
          const SizedBox(height: 12),
          _buildCreateGameCard(),

          const SizedBox(height: 32),

          // Join game section
          _buildSectionTitle('Join Game'),
          const SizedBox(height: 12),
          _buildJoinGameCard(),
        ],
      ),
    );
  }

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
    final timers = [
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
                color: isSelected
                    ? AppTheme.terracotta
                    : AppTheme.sandalwood,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.terracotta.withOpacity(0.3),
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
                    ? AppTheme.forestGreen.withOpacity(0.15)
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.terracotta.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.terracotta.withOpacity(0.3)),
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
          const Text(
            'Finding opponent...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(
              color: AppTheme.charcoal.withOpacity(0.6),
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
          const Icon(
            Icons.share,
            size: 48,
            color: AppTheme.peacockBlue,
          ),
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
                borderSide: const BorderSide(color: AppTheme.forestGreen, width: 2),
              ),
            ),
            onChanged: (value) => _inviteCode = value.toUpperCase(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _inviteCode.length == 6 ? _joinWithCode : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
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

  void _startSearching() {
    setState(() => _isSearching = true);
    // TODO: Implement match finding logic
  }

  void _cancelSearch() {
    setState(() => _isSearching = false);
  }

  void _createPrivateGame() {
    // TODO: Create private game and show invite code
    showDialog(
      context: context,
      builder: (context) => _InviteCodeDialog(code: 'ABC123'),
    );
  }

  void _joinWithCode() {
    // TODO: Join game with invite code
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
        color: isSelected ? color.withOpacity(0.15) : Colors.white,
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
                  ? color.withOpacity(0.8)
                  : AppTheme.charcoal.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

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
              color: AppTheme.peacockBlue.withOpacity(0.1),
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
