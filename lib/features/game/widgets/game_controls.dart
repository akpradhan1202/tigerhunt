import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Game control buttons (resign, draw, etc.)
class GameControls extends StatelessWidget {
  final VoidCallback onResign;
  final VoidCallback onOfferDraw;
  final VoidCallback? onUndo;

  const GameControls({
    super.key,
    required this.onResign,
    required this.onOfferDraw,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: Icons.flag_outlined,
            label: 'Resign',
            color: Colors.red,
            onTap: onResign,
          ),
          _ControlButton(
            icon: Icons.handshake_outlined,
            label: 'Draw',
            color: AppTheme.charcoal,
            onTap: onOfferDraw,
          ),
          _ControlButton(
            icon: Icons.undo,
            label: 'Undo',
            color: AppTheme.peacockBlue,
            onTap: onUndo,
            enabled: onUndo != null,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : color.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
