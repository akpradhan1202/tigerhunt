package com.tigerhunt.tigerhunt.data

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.tigerhunt.tigerhunt.MainActivity
import com.tigerhunt.tigerhunt.R

object NotificationHelper {
    private const val TAG = "TigerHuntNotifications"

    const val CHANNEL_FRIEND_TURNS = "tiger_hunt_friend_turns"
    const val CHANNEL_TOURNAMENTS = "tiger_hunt_tournaments"
    const val CHANNEL_GENERAL = "tiger_hunt_general"

    const val EXTRA_ROUTE = "extra_route"
    const val EXTRA_ROOM_CODE = "extra_room_code"
    const val EXTRA_FRIEND_NAME = "extra_friend_name"
    const val EXTRA_NOTIFICATION_TYPE = "extra_notification_type"

    const val TYPE_FRIEND_TURN = "FRIEND_TURN"
    const val TYPE_TOURNAMENT_START = "TOURNAMENT_START"
    const val TYPE_FRIEND_CHALLENGE = "FRIEND_CHALLENGE"

    fun createNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            // 1. Friend Match Turns Channel
            val friendTurnChannel = NotificationChannel(
                CHANNEL_FRIEND_TURNS,
                "Friend Match & Turn Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Real-time push alerts when it is your turn against friends or online opponents"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 150, 300)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }

            // 2. Tournament Starts & Bracket Channel
            val tournamentChannel = NotificationChannel(
                CHANNEL_TOURNAMENTS,
                "Tournament & Championship Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications when Himalayan Championship tournaments and rounds begin"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 400, 200, 400)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }

            // 3. General Game Events Channel
            val generalChannel = NotificationChannel(
                CHANNEL_GENERAL,
                "Tiger Hunt Announcements",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Leaderboard updates, daily challenges, and game news"
                enableLights(true)
                setShowBadge(true)
            }

            notificationManager.createNotificationChannel(friendTurnChannel)
            notificationManager.createNotificationChannel(tournamentChannel)
            notificationManager.createNotificationChannel(generalChannel)
            Log.d(TAG, "Notification channels registered successfully")
        }
    }

    /**
     * Sends a push notification alerting the player that it is their turn in a friend match.
     */
    fun sendFriendTurnNotification(
        context: Context,
        friendName: String,
        roomCode: String,
        role: String = "Goats",
        moveSummary: String? = null
    ) {
        val prefs = GamePreferences(context)
        if (!prefs.isPushNotificationsEnabled() || !prefs.isTurnNotificationsEnabled()) {
            Log.d(TAG, "Friend turn notification skipped due to user preference settings")
            return
        }

        createNotificationChannels(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_ROUTE, "play_friend")
            putExtra(EXTRA_ROOM_CODE, roomCode)
            putExtra(EXTRA_FRIEND_NAME, friendName)
            putExtra(EXTRA_NOTIFICATION_TYPE, TYPE_FRIEND_TURN)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            roomCode.hashCode() + 100,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = "🎯 Your Turn in Bagh-Chal!"
        val roleEmoji = if (role.contains("Tiger", ignoreCase = true)) "🐅 Tigers" else "🐐 Goats"
        val subtitle = if (!moveSummary.isNullOrEmpty()) {
            "$friendName played: $moveSummary.\nYour turn as $roleEmoji in Room #$roomCode!"
        } else {
            "$friendName has played their move in Room #$roomCode. It's now your turn to command the $roleEmoji!"
        }

        val largeIconBitmap = try {
            BitmapFactory.decodeResource(context.resources, R.drawable.ic_tiger_logo)
        } catch (_: Exception) {
            null
        }

        val notificationBuilder = NotificationCompat.Builder(context, CHANNEL_FRIEND_TURNS)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText("$friendName made a move • It's your turn ($roleEmoji)")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle(title)
                    .bigText(subtitle)
                    .setSummaryText("Room #$roomCode • Live Turn")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVibrate(longArrayOf(0, 300, 150, 300))
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(
                R.mipmap.ic_launcher,
                "Play Move",
                pendingIntent
            )

        if (largeIconBitmap != null) {
            notificationBuilder.setLargeIcon(largeIconBitmap)
        }

        try {
            val notificationManager = NotificationManagerCompat.from(context)
            val notificationId = 1000 + (System.currentTimeMillis() % 1000).toInt()
            notificationManager.notify(notificationId, notificationBuilder.build())
            Log.d(TAG, "Sent friend turn notification: id=$notificationId, friend=$friendName, room=$roomCode")
        } catch (e: SecurityException) {
            Log.w(TAG, "Missing notification permission to display friend turn notification", e)
        }
    }

    /**
     * Sends a push notification alerting the player that a tournament or bracket stage has started.
     */
    fun sendTournamentStartNotification(
        context: Context,
        tournamentTitle: String = "Kathmandu Championship Cup",
        stageName: String = "Quarter-Finals",
        opponentName: String = "Sherpa Tenzing"
    ) {
        val prefs = GamePreferences(context)
        if (!prefs.isPushNotificationsEnabled() || !prefs.isTournamentNotificationsEnabled()) {
            Log.d(TAG, "Tournament start notification skipped due to user preference settings")
            return
        }

        createNotificationChannels(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_ROUTE, "tournaments")
            putExtra(EXTRA_NOTIFICATION_TYPE, TYPE_TOURNAMENT_START)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            200,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = "🏆 $tournamentTitle Has Begun!"
        val bigText = "The championship bracket is active! Your $stageName match against $opponentName is waiting. Step onto the board and claim the Himalayan crown!"

        val largeIconBitmap = try {
            BitmapFactory.decodeResource(context.resources, R.drawable.ic_tiger_logo)
        } catch (_: Exception) {
            null
        }

        val notificationBuilder = NotificationCompat.Builder(context, CHANNEL_TOURNAMENTS)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText("$stageName: Face $opponentName now!")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle(title)
                    .bigText(bigText)
                    .setSummaryText("Championship Bracket • Active")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVibrate(longArrayOf(0, 400, 200, 400))
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(
                R.mipmap.ic_launcher,
                "Enter Tournament",
                pendingIntent
            )

        if (largeIconBitmap != null) {
            notificationBuilder.setLargeIcon(largeIconBitmap)
        }

        try {
            val notificationManager = NotificationManagerCompat.from(context)
            val notificationId = 2000 + (System.currentTimeMillis() % 1000).toInt()
            notificationManager.notify(notificationId, notificationBuilder.build())
            Log.d(TAG, "Sent tournament start notification: id=$notificationId, stage=$stageName")
        } catch (e: SecurityException) {
            Log.w(TAG, "Missing notification permission to display tournament notification", e)
        }
    }

    /**
     * Sends a push notification alerting the player of a direct challenge from a friend.
     */
    fun sendFriendChallengeNotification(
        context: Context,
        friendName: String,
        friendAvatar: String = "🐅"
    ) {
        val prefs = GamePreferences(context)
        if (!prefs.isPushNotificationsEnabled()) return

        createNotificationChannels(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_ROUTE, "play_friend")
            putExtra(EXTRA_FRIEND_NAME, friendName)
            putExtra(EXTRA_NOTIFICATION_TYPE, TYPE_FRIEND_CHALLENGE)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            300,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = "⚔️ Bagh-Chal Challenge from $friendName!"
        val bigText = "$friendAvatar $friendName challenged you to a live Himalayan Bagh-Chal duel! Accept the challenge and prove your mastery."

        val notificationBuilder = NotificationCompat.Builder(context, CHANNEL_FRIEND_TURNS)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText("$friendAvatar $friendName challenged you to a match!")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle(title)
                    .bigText(bigText)
                    .setSummaryText("Friend Challenge")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(R.mipmap.ic_launcher, "Accept Duel", pendingIntent)

        try {
            val notificationManager = NotificationManagerCompat.from(context)
            val notificationId = 3000 + (System.currentTimeMillis() % 1000).toInt()
            notificationManager.notify(notificationId, notificationBuilder.build())
        } catch (e: SecurityException) {
            Log.w(TAG, "Missing notification permission", e)
        }
    }
}
