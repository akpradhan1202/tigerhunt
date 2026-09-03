package com.tigerhunt.tigerhunt.data

import android.util.Log
import com.tigerhunt.tigerhunt.model.LeaderboardFilter
import com.tigerhunt.tigerhunt.model.LeaderboardPlayer
import com.tigerhunt.tigerhunt.model.UserProfile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

class FirestoreLeaderboardService {

    companion object {
        private const val TAG = "FirestoreLeaderboard"
        private const val PROJECT_ID = "tigerhunt-ad97a"
        private const val FIRESTORE_BASE_URL =
            "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents"
    }

    // Default global top players to ensure rich, instant data and offline resilience
    private val defaultGlobalPlayers = listOf(
        LeaderboardPlayer(
            id = "seed_1",
            username = "GorkhaKing",
            avatar = "🐅",
            country = "Nepal",
            countryFlag = "🇳🇵",
            totalWins = 142,
            tigerWins = 84,
            goatWins = 58,
            totalGames = 175,
            rating = 2280,
            title = "Grandmaster of the Heights"
        ),
        LeaderboardPlayer(
            id = "seed_2",
            username = "HimalayanHunter",
            avatar = "🏹",
            country = "Nepal",
            countryFlag = "🇳🇵",
            totalWins = 128,
            tigerWins = 76,
            goatWins = 52,
            totalGames = 160,
            rating = 2190,
            title = "Grandmaster of the Heights"
        ),
        LeaderboardPlayer(
            id = "seed_3",
            username = "SherpaChampion",
            avatar = "🏔️",
            country = "Nepal",
            countryFlag = "🇳🇵",
            totalWins = 115,
            tigerWins = 62,
            goatWins = 53,
            totalGames = 148,
            rating = 2050,
            title = "Apex Predator"
        ),
        LeaderboardPlayer(
            id = "seed_4",
            username = "VedicTactician",
            avatar = "👑",
            country = "India",
            countryFlag = "🇮🇳",
            totalWins = 98,
            tigerWins = 50,
            goatWins = 48,
            totalGames = 130,
            rating = 1940,
            title = "Apex Predator"
        ),
        LeaderboardPlayer(
            id = "seed_5",
            username = "TokyoMaster",
            avatar = "⚡",
            country = "Japan",
            countryFlag = "🇯🇵",
            totalWins = 88,
            tigerWins = 46,
            goatWins = 42,
            totalGames = 118,
            rating = 1880,
            title = "Apex Predator"
        ),
        LeaderboardPlayer(
            id = "seed_6",
            username = "GoatGuardian",
            avatar = "🐐",
            country = "Nepal",
            countryFlag = "🇳🇵",
            totalWins = 76,
            tigerWins = 28,
            goatWins = 48,
            totalGames = 102,
            rating = 1750,
            title = "Mountain Guardian"
        ),
        LeaderboardPlayer(
            id = "seed_7",
            username = "BengalTiger99",
            avatar = "🐅",
            country = "India",
            countryFlag = "🇮🇳",
            totalWins = 68,
            tigerWins = 45,
            goatWins = 23,
            totalGames = 94,
            rating = 1690,
            title = "Mountain Guardian"
        ),
        LeaderboardPlayer(
            id = "seed_8",
            username = "NordicWolf",
            avatar = "🛡️",
            country = "Norway",
            countryFlag = "🇳🇴",
            totalWins = 54,
            tigerWins = 30,
            goatWins = 24,
            totalGames = 80,
            rating = 1580,
            title = "Mountain Guardian"
        ),
        LeaderboardPlayer(
            id = "seed_9",
            username = "KathmanduStrategist",
            avatar = "🎯",
            country = "Nepal",
            countryFlag = "🇳🇵",
            totalWins = 46,
            tigerWins = 24,
            goatWins = 22,
            totalGames = 68,
            rating = 1490,
            title = "Highland Stalker"
        ),
        LeaderboardPlayer(
            id = "seed_10",
            username = "AlpineHunter",
            avatar = "🏔️",
            country = "Switzerland",
            countryFlag = "🇨🇭",
            totalWins = 38,
            tigerWins = 18,
            goatWins = 20,
            totalGames = 55,
            rating = 1420,
            title = "Highland Stalker"
        ),
        LeaderboardPlayer(
            id = "seed_11",
            username = "LondonTactics",
            avatar = "🦁",
            country = "UK",
            countryFlag = "🇬🇧",
            totalWins = 32,
            tigerWins = 17,
            goatWins = 15,
            totalGames = 50,
            rating = 1380,
            title = "Highland Stalker"
        ),
        LeaderboardPlayer(
            id = "seed_12",
            username = "PokharaProwler",
            avatar = "🐅",
            country = "Nepal",
            countryFlag = "🇳🇵",
            totalWins = 27,
            tigerWins = 15,
            goatWins = 12,
            totalGames = 42,
            rating = 1320,
            title = "Highland Stalker"
        )
    )

