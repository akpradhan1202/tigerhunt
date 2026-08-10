import 'package:equatable/equatable.dart';

/// Chat message model
class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isQuickChat;
  final bool isSystem;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isQuickChat = false,
    this.isSystem = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'isQuickChat': isQuickChat,
        'isSystem': isSystem,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isQuickChat: json['isQuickChat'] as bool? ?? false,
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }

  factory ChatMessage.system(String message) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      senderName: 'System',
      message: message,
      timestamp: DateTime.now(),
      isSystem: true,
    );
  }

  @override
  List<Object?> get props => [id, senderId, message, timestamp];
}

/// Quick chat presets
class QuickChatMessages {
  static const List<QuickChatOption> greetings = [
    QuickChatOption('👋', 'Hi!'),
    QuickChatOption('🙏', 'Namaste!'),
    QuickChatOption('😊', 'Good luck!'),
    QuickChatOption('🤝', 'Good game!'),
  ];

  static const List<QuickChatOption> reactions = [
    QuickChatOption('👏', 'Nice move!'),
    QuickChatOption('😮', 'Wow!'),
    QuickChatOption('🤔', 'Interesting...'),
    QuickChatOption('😅', 'Oops!'),
  ];

  static const List<QuickChatOption> gamePlay = [
    QuickChatOption('⏰', 'Take your time'),
    QuickChatOption('🎯', 'Well played!'),
    QuickChatOption('🔥', 'On fire!'),
    QuickChatOption('💪', 'Let\'s go!'),
  ];

  static const List<QuickChatOption> endings = [
    QuickChatOption('🏆', 'GG!'),
    QuickChatOption('🎉', 'Great game!'),
    QuickChatOption('🔄', 'Rematch?'),
    QuickChatOption('👋', 'Bye!'),
  ];

  static List<QuickChatOption> get all => [
        ...greetings,
        ...reactions,
        ...gamePlay,
        ...endings,
      ];
}

class QuickChatOption {
  final String emoji;
  final String message;

  const QuickChatOption(this.emoji, this.message);

  String get fullMessage => '$emoji $message';
}
