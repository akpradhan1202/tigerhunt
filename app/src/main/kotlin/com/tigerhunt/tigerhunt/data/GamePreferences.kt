package com.tigerhunt.tigerhunt.data

import android.content.Context
import android.content.SharedPreferences
import com.tigerhunt.tigerhunt.model.AIDifficulty
import com.tigerhunt.tigerhunt.model.BoardTheme
import com.tigerhunt.tigerhunt.model.UserProfile

class GamePreferences(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("tiger_hunt_prefs", Context.MODE_PRIVATE)

    fun getUserProfile(): UserProfile {
        return UserProfile(
            id = prefs.getString("user_id", "local_player") ?: "local_player",
            username = prefs.getString("username", "Himalayan Hunter") ?: "Himalayan Hunter",
            rating = prefs.getInt("rating", 1200),
            title = prefs.getString("title", "Tiger Novice") ?: "Tiger Novice",
            avatarId = prefs.getString("avatar_id", "tiger_avatar") ?: "tiger_avatar",
            winsAsTiger = prefs.getInt("wins_tiger", 0),
            lossesAsTiger = prefs.getInt("losses_tiger", 0),
            winsAsGoat = prefs.getInt("wins_goat", 0),
            lossesAsGoat = prefs.getInt("losses_goat", 0),
            puzzlesSolved = prefs.getInt("puzzles_solved", 0),
            tournamentsWon = prefs.getInt("tournaments_won", 0)
        )
    }

    fun saveUserProfile(profile: UserProfile) {
        prefs.edit().apply {
            putString("username", profile.username)
            putInt("rating", profile.rating)
            putString("title", profile.title)
            putString("avatar_id", profile.avatarId)
            putInt("wins_tiger", profile.winsAsTiger)
            putInt("losses_tiger", profile.lossesAsTiger)
            putInt("wins_goat", profile.winsAsGoat)
            putInt("losses_goat", profile.lossesAsGoat)
            putInt("puzzles_solved", profile.puzzlesSolved)
            putInt("tournaments_won", profile.tournamentsWon)
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
}
