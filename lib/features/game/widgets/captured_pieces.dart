import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/game_models.dart';

/// Displays captured pieces
class CapturedPieces extends StatelessWidget {
  final int count;
  final PieceType pieceType;

  const CapturedPieces({
    super.key,
    required this.count,
    required this.pieceType,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = pieceType == PieceType.tiger ? '🐯' : '🐐';
    final color = pieceType == PieceType.tiger
        ? AppTheme.terracotta
        : AppTheme.forestGreen;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Captured: ',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          ...List.generate(
            count,
            (index) => Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
