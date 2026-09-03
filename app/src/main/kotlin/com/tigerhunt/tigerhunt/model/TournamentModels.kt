package com.tigerhunt.tigerhunt.model

enum class TournamentStage(val displayName: String) {
    QUARTER_FINALS("Quarter-Finals"),
    SEMI_FINALS("Semi-Finals"),
    FINALS("Championship Finals"),
    COMPLETED("Tournament Champion")
}

data class TournamentContender(
    val id: String,
    val name: String,
    val avatar: String,
    val rating: Int,
    val difficulty: AIDifficulty,
    val isUser: Boolean = false
)

data class TournamentMatch(
    val id: String,
    val stage: TournamentStage,
    val player1: TournamentContender,
    val player2: TournamentContender,
    val winner: TournamentContender? = null,
    val boardLevel: BoardLevel = BoardLevel.SQUARE
)

data class TournamentState(
    val currentStage: TournamentStage = TournamentStage.QUARTER_FINALS,
    val matches: List<TournamentMatch> = emptyList(),
    val userContender: TournamentContender,
    val isUserEliminated: Boolean = false,
    val isUserChampion: Boolean = false
) {
    companion object {
        fun createDefault(userName: String = "You"): TournamentState {
            val user = TournamentContender("user", userName, "🐯", 1200, AIDifficulty.MEDIUM, isUser = true)
            val aiContenders = listOf(
                TournamentContender("ai_1", "Sherpa Tenzing", "🏔️", 1100, AIDifficulty.EASY),
                TournamentContender("ai_2", "Pokhara Puma", "🐆", 1300, AIDifficulty.MEDIUM),
                TournamentContender("ai_3", "Annapurna Hunter", "🦅", 1450, AIDifficulty.MEDIUM),
                TournamentContender("ai_4", "Kathmandu King", "👑", 1600, AIDifficulty.HARD),
                TournamentContender("ai_5", "Everest Yeti", "❄️", 1750, AIDifficulty.HARD),
                TournamentContender("ai_6", "Himalayan Tiger", "🐅", 1900, AIDifficulty.EXPERT),
                TournamentContender("ai_7", "Bagh Grandmaster", "🧘", 2100, AIDifficulty.EXPERT)
            )

            val qfMatches = listOf(
                TournamentMatch("m_qf_1", TournamentStage.QUARTER_FINALS, user, aiContenders[0]),
                TournamentMatch("m_qf_2", TournamentStage.QUARTER_FINALS, aiContenders[1], aiContenders[2]),
                TournamentMatch("m_qf_3", TournamentStage.QUARTER_FINALS, aiContenders[3], aiContenders[4]),
                TournamentMatch("m_qf_4", TournamentStage.QUARTER_FINALS, aiContenders[5], aiContenders[6])
            )

            return TournamentState(
                currentStage = TournamentStage.QUARTER_FINALS,
                matches = qfMatches,
                userContender = user
            )
        }
    }
}
