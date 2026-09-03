package com.tigerhunt.tigerhunt.data

import android.content.Context
import android.content.SharedPreferences
import com.tigerhunt.tigerhunt.model.*

class GamePreferences(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("tiger_hunt_prefs", Context.MODE_PRIVATE)

    fun getUserProfile(): UserProfile {
        val authMethodName = prefs.getString("auth_method", AuthMethod.GUEST.name)
        val authMethod = try {
            AuthMethod.valueOf(authMethodName ?: AuthMethod.GUEST.name)
        } catch (_: Exception) {
            AuthMethod.GUEST
        }

        return UserProfile(
            id = prefs.getString("user_id", "local_player") ?: "local_player",
            username = prefs.getString("username", "Himalayan Hunter") ?: "Himalayan Hunter",
            email = prefs.getString("email", null),
            phoneNumber = prefs.getString("phone_number", null),
            authMethod = authMethod,
            isLoggedIn = prefs.getBoolean("is_logged_in", false),
            rating = prefs.getInt("rating", 1200),
            title = prefs.getString("title", "Tiger Novice") ?: "Tiger Novice",
            avatarId = prefs.getString("avatar_id", "🐅") ?: "🐅",
            customAvatarUri = prefs.getString("custom_avatar_uri", null),
            winsAsTiger = prefs.getInt("wins_tiger", 0),
            lossesAsTiger = prefs.getInt("losses_tiger", 0),
            winsAsGoat = prefs.getInt("wins_goat", 0),
            lossesAsGoat = prefs.getInt("losses_goat", 0),
            puzzlesSolved = prefs.getInt("puzzles_solved", 0),
            tournamentsWon = prefs.getInt("tournaments_won", 0),
            coins = prefs.getInt("virtual_coins", 150),
            dailyStreak = prefs.getInt("daily_streak", 0),
            lastDailyPuzzleDate = prefs.getString("last_daily_puzzle_date", null)
        )
    }

    fun saveUserProfile(profile: UserProfile) {
        prefs.edit().apply {
            putString("user_id", profile.id)
            putString("username", profile.username)
            putString("email", profile.email)
            putString("phone_number", profile.phoneNumber)
            putString("auth_method", profile.authMethod.name)
            putBoolean("is_logged_in", profile.isLoggedIn)
            putInt("rating", profile.rating)
            putString("title", profile.title)
            putString("avatar_id", profile.avatarId)
            putString("custom_avatar_uri", profile.customAvatarUri)
            putInt("wins_tiger", profile.winsAsTiger)
            putInt("losses_tiger", profile.lossesAsTiger)
            putInt("wins_goat", profile.winsAsGoat)
            putInt("losses_goat", profile.lossesAsGoat)
            putInt("puzzles_solved", profile.puzzlesSolved)
            putInt("tournaments_won", profile.tournamentsWon)
            putInt("virtual_coins", profile.coins)
            putInt("daily_streak", profile.dailyStreak)
            putString("last_daily_puzzle_date", profile.lastDailyPuzzleDate)
            apply()
        }
    }

    fun clearSession() {
        prefs.edit().apply {
            putBoolean("is_logged_in", false)
            putString("auth_method", AuthMethod.GUEST.name)
            putString("email", null)
            putString("phone_number", null)
            putString("username", "Guest Hunter")
            apply()
        }
    }

    fun getSelectedTheme(): BoardTheme {
        val name = prefs.getString("board_theme", BoardTheme.CLASSIC_NEPAL.name)
        return try {
            BoardTheme.valueOf(name ?: BoardTheme.CLASSIC_NEPAL.name)
        } catch (_: Exception) {
            BoardTheme.CLASSIC_NEPAL
        }
    }

    fun setSelectedTheme(theme: BoardTheme) {
        prefs.edit().putString("board_theme", theme.name).apply()
    }

    fun isSoundEnabled(): Boolean = prefs.getBoolean("sound_enabled", true)
    fun setSoundEnabled(enabled: Boolean) = prefs.edit().putBoolean("sound_enabled", enabled).apply()

    fun isHapticsEnabled(): Boolean = prefs.getBoolean("haptics_enabled", true)
    fun setHapticsEnabled(enabled: Boolean) = prefs.edit().putBoolean("haptics_enabled", enabled).apply()

    fun isPowerUpsEnabled(): Boolean = prefs.getBoolean("powerups_enabled", false)
    fun setPowerUpsEnabled(enabled: Boolean) = prefs.edit().putBoolean("powerups_enabled", enabled).apply()

    fun isSolvedPuzzle(id: String): Boolean = prefs.getBoolean("puzzle_solved_$id", false)
    fun markPuzzleSolved(id: String) {
        prefs.edit().putBoolean("puzzle_solved_$id", true).apply()
        val currentSolved = prefs.getInt("puzzles_solved", 0)
        prefs.edit().putInt("puzzles_solved", currentSolved + 1).apply()
    }

    fun isDailyPuzzleSolvedForDate(dateStr: String): Boolean = prefs.getBoolean("daily_puzzle_solved_$dateStr", false)
    fun markDailyPuzzleSolvedForDate(dateStr: String) {
        prefs.edit().putBoolean("daily_puzzle_solved_$dateStr", true).apply()
    }

    fun getCoins(): Int = prefs.getInt("virtual_coins", 150)
    fun addCoins(amount: Int): Int {
        val current = getCoins()
        val updated = (current + amount).coerceAtLeast(0)
        prefs.edit().putInt("virtual_coins", updated).apply()
        return updated
    }

    fun getDefaultDifficulty(): AIDifficulty {
        val name = prefs.getString("default_difficulty", AIDifficulty.MEDIUM.name)
        return try {
            AIDifficulty.valueOf(name ?: AIDifficulty.MEDIUM.name)
        } catch (_: Exception) {
            AIDifficulty.MEDIUM
        }
    }

    fun setDefaultDifficulty(difficulty: AIDifficulty) {
        prefs.edit().putString("default_difficulty", difficulty.name).apply()
    }

    // Push Notification Settings (FCM)
    fun isPushNotificationsEnabled(): Boolean = prefs.getBoolean("push_notifications_enabled", true)
    fun setPushNotificationsEnabled(enabled: Boolean) = prefs.edit().putBoolean("push_notifications_enabled", enabled).apply()

    fun isTurnNotificationsEnabled(): Boolean = prefs.getBoolean("turn_notifications_enabled", true)
    fun setTurnNotificationsEnabled(enabled: Boolean) = prefs.edit().putBoolean("turn_notifications_enabled", enabled).apply()

    fun isTournamentNotificationsEnabled(): Boolean = prefs.getBoolean("tournament_notifications_enabled", true)
    fun setTournamentNotificationsEnabled(enabled: Boolean) = prefs.edit().putBoolean("tournament_notifications_enabled", enabled).apply()

    fun isFirstLoginTutorialCompleted(): Boolean = prefs.getBoolean("tutorial_completed", false)
    fun setFirstLoginTutorialCompleted(completed: Boolean) = prefs.edit().putBoolean("tutorial_completed", completed).apply()

    fun getFcmToken(): String? = prefs.getString("fcm_token", null)
    fun setFcmToken(token: String?) = prefs.edit().putString("fcm_token", token).apply()
}