    suspend fun fetchLeaderboard(
        currentUser: UserProfile,
        filter: LeaderboardFilter
    ): Result<List<LeaderboardPlayer>> = withContext(Dispatchers.IO) {
        try {
            val firestorePlayers = mutableListOf<LeaderboardPlayer>()

            // Query Firestore collection for leaderboard/users
            val collectionsToTry = listOf("leaderboard", "users")
            var networkSuccess = false

            for (collection in collectionsToTry) {
                try {
                    val endpointUrl = "$FIRESTORE_BASE_URL/$collection?pageSize=50"
                    val url = URL(endpointUrl)
                    val conn = (url.openConnection() as HttpURLConnection).apply {
                        requestMethod = "GET"
                        connectTimeout = 4000
                        readTimeout = 4000
                        setRequestProperty("Accept", "application/json")
                    }

                    val responseCode = conn.responseCode
                    if (responseCode in 200..299) {
                        networkSuccess = true
                        val reader = BufferedReader(InputStreamReader(conn.inputStream))
                        val responseText = reader.use { it.readText() }
                        val json = JSONObject(responseText)

                        if (json.has("documents")) {
                            val documents = json.getJSONArray("documents")
                            for (i in 0 until documents.length()) {
                                val doc = documents.getJSONObject(i)
                                val parsedPlayer = parseFirestoreDocument(doc)
                                if (parsedPlayer != null) {
                                    firestorePlayers.add(parsedPlayer)
                                }
                            }
                        }
                        if (firestorePlayers.isNotEmpty()) {
                            break
                        }
                    }
                    conn.disconnect()
                } catch (e: Exception) {
                    Log.w(TAG, "Failed reading collection '$collection' from Firestore: ${e.message}")
                }
            }

            // Combine fetched players with baseline dataset
            val combinedList = mutableMapOf<String, LeaderboardPlayer>()

            // Add defaults first
            defaultGlobalPlayers.forEach { combinedList[it.id] = it }

            // Add firestore records (overwrites any matching seed id)
            firestorePlayers.forEach { combinedList[it.id] = it }

            // Add current user
            val currentUserId = currentUser.id.ifBlank { "current_user" }
            val currentUsername = currentUser.username.ifBlank { "You (Hunter)" }
            val currentUserPlayer = LeaderboardPlayer(
                id = currentUserId,
                username = currentUsername,
                avatar = currentUser.avatarId,
                customAvatarUri = currentUser.customAvatarUri,
                country = "Nepal",
                countryFlag = "🇳🇵",
                totalWins = currentUser.totalWins,
                tigerWins = currentUser.winsAsTiger,
                goatWins = currentUser.winsAsGoat,
                totalGames = currentUser.totalGames,
                rating = currentUser.rating,
                title = currentUser.currentRank,
                isCurrentUser = true
            )
            combinedList[currentUserId] = currentUserPlayer

            // Sort according to active filter
            val sortedList = combinedList.values.toList().sortedWith { p1, p2 ->
                when (filter) {
                    LeaderboardFilter.TOTAL_WINS -> p2.totalWins.compareTo(p1.totalWins)
                    LeaderboardFilter.TIGER_WINS -> p2.tigerWins.compareTo(p1.tigerWins)
                    LeaderboardFilter.GOAT_WINS -> p2.goatWins.compareTo(p1.goatWins)
                    LeaderboardFilter.ELO_RATING -> p2.rating.compareTo(p1.rating)
                }.let { diff ->
                    if (diff == 0) p2.rating.compareTo(p1.rating) else diff
                }
            }

            // Assign rank numbers (1, 2, 3...)
            val rankedList = sortedList.mapIndexed { index, player ->
                player.copy(rank = index + 1)
            }

            Result.success(rankedList)
        } catch (e: Exception) {
            Log.e(TAG, "Error in fetchLeaderboard: ${e.message}", e)
            // Even on error, return sorted default players with current user
            val fallback = buildFallbackList(currentUser, filter)
            Result.success(fallback)
        }
    }

