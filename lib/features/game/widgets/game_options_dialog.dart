import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

/// Time control options for the game
enum TimeControl {
  none('No Limit', null, Icons.all_inclusive),
  blitz1('1 min', Duration(minutes: 1), Icons.flash_on),
  blitz3('3 min', Duration(minutes: 3), Icons.bolt),
  rapid5('5 min', Duration(minutes: 5), Icons.timer),
  rapid10('10 min', Duration(minutes: 10), Icons.timer_outlined),
  classical15('15 min', Duration(minutes: 15), Icons.schedule);

  final String label;
  final Duration? duration;
  final IconData icon;

  const TimeControl(this.label, this.duration, this.icon);
}

/// Board theme options
enum BoardTheme {
  classic('Classic', Color(0xFFF5E6D3), Color(0xFF8B4513)),
  forest('Forest', Color(0xFFE8F5E9), Color(0xFF2E7D32)),
  ocean('Ocean', Color(0xFFE3F2FD), Color(0xFF1565C0)),
  desert('Desert', Color(0xFFFFF8E1), Color(0xFFFF8F00)),
  night('Night', Color(0xFF263238), Color(0xFF37474F)),
  royal('Royal', Color(0xFFF3E5F5), Color(0xFF6A1B9A));

  final String label;
  final Color lightColor;
  final Color darkColor;

  const BoardTheme(this.label, this.lightColor, this.darkColor);
}

/// Game options selected by the player
class GameOptions {
  final TimeControl timeControl;
  final BoardTheme boardTheme;
  final bool playAsGoats; // true = goats, false = tigers
  final String opponentType; // 'ai', 'local', 'online'
  final int aiDifficulty; // 1-5

  const GameOptions({
    this.timeControl = TimeControl.none,
    this.boardTheme = BoardTheme.classic,
    this.playAsGoats = true,
    this.opponentType = 'ai',
    this.aiDifficulty = 3,
  });

  GameOptions copyWith({
    TimeControl? timeControl,
    BoardTheme? boardTheme,
    bool? playAsGoats,
    String? opponentType,
    int? aiDifficulty,
  }) {
    return GameOptions(
      timeControl: timeControl ?? this.timeControl,
      boardTheme: boardTheme ?? this.boardTheme,
      playAsGoats: playAsGoats ?? this.playAsGoats,
      opponentType: opponentType ?? this.opponentType,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
    );
  }
}

/// Provider for game options
final gameOptionsProvider = StateProvider<GameOptions>((ref) {
  return const GameOptions();
});

/// Dialog to select game options before starting
class GameOptionsDialog extends ConsumerStatefulWidget {
  final String opponentType;

  const GameOptionsDialog({
    super.key,
    required this.opponentType,
  });

  static Future<GameOptions?> show(
    BuildContext context, {
    required String opponentType,
  }) {
    return showModalBottomSheet<GameOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GameOptionsDialog(opponentType: opponentType),
    );
  }

  @override
  ConsumerState<GameOptionsDialog> createState() => _GameOptionsDialogState();
}

class _GameOptionsDialogState extends ConsumerState<GameOptionsDialog> {
  late TimeControl _selectedTime;
  late BoardTheme _selectedBoard;
  late bool _playAsGoats;
  late int _aiDifficulty;

