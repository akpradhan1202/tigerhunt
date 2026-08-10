import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/challenge_models.dart';

/// Card displaying a challenge
class ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final ChallengeDifficulty difficulty;
  final int reward;
  final int progress;
  final int target;
  final bool isCompleted;
  final bool isWeekly;
  final VoidCallback onTap;

  const ChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.reward,
    required this.progress,
    required this.target,
    required this.isCompleted,
    this.isWeekly = false,
    required this.onTap,
  });

  Color get _difficultyColor {
    switch (difficulty) {
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
              ? AppTheme.forestGreen.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppTheme.forestGreen
                : AppTheme.sandalwood.withOpacity(0.3),
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkBrown.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? AppTheme.forestGreen
                          : AppTheme.charcoal,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _difficultyColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    difficulty.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _difficultyColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: TextStyle(
                color: AppTheme.charcoal.withOpacity(0.7),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / target,
                backgroundColor: AppTheme.sandalwood.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppTheme.forestGreen : _difficultyColor,
                ),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 8),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$progress / $target',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.charcoal.withOpacity(0.6),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: AppTheme.turmeric,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+$reward XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.turmeric,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Completed badge
            if (isCompleted) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Completed!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Weekly badge
            if (isWeekly && !isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppTheme.peacockBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Resets in 3 days',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.peacockBlue,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
