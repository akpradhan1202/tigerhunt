package com.tigerhunt.tigerhunt.data

import android.content.Context
import android.util.Log
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

object PushNotificationManager {
    private const val TAG = "PushNotificationManager"

    const val TOPIC_TOURNAMENTS = "tournaments"
    const val TOPIC_FRIEND_MATCHES = "friend_matches"
    const val TOPIC_GLOBAL = "tigerhunt_global"

    fun initialize(context: Context, onTokenRetrieved: ((String) -> Unit)? = null) {
        NotificationHelper.createNotificationChannels(context)

        try {
            // Retrieve current FCM Registration Token
            FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                if (!task.isSuccessful) {
                    Log.w(TAG, "Fetching FCM registration token failed", task.exception)
                    return@addOnCompleteListener
                }

                val token = task.result
                Log.d(TAG, "Current FCM Token: $token")
                val prefs = GamePreferences(context)
                prefs.setFcmToken(token)
                onTokenRetrieved?.invoke(token)
            }

            // Subscribe to default topics
            FirebaseMessaging.getInstance().subscribeToTopic(TOPIC_TOURNAMENTS)
                .addOnSuccessListener { Log.d(TAG, "Subscribed to $TOPIC_TOURNAMENTS topic") }
            FirebaseMessaging.getInstance().subscribeToTopic(TOPIC_FRIEND_MATCHES)
                .addOnSuccessListener { Log.d(TAG, "Subscribed to $TOPIC_FRIEND_MATCHES topic") }
            FirebaseMessaging.getInstance().subscribeToTopic(TOPIC_GLOBAL)
                .addOnSuccessListener { Log.d(TAG, "Subscribed to $TOPIC_GLOBAL topic") }
        } catch (e: Exception) {
            Log.e(TAG, "FirebaseMessaging initialization encountered exception: ${e.message}")
        }
    }

    /**
     * Dispatches a friend turn push notification.
     */
    fun sendFriendTurnPush(
        context: Context,
        friendName: String,
        roomCode: String,
        role: String = "Goats",
        moveSummary: String? = null
    ) {
        NotificationHelper.sendFriendTurnNotification(
            context = context,
            friendName = friendName,
            roomCode = roomCode,
            role = role,
            moveSummary = moveSummary
        )
    }

    /**
     * Dispatches a tournament start push notification.
     */
    fun sendTournamentStartPush(
        context: Context,
        tournamentTitle: String = "Kathmandu Championship Cup",
        stageName: String = "Quarter-Finals",
        opponentName: String = "Sherpa Tenzing"
    ) {
        NotificationHelper.sendTournamentStartNotification(
            context = context,
            tournamentTitle = tournamentTitle,
            stageName = stageName,
            opponentName = opponentName
        )
    }

    /**
     * Schedules a simulated opponent turn notification with realistic delay (e.g., player minimized app or is waiting).
     */
    fun scheduleSimulatedFriendTurn(
        context: Context,
        friendName: String,
        roomCode: String,
        delayMillis: Long = 2500L,
        role: String = "Goats",
        moveSummary: String = "Goat deployed to Center intersection"
    ) {
        CoroutineScope(Dispatchers.Default).launch {
            delay(delayMillis)
            sendFriendTurnPush(
                context = context,
                friendName = friendName,
                roomCode = roomCode,
                role = role,
                moveSummary = moveSummary
            )
        }
    }
}