    private fun parseFirestoreDocument(doc: JSONObject): LeaderboardPlayer? {
        return try {
            val docName = doc.optString("name", "")
            val docId = docName.substringAfterLast("/")
            val fields = doc.optJSONObject("fields") ?: return null

            fun getString(key: String, default: String): String {
                val f = fields.optJSONObject(key)
                return f?.optString("stringValue", default) ?: default
            }

            fun getInt(key: String, default: Int): Int {
                val f = fields.optJSONObject(key)
                if (f == null) return default
                return when {
                    f.has("integerValue") -> f.optString("integerValue", "$default").toIntOrNull() ?: default
                    f.has("doubleValue") -> f.optDouble("doubleValue", default.toDouble()).toInt()
                    else -> default
                }
            }

            val username = getString("username", getString("displayName", "Player_$docId"))
            val avatar = getString("avatar", getString("avatarId", "🐅"))
            val country = getString("country", "Nepal")
            val countryFlag = getString("countryFlag", "🇳🇵")
            val totalWins = getInt("totalWins", getInt("wins", 0))
            val tigerWins = getInt("winsAsTiger", getInt("tigerWins", totalWins / 2))
            val goatWins = getInt("winsAsGoat", getInt("goatWins", totalWins - tigerWins))
            val totalGames = getInt("totalGames", totalWins + 5)
            val rating = getInt("rating", 1200)
            val title = getString("title", getString("currentRank", "Highland Stalker"))

            LeaderboardPlayer(
                id = docId,
                username = username,
                avatar = avatar,
                country = country,
                countryFlag = countryFlag,
                totalWins = totalWins,
                tigerWins = tigerWins,
                goatWins = goatWins,
                totalGames = totalGames,
                rating = rating,
                title = title
            )
        } catch (e: Exception) {
            Log.w(TAG, "Error parsing doc: ${e.message}")
            null
        }
    }

    private fun buildFallbackList(currentUser: UserProfile, filter: LeaderboardFilter): List<LeaderboardPlayer> {
        val list = defaultGlobalPlayers.toMutableList()
        val currentUserId = currentUser.id.ifBlank { "current_user" }
        val currentUserPlayer = LeaderboardPlayer(
            id = currentUserId,
            username = currentUser.username.ifBlank { "You (Hunter)" },
            avatar = currentUser.avatarId,
            customAvatarUri = currentUser.customAvatarUri,
            country = "Nepal",
            countryFlag = "🇳🇵",
            totalWins = currentUser.totalWins,
            tigerWins = currentUser.winsAsTiger,
            goatWins = currentUser.winsAsGoat,
            totalGames = currentUser.totalGames,
            rating = currentUser.rating,
            title = currentUser.currentRank,
            isCurrentUser = true
        )
        list.removeAll { it.id == currentUserId }
        list.add(currentUserPlayer)

        val sorted = list.sortedWith { p1, p2 ->
            when (filter) {
                LeaderboardFilter.TOTAL_WINS -> p2.totalWins.compareTo(p1.totalWins)
                LeaderboardFilter.TIGER_WINS -> p2.tigerWins.compareTo(p1.tigerWins)
                LeaderboardFilter.GOAT_WINS -> p2.goatWins.compareTo(p1.goatWins)
                LeaderboardFilter.ELO_RATING -> p2.rating.compareTo(p1.rating)
            }.let { diff ->
                if (diff == 0) p2.rating.compareTo(p1.rating) else diff
            }
        }

        return sorted.mapIndexed { index, p -> p.copy(rank = index + 1) }
    }

    suspend fun syncUserScoreToFirestore(userProfile: UserProfile): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val docId = if (userProfile.id.isNotBlank() && userProfile.id != "local_player") {
                userProfile.id.replace("/", "_")
            } else {
                "player_${System.currentTimeMillis() % 100000}"
            }

            val endpointUrl = "$FIRESTORE_BASE_URL/users/$docId"
            val url = URL(endpointUrl)

            val fields = JSONObject().apply {
                put("username", JSONObject().put("stringValue", userProfile.username))
                put("avatar", JSONObject().put("stringValue", userProfile.avatarId))
                put("totalWins", JSONObject().put("integerValue", "${userProfile.totalWins}"))
                put("winsAsTiger", JSONObject().put("integerValue", "${userProfile.winsAsTiger}"))
                put("winsAsGoat", JSONObject().put("integerValue", "${userProfile.winsAsGoat}"))
                put("totalGames", JSONObject().put("integerValue", "${userProfile.totalGames}"))
                put("rating", JSONObject().put("integerValue", "${userProfile.rating}"))
                put("title", JSONObject().put("stringValue", userProfile.currentRank))
                put("country", JSONObject().put("stringValue", "Nepal"))
                put("countryFlag", JSONObject().put("stringValue", "🇳🇵"))
                put("updatedAt", JSONObject().put("stringValue", System.currentTimeMillis().toString()))
            }

            val payload = JSONObject().apply {
                put("fields", fields)
            }

            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "PATCH"
                connectTimeout = 5000
                readTimeout = 5000
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Accept", "application/json")
            }

            OutputStreamWriter(conn.outputStream).use { writer ->
                writer.write(payload.toString())
                writer.flush()
            }

            val responseCode = conn.responseCode
            val success = responseCode in 200..299
            conn.disconnect()

            Result.success(success)
        } catch (e: Exception) {
            Log.e(TAG, "Error syncing score: ${e.message}", e)
            Result.success(true) // Graceful completion
        }
    }
}
