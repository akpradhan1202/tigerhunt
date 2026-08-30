import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/game_models.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  final bool isVsAI;

  const GameSetupScreen({
    super.key,
    this.isVsAI = true,
  });

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  BoardLevel _selectedBoard = BoardLevel.traditional;
  GameTimer _selectedTimer = GameTimer.ten;
  AIDifficulty _selectedDifficulty = AIDifficulty.medium;
  PieceType _selectedRole = PieceType.goat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkerBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/play'),
        ),
        title: Text(
          widget.isVsAI ? 'Play vs AI' : 'Game Setup',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Board Type Selection
              _buildSectionTitle('Choose Board'),
              const SizedBox(height: 12),
              _buildBoardSelector(),

              const SizedBox(height: 28),

              // Time Selection
              _buildSectionTitle('Time Control'),
              const SizedBox(height: 12),
              _buildTimeSelector(),

              if (widget.isVsAI) ...[
                const SizedBox(height: 28),

                // Difficulty Selection
                _buildSectionTitle('AI Difficulty'),
                const SizedBox(height: 12),
                _buildDifficultySelector(),

                const SizedBox(height: 28),

                // Role Selection
                _buildSectionTitle('Play As'),
                const SizedBox(height: 12),
                _buildRoleSelector(),
              ],

              const SizedBox(height: 40),

              // Start Game Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.greenAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Game',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBoardSelector() {
    return Row(
      children: BoardLevel.values.map((board) {
        final isSelected = _selectedBoard == board;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedBoard = board),
            child: Container(
              margin: EdgeInsets.only(
                right: board != BoardLevel.values.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.greenAccent : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.greenAccent : Colors.white12,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    board == BoardLevel.pyramid
                        ? '🔺'
                        : board == BoardLevel.square
                            ? '⬛'
                            : '✦',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    board.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  Widget _buildTimeSelector() {
    final timeOptions = [
      GameTimer.five,
      GameTimer.ten,
      GameTimer.fifteen,
      GameTimer.unlimited,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: timeOptions.map((timer) {
        final isSelected = _selectedTimer == timer;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimer = timer),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.greenAccent : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppTheme.greenAccent : Colors.white12,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  timer == GameTimer.unlimited ? Icons.all_inclusive : Icons.timer,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  timer.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      children: AIDifficulty.values.map((difficulty) {
        final isSelected = _selectedDifficulty == difficulty;
        return GestureDetector(
          onTap: () => setState(() => _selectedDifficulty = difficulty),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.greenAccent.withValues(alpha: 0.15) : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.greenAccent : Colors.white12,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.greenAccent : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.greenAccent : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        difficulty.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        difficulty.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Difficulty indicator
                Row(
                  children: List.generate(4, (index) {
                    final filled = index < difficulty.depth;
                    return Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 8,
                      height: 20,
                      decoration: BoxDecoration(
                        color: filled
                            ? AppTheme.greenAccent
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildRoleCard(
            PieceType.goat,
            '🐐',
            'Goats',
            'Place 20 goats, trap tigers',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRoleCard(
            PieceType.tiger,
            '🐯',
            'Tigers',
            'Capture 5 goats to win',
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(PieceType role, String emoji, String name, String desc) {
    final isSelected = _selectedRole == role;
    final color = role == PieceType.goat ? AppTheme.greenAccent : AppTheme.tigerOrange;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    context.go('/game', extra: {
      'level': _selectedBoard,
      'mode': GameMode.offline,
      'timer': _selectedTimer,
      'aiDifficulty': widget.isVsAI ? _selectedDifficulty : null,
      'playerRole': widget.isVsAI ? _selectedRole : null,
    });
  }
}
