package com.tigerhunt.tigerhunt.data

import android.app.PendingIntent
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.tigerhunt.tigerhunt.MainActivity
import com.tigerhunt.tigerhunt.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class TigerHuntFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM Token generated: $token")
        
        // Save FCM token in preferences
        val prefs = GamePreferences(applicationContext)
        prefs.setFcmToken(token)

        // Attempt to sync token with Firestore if user is logged in
        try {
            val userProfile = prefs.getUserProfile()
            if (userProfile.isLoggedIn) {
                kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
                    val firestoreService = FirestoreLeaderboardService()
                    firestoreService.syncUserScoreToFirestore(userProfile)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to sync FCM token with Firestore: ${e.message}")
        }
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "FCM Message received from: ${remoteMessage.from}, data: ${remoteMessage.data}")

        val data = remoteMessage.data
        val type = data["type"] ?: data["notification_type"] ?: remoteMessage.notification?.title ?: ""

        when {
            type.contains("FRIEND_TURN", ignoreCase = true) || type.contains("turn", ignoreCase = true) -> {
                val friendName = data["friend_name"] ?: data["opponent"] ?: "Your Friend"
                val roomCode = data["room_code"] ?: "8899"
                val role = data["role"] ?: "Goats"
                val moveSummary = data["move_summary"]

                NotificationHelper.sendFriendTurnNotification(
                    context = applicationContext,
                    friendName = friendName,
                    roomCode = roomCode,
                    role = role,
                    moveSummary = moveSummary
                )
            }

            type.contains("TOURNAMENT", ignoreCase = true) -> {
                val tournamentTitle = data["tournament_title"] ?: "Himalayan Championship Cup"
                val stageName = data["stage"] ?: "Quarter-Finals"
                val opponentName = data["opponent"] ?: "Sherpa Tenzing"

                NotificationHelper.sendTournamentStartNotification(
                    context = applicationContext,
                    tournamentTitle = tournamentTitle,
                    stageName = stageName,
                    opponentName = opponentName
                )
            }

            type.contains("CHALLENGE", ignoreCase = true) -> {
                val friendName = data["friend_name"] ?: "Challenger"
                val avatar = data["avatar"] ?: "🐅"

                NotificationHelper.sendFriendChallengeNotification(
                    context = applicationContext,
                    friendName = friendName,
                    friendAvatar = avatar
                )
            }

            else -> {
                // Generic notification payload fallback
                val title = remoteMessage.notification?.title ?: data["title"] ?: "🐅 Tiger Hunt Bagh-Chal"
                val body = remoteMessage.notification?.body ?: data["body"] ?: "A game event is ready in Tiger Hunt."
                displayGenericNotification(title, body)
            }
        }
    }

    private fun displayGenericNotification(title: String, body: String) {
        NotificationHelper.createNotificationChannels(applicationContext)

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            999,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, NotificationHelper.CHANNEL_GENERAL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        try {
            NotificationManagerCompat.from(this).notify(500, notification)
        } catch (e: SecurityException) {
            Log.w(TAG, "Notification permission missing for generic alert", e)
        }
    }

    companion object {
        private const val TAG = "TigerHuntFCMService"
    }
}
