import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../game/models/game_models.dart';

/// Animated hand pointer for tutorial
class TutorialHand extends StatelessWidget {
  final Animation<double> animation;
  final Position targetPosition;
  final BoardLevel boardLevel;

  const TutorialHand({
    super.key,
    required this.animation,
    required this.targetPosition,
    required this.boardLevel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        final cellSize = boardSize / (boardLevel.cols - 1);

        final x = targetPosition.col * cellSize;
        final y = targetPosition.row * cellSize;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            // Bounce animation
            final bounceOffset = animation.value * 10;

            return Positioned(
              left: x + 10,
              top: y + 10 + bounceOffset,
              child: Transform.rotate(
                angle: -0.5, // Slight rotation for natural look
                child: const Icon(
                  Icons.touch_app,
                  size: 48,
                  color: AppTheme.terracotta,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Custom animated builder widget
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
