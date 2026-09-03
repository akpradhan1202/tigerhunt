package com.tigerhunt.tigerhunt.model

enum class AuthMethod(val displayName: String, val icon: String) {
    GUEST("Guest", "👤"),
    GMAIL("Google / Gmail", "🇬"),
    PHONE("Mobile Number", "📱")
}

data class UserProfile(
    val id: String = "local_player",
    val username: String = "Himalayan Hunter",
    val email: String? = null,
    val phoneNumber: String? = null,
    val authMethod: AuthMethod = AuthMethod.GUEST,
    val isLoggedIn: Boolean = false,
    val rating: Int = 1200,
    val title: String = "Tiger Novice",
    val avatarId: String = "🐅",
    val customAvatarUri: String? = null,
    val winsAsTiger: Int = 0,
    val lossesAsTiger: Int = 0,
    val winsAsGoat: Int = 0,
    val lossesAsGoat: Int = 0,
    val puzzlesSolved: Int = 0,
    val tournamentsWon: Int = 0,
    val coins: Int = 150,
    val dailyStreak: Int = 0,
    val lastDailyPuzzleDate: String? = null
) {
    val totalGames: Int get() = winsAsTiger + lossesAsTiger + winsAsGoat + lossesAsGoat
    val totalWins: Int get() = winsAsTiger + winsAsGoat
    val winRate: Float get() = if (totalGames == 0) 0f else (totalWins.toFloat() / totalGames * 100f)

    val friendCode: String get() {
        val hash = (username + id).hashCode()
        val num = kotlin.math.abs(hash % 9000) + 1000
        return "BH-$num"
    }

    val currentRank: String get() = when {
        rating >= 2100 -> "Grandmaster of the Heights"
        rating >= 1800 -> "Apex Predator"
        rating >= 1500 -> "Mountain Guardian"
        rating >= 1200 -> "Highland Stalker"
        else -> "Bagh Novice"
    }
}

enum class FriendStatus(val label: String, val colorHex: Long) {
    ONLINE("Online", 0xFF00E676),
    IN_GAME("In Match", 0xFFFFB300),
    OFFLINE("Offline", 0xFF9E9E9E)
}

data class Friend(
    val id: String,
    val name: String,
    val avatar: String = "🐅",
    val rating: Int = 1200,
    val rank: String = "Highland Stalker",
    val status: FriendStatus = FriendStatus.ONLINE,
    val friendCode: String,
    val countryFlag: String = "🇳🇵",
    val isFavorite: Boolean = false,
    val lastSeen: String = "Just now"
)

data class GameRecord(
    val id: String,
    val dateMillis: Long,
    val mode: GameMode,
    val boardLevel: BoardLevel,
    val playerSide: PieceType,
    val winner: GameWinner,
    val totalMoves: Int,
    val goatsCaptured: Int,
    val ratingChange: Int = 0
)


