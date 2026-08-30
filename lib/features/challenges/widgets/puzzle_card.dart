import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../game/models/game_models.dart';
import '../models/challenge_models.dart';

/// Card displaying a puzzle
class PuzzleCard extends StatelessWidget {
  final Puzzle puzzle;
  final VoidCallback onTap;
  final bool isCompleted;

  const PuzzleCard({
    super.key,
    required this.puzzle,
    required this.onTap,
    this.isCompleted = false,
  });

  Color get _difficultyColor {
    switch (puzzle.difficulty) {
      case ChallengeDifficulty.easy:
        return AppTheme.forestGreen;
      case ChallengeDifficulty.medium:
        return AppTheme.turmeric;
      case ChallengeDifficulty.hard:
        return AppTheme.terracotta;
      case ChallengeDifficulty.expert:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppTheme.forestGreen.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppTheme.forestGreen
                : AppTheme.sandalwood.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Puzzle preview thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.boardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.henna.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Simple board representation
                  CustomPaint(
                    size: const Size(64, 64),
                    painter: _MiniBoardPainter(),
                  ),
                  // Piece indicators
                  if (puzzle.playerRole == PieceType.tiger)
                    const Center(
                      child: Text('🐯', style: TextStyle(fontSize: 24)),
                    )
                  else
                    const Center(
                      child: Text('🐐', style: TextStyle(fontSize: 24)),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          puzzle.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.forestGreen,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    puzzle.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.charcoal.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _difficultyColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          puzzle.difficulty.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _difficultyColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rating: ${puzzle.rating}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.charcoal.withValues(alpha: 0.5),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${puzzle.solutionLength} move${puzzle.solutionLength > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.peacockBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Play button
            Icon(
              Icons.play_circle_fill,
              color: _difficultyColor,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.boardLine.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Draw simple grid
    for (int i = 0; i < 5; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(4, y + 4), Offset(size.width - 4, y + 4), paint);
    }
    for (int i = 0; i < 5; i++) {
      final x = (i / 4) * size.width;
      canvas.drawLine(Offset(x + 4, 4), Offset(x + 4, size.height - 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
