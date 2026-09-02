import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsDialog extends StatelessWidget {
  const NotificationsDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const NotificationsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = [
      (
        icon: Icons.flash_on,
        iconColor: AppTheme.tigerOrange,
        title: '⚡ Fast Move Bonus Active',
        desc: 'Play your turn within 3 seconds to earn a +2s speed bonus on your clock!',
        time: 'Just now',
      ),
      (
        icon: Icons.mail_outline,
        iconColor: AppTheme.peacockBlue,
        title: '👥 Invite Friends by Email',
        desc: 'You can now challenge any friend directly by typing their email in Play With Friend!',
        time: 'Today',
      ),
      (
        icon: Icons.chat_bubble_outline,
        iconColor: AppTheme.greenAccent,
        title: '💬 Real-Time In-Game Chat',
        desc: 'Send quick reactions or messages during online matches with automated safe chat filters.',
        time: 'Yesterday',
      ),
      (
        icon: Icons.emoji_events_outlined,
        iconColor: Colors.amberAccent,
        title: '🏆 Welcome to TigerHunt',
        desc: 'Play as Tigers (capture 5 goats) or Goats (trap all tigers). May the best hunter win!',
        time: 'Notice',
      ),
    ];

    return AlertDialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, color: AppTheme.tigerOrange, size: 22),
              SizedBox(width: 8),
              Text(
                'Notifications',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 16),
          itemBuilder: (context, index) {
            final n = notifications[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: n.iconColor.withValues(alpha: 0.15),
                  child: Icon(n.icon, color: n.iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            n.time,
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.desc,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tigerOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
