import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';

/// Chat message bubble
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _buildSystemMessage();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.forestGreen.withOpacity(0.2),
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forestGreen,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: message.isQuickChat ? 12 : 14,
                vertical: message.isQuickChat ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.terracotta
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isQuickChat)
                    Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 16,
                        color: isMe ? Colors.white : AppTheme.charcoal,
                      ),
                    )
                  else
                    Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : AppTheme.charcoal,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.charcoal.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.sandalwood.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.message,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.charcoal.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
