import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/game_record.dart';
import '../../game/models/game_models.dart';
import '../widgets/game_history_card.dart';

class GameHistoryScreen extends ConsumerWidget {
  const GameHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get actual game history from provider
    final games = _getMockHistory();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        title: const Text(
          'Game History',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            color: AppTheme.charcoal,
          ),
        ],
      ),
      body: games.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return GameHistoryCard(
                  record: game,
                  currentUserId: 'user_123', // TODO: Get actual user ID
                  onTap: () => _openReplay(context, game),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 80,
            color: AppTheme.sandalwood,
          ),
          const SizedBox(height: 16),
          const Text(
            'No games yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed games will appear here',
            style: TextStyle(
              color: AppTheme.charcoal.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Games',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _FilterChip(label: 'All Games', isSelected: true),
            _FilterChip(label: 'Wins Only', isSelected: false),
            _FilterChip(label: 'Losses Only', isSelected: false),
            _FilterChip(label: 'As Tiger', isSelected: false),
            _FilterChip(label: 'As Goat', isSelected: false),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openReplay(BuildContext context, GameRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameReplayScreen(record: record),
      ),
    );
  }

  List<GameRecord> _getMockHistory() {
    // Mock data for testing
    return [
      GameRecord(
        id: '1',
        playedAt: DateTime.now().subtract(const Duration(hours: 2)),
        level: BoardLevel.traditional,
        mode: GameMode.online,
        timer: GameTimer.ten,
        gameDuration: const Duration(minutes: 8, seconds: 32),
        tigerPlayerId: 'user_123',
        tigerPlayerName: 'You',
        tigerPlayerRating: 1350,
        goatPlayerId: 'opp_1',
        goatPlayerName: 'PlayerOne',
        goatPlayerRating: 1280,
        winner: GameWinner.tigers,
        goatsCaptured: 5,
        totalMoves: 42,
        moves: [],
        tigerRatingChange: 12,
        goatRatingChange: -12,
      ),
      GameRecord(
        id: '2',
        playedAt: DateTime.now().subtract(const Duration(days: 1)),
        level: BoardLevel.traditional,
        mode: GameMode.online,
        timer: GameTimer.fifteen,
        gameDuration: const Duration(minutes: 12, seconds: 45),
        tigerPlayerId: 'opp_2',
        tigerPlayerName: 'MasterPlayer',
        tigerPlayerRating: 1520,
        goatPlayerId: 'user_123',
        goatPlayerName: 'You',
        goatPlayerRating: 1338,
        winner: GameWinner.goats,
        goatsCaptured: 3,
        totalMoves: 58,
        moves: [],
        tigerRatingChange: -15,
        goatRatingChange: 15,
      ),
    ];
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {},
        selectedColor: AppTheme.terracotta.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.terracotta : AppTheme.charcoal,
        ),
      ),
    );
  }
}

/// Game replay screen
class GameReplayScreen extends StatefulWidget {
  final GameRecord record;

  const GameReplayScreen({super.key, required this.record});

  @override
  State<GameReplayScreen> createState() => _GameReplayScreenState();
}

class _GameReplayScreenState extends State<GameReplayScreen> {
  int _currentMoveIndex = 0;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.parchment,
      appBar: AppBar(
        backgroundColor: AppTheme.parchment,
        elevation: 0,
        title: Text(
          'Game Replay',
          style: const TextStyle(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
            color: AppTheme.charcoal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Game info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PlayerInfo(
                  name: widget.record.tigerPlayerName,
                  rating: widget.record.tigerPlayerRating,
                  emoji: '🐯',
                  isWinner: widget.record.winner == GameWinner.tigers,
                ),
                Column(
                  children: [
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    Text(
                      '${widget.record.totalMoves} moves',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.charcoal.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                _PlayerInfo(
                  name: widget.record.goatPlayerName,
                  rating: widget.record.goatPlayerRating,
                  emoji: '🐐',
                  isWinner: widget.record.winner == GameWinner.goats,
                ),
              ],
            ),
          ),

          // Board placeholder
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.boardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.henna, width: 3),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.replay,
                      size: 64,
                      color: AppTheme.sandalwood,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Move $_currentMoveIndex of ${widget.record.totalMoves}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Replay controls
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Progress slider
                Slider(
                  value: _currentMoveIndex.toDouble(),
                  min: 0,
                  max: widget.record.totalMoves.toDouble(),
                  divisions: widget.record.totalMoves,
                  activeColor: AppTheme.terracotta,
                  onChanged: (value) {
                    setState(() {
                      _currentMoveIndex = value.round();
                    });
                  },
                ),

                const SizedBox(height: 8),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () => setState(() => _currentMoveIndex = 0),
                      color: AppTheme.charcoal,
                    ),
                    IconButton(
                      icon: const Icon(Icons.fast_rewind),
                      onPressed: _currentMoveIndex > 0
                          ? () => setState(() => _currentMoveIndex--)
                          : null,
                      color: AppTheme.charcoal,
                    ),
                    FloatingActionButton(
                      onPressed: () => setState(() => _isPlaying = !_isPlaying),
                      backgroundColor: AppTheme.terracotta,
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fast_forward),
                      onPressed: _currentMoveIndex < widget.record.totalMoves
                          ? () => setState(() => _currentMoveIndex++)
                          : null,
                      color: AppTheme.charcoal,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: () => setState(
                          () => _currentMoveIndex = widget.record.totalMoves),
                      color: AppTheme.charcoal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerInfo extends StatelessWidget {
  final String name;
  final int rating;
  final String emoji;
  final bool isWinner;

  const _PlayerInfo({
    required this.name,
    required this.rating,
    required this.emoji,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            if (isWinner)
              const Positioned(
                right: -4,
                top: -4,
                child: Text('👑', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isWinner ? AppTheme.terracotta : AppTheme.charcoal,
          ),
        ),
        Text(
          '$rating',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.charcoal.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