  @override
  void initState() {
    super.initState();
    final currentOptions = ref.read(gameOptionsProvider);
    _selectedTime = currentOptions.timeControl;
    _selectedBoard = currentOptions.boardTheme;
    _playAsGoats = currentOptions.playAsGoats;
    _aiDifficulty = currentOptions.aiDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.settings, color: AppTheme.tigerOrange),
                const SizedBox(width: 12),
                const Text(
                  'Game Options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Control Section
                  _buildSectionTitle('Time Control', Icons.timer),
                  const SizedBox(height: 12),
                  _buildTimeControlGrid(),

                  const SizedBox(height: 28),

                  // Board Theme Section
                  _buildSectionTitle('Board Theme', Icons.palette),
                  const SizedBox(height: 12),
                  _buildBoardThemeGrid(),

                  const SizedBox(height: 28),

                  // Play As Section
                  _buildSectionTitle('Play As', Icons.swap_horiz),
                  const SizedBox(height: 12),
                  _buildPlayAsSelector(),

                  // AI Difficulty (only for AI opponent)
                  if (widget.opponentType == 'ai') ...[
                    const SizedBox(height: 28),
                    _buildSectionTitle('AI Difficulty', Icons.psychology),
                    const SizedBox(height: 12),
                    _buildDifficultySlider(),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Start Game Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.tigerOrange, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeControlGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: TimeControl.values.length,
      itemBuilder: (context, index) {
        final time = TimeControl.values[index];
        final isSelected = _selectedTime == time;

        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.tigerOrange.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.tigerOrange
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  time.icon,
                  color: isSelected ? AppTheme.tigerOrange : Colors.white70,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  time.label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.tigerOrange : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoardThemeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: BoardTheme.values.length,
      itemBuilder: (context, index) {
        final theme = BoardTheme.values[index];
        final isSelected = _selectedBoard == theme;

        return GestureDetector(
          onTap: () => setState(() => _selectedBoard = theme),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.tigerOrange
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [theme.lightColor, theme.darkColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                          )
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    theme.label,
                    style: TextStyle(
                      color: isSelected ? AppTheme.tigerOrange : Colors.white70,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayAsSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _playAsGoats = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _playAsGoats
                    ? AppTheme.greenAccent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _playAsGoats
                      ? AppTheme.greenAccent
                      : Colors.white.withValues(alpha: 0.1),
                  width: _playAsGoats ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  const Text('🐐', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    'Goats',
                    style: TextStyle(
                      color: _playAsGoats
                          ? AppTheme.greenAccent
                          : Colors.white70,
                      fontWeight:
                          _playAsGoats ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    '20 pieces',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _playAsGoats = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: !_playAsGoats
                    ? AppTheme.tigerOrange.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_playAsGoats
                      ? AppTheme.tigerOrange
                      : Colors.white.withValues(alpha: 0.1),
                  width: !_playAsGoats ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  const Text('🐯', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    'Tigers',
                    style: TextStyle(
                      color: !_playAsGoats
                          ? AppTheme.tigerOrange
                          : Colors.white70,
                      fontWeight:
                          !_playAsGoats ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    '4 pieces',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySlider() {
    final difficultyLabels = ['Easy', 'Normal', 'Hard', 'Expert', 'Master'];
    final difficultyColors = [
      Colors.green,
      Colors.lightGreen,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
    ];

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: difficultyColors[_aiDifficulty - 1],
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            thumbColor: difficultyColors[_aiDifficulty - 1],
            overlayColor:
                difficultyColors[_aiDifficulty - 1].withValues(alpha: 0.2),
            valueIndicatorColor: difficultyColors[_aiDifficulty - 1],
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
          ),
          child: Slider(
            value: _aiDifficulty.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: difficultyLabels[_aiDifficulty - 1],
            onChanged: (value) {
              setState(() => _aiDifficulty = value.round());
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: difficultyLabels.asMap().entries.map((entry) {
            final isSelected = entry.key == _aiDifficulty - 1;
            return Text(
              entry.value,
              style: TextStyle(
                color: isSelected
                    ? difficultyColors[entry.key]
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _startGame() {
    final options = GameOptions(
      timeControl: _selectedTime,
      boardTheme: _selectedBoard,
      playAsGoats: _playAsGoats,
      opponentType: widget.opponentType,
      aiDifficulty: _aiDifficulty,
    );

    // Save options for next time
    ref.read(gameOptionsProvider.notifier).state = options;

    Navigator.pop(context, options);
  }
}
