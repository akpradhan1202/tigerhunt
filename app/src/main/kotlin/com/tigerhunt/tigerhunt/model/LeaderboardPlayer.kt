package com.tigerhunt.tigerhunt.model

enum class LeaderboardFilter(val displayName: String, val icon: String) {
    TOTAL_WINS("Total Wins", "🏆"),
    TIGER_WINS("Tiger Wins", "🐅"),
    GOAT_WINS("Goat Wins", "🐐"),
    ELO_RATING("ELO Rating", "⭐")
}

data class LeaderboardPlayer(
    val id: String,
    val rank: Int = 0,
    val username: String,
    val avatar: String = "🐅",
    val customAvatarUri: String? = null,
    val country: String = "Nepal",
    val countryFlag: String = "🇳🇵",
    val totalWins: Int = 0,
    val tigerWins: Int = 0,
    val goatWins: Int = 0,
    val totalGames: Int = 0,
    val rating: Int = 1200,
    val title: String = "Highland Stalker",
    val isCurrentUser: Boolean = false
) {
    val winRate: Float
        get() = if (totalGames == 0) {
            if (totalWins > 0) 75f else 0f
        } else {
            (totalWins.toFloat() / totalGames * 100f).coerceIn(0f, 100f)
        }
}
