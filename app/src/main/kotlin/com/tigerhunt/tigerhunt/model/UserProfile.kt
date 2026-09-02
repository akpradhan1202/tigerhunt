package com.tigerhunt.tigerhunt.model

data class UserProfile(
    val id: String = "local_player",
    val username: String = "Himalayan Hunter",
    val rating: Int = 1200,
    val title: String = "Tiger Novice",
    val avatarId: String = "tiger_avatar",
    val winsAsTiger: Int = 0,
    val lossesAsTiger: Int = 0,
    val winsAsGoat: Int = 0,
    val lossesAsGoat: Int = 0,
    val puzzlesSolved: Int = 0,
    val tournamentsWon: Int = 0
) {
    val totalGames: Int get() = winsAsTiger + lossesAsTiger + winsAsGoat + lossesAsGoat
    val totalWins: Int get() = winsAsTiger + winsAsGoat
    val winRate: Float get() = if (totalGames == 0) 0f else (totalWins.toFloat() / totalGames * 100f)

    val currentRank: String get() = when {
        rating >= 2100 -> "Grandmaster of the Heights"
        rating >= 1800 -> "Apex Predator"
        rating >= 1500 -> "Mountain Guardian"
        rating >= 1200 -> "Highland Stalker"
        else -> "Bagh Novice"
    }
}

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
