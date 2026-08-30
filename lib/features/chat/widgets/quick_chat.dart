import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';

/// Quick chat bar with emoji shortcuts
class QuickChatBar extends StatelessWidget {
  final Function(String) onSelect;
  final VoidCallback onToggle;

  const QuickChatBar({
    super.key,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.parchment,
        border: Border(
          top: BorderSide(color: AppTheme.sandalwood.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          // Category tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _QuickChatCategory(
                  label: '👋 Greetings',
                  options: QuickChatMessages.greetings,
                  onSelect: onSelect,
                ),
                _QuickChatCategory(
                  label: '😊 Reactions',
                  options: QuickChatMessages.reactions,
                  onSelect: onSelect,
                ),
                _QuickChatCategory(
                  label: '🎮 Game',
                  options: QuickChatMessages.gamePlay,
                  onSelect: onSelect,
                ),
                _QuickChatCategory(
                  label: '🏆 End',
                  options: QuickChatMessages.endings,
                  onSelect: onSelect,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChatCategory extends StatefulWidget {
  final String label;
  final List<QuickChatOption> options;
  final Function(String) onSelect;

  const _QuickChatCategory({
    required this.label,
    required this.options,
    required this.onSelect,
  });

  @override
  State<_QuickChatCategory> createState() => _QuickChatCategoryState();
}

class _QuickChatCategoryState extends State<_QuickChatCategory> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _expanded
                    ? AppTheme.terracotta.withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _expanded
                      ? AppTheme.terracotta
                      : AppTheme.sandalwood.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _expanded
                          ? AppTheme.terracotta
                          : AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: _expanded
                        ? AppTheme.terracotta
                        : AppTheme.charcoal.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.options.map((option) {
                  return GestureDetector(
                    onTap: () {
                      widget.onSelect(option.fullMessage);
                      setState(() => _expanded = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.sandalwood.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        option.fullMessage,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Floating quick chat button for in-game use
class QuickChatButton extends StatelessWidget {
  final VoidCallback onTap;
  final int unreadCount;

  const QuickChatButton({
    super.key,
    required this.onTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.terracotta,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.terracotta.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
