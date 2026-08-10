import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Player info bar showing name, timer, and captured pieces
class PlayerInfoBar extends StatelessWidget {
  final String name;
  final String emoji;
  final bool isCurrentTurn;
  final Duration? timeRemaining;
  final int capturedCount;
  final String? capturedEmoji;
  final bool isPlayer;

  const PlayerInfoBar({
    super.key,
    required this.name,
    required this.emoji,
    required this.isCurrentTurn,
    this.timeRemaining,
    this.capturedCount = 0,
    this.capturedEmoji,
    this.isPlayer = false,
  });

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? (isPlayer
                ? AppTheme.forestGreen.withOpacity(0.15)
                : AppTheme.terracotta.withOpacity(0.15))
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn
              ? (isPlayer ? AppTheme.forestGreen : AppTheme.terracotta)
              : AppTheme.sandalwood,
          width: isCurrentTurn ? 2 : 1,
        ),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: (isPlayer
                          ? AppTheme.forestGreen
                          : AppTheme.terracotta)
                      .withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPlayer
                  ? AppTheme.forestGreen.withOpacity(0.2)
                  : AppTheme.terracotta.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),

          const SizedBox(width: 12),

          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.charcoal,
                  ),
                ),
                if (isCurrentTurn)
                  Text(
                    'Your turn',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPlayer
                          ? AppTheme.forestGreen
                          : AppTheme.terracotta,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Captured pieces
          if (capturedCount > 0 && capturedEmoji != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(capturedEmoji!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    'x$capturedCount',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Timer
          if (timeRemaining != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrentTurn
                    ? AppTheme.charcoal
                    : AppTheme.charcoal.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(timeRemaining!),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
