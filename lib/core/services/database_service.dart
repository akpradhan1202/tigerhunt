import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'auth_service.dart';

/// Lightweight SQLite database service for storing game data
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'tigerhunt.db';
  static const int _dbVersion = 1;

  /// Get database instance (singleton). SQLite is a native-only feature;
  /// on web this throws a clear error instead of crashing with the opaque
  /// "Method not implemented" from the sqflite web stub.
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Local SQLite database is not available on web. '
        'Use the cloud database instead.',
      );
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with all tables
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables
  Future<void> _onCreate(Database db, int version) async {
    // Users table (only for authenticated users, not guests)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        displayName TEXT NOT NULL,
        email TEXT,
        photoUrl TEXT,
        authType TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isGuest INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Game history table
    await db.execute('''
      CREATE TABLE game_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        playedAs TEXT NOT NULL,
        opponentType TEXT,
        winner TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        boardTheme TEXT NOT NULL,
        timeControl TEXT NOT NULL,
        totalMoves INTEGER NOT NULL,
        goatsCaptured INTEGER NOT NULL,
        playedAt TEXT NOT NULL,
        isGuestGame INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // User statistics table
    await db.execute('''
      CREATE TABLE user_stats (
        userId TEXT PRIMARY KEY,
        gamesPlayed INTEGER NOT NULL DEFAULT 0,
        gamesWon INTEGER NOT NULL DEFAULT 0,
        gamesLost INTEGER NOT NULL DEFAULT 0,
        gamesDraw INTEGER NOT NULL DEFAULT 0,
        totalPlayTime INTEGER NOT NULL DEFAULT 0,
        longestWinStreak INTEGER NOT NULL DEFAULT 0,
        currentWinStreak INTEGER NOT NULL DEFAULT 0,
        rating INTEGER NOT NULL DEFAULT 1200,
        lastPlayedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // Game settings/preferences table
    await db.execute('''
      CREATE TABLE game_settings (
        userId TEXT PRIMARY KEY,
        boardTheme TEXT NOT NULL DEFAULT 'classic',
        soundEnabled INTEGER NOT NULL DEFAULT 1,
        musicEnabled INTEGER NOT NULL DEFAULT 1,
        hapticEnabled INTEGER NOT NULL DEFAULT 1,
        showHints INTEGER NOT NULL DEFAULT 1,
        animationSpeed TEXT NOT NULL DEFAULT 'normal',
        preferredTimeControl TEXT NOT NULL DEFAULT 'none',
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // Guest session data (temporary, cleared on sign out)
    await db.execute('''
      CREATE TABLE guest_session (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Saved games (for resume functionality)
    await db.execute('''
      CREATE TABLE saved_games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        gameState TEXT NOT NULL,
        boardTheme TEXT NOT NULL,
        timeControl TEXT NOT NULL,
        currentTurn TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'in_progress',
        savedAt TEXT NOT NULL,
        isGuestGame INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration logic here for future versions
  }

  // ============ USER OPERATIONS ============

  /// Save user to database (authenticated users only)
  Future<void> saveUser(AppUser user) async {
    if (user.isGuest) return; // Don't save guest users

    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Initialize user stats if new user
    await db.insert(
      'user_stats',
      {'userId': user.id},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Initialize user settings if new user
    await db.insert(
      'game_settings',
      {'userId': user.id},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Get user by ID
  Future<AppUser?> getUser(String userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;
    return AppUser.fromMap(results.first);
  }

  // ============ GAME HISTORY OPERATIONS ============

  /// Save game to history
  Future<void> saveGameHistory({
    required String userId,
    required String playedAs,
    String? opponentType,
    required String winner,
    required int durationSeconds,
    required String boardTheme,
    required String timeControl,
    required int totalMoves,
    required int goatsCaptured,
    required bool isGuestGame,
  }) async {
    final db = await database;
    await db.insert('game_history', {
      'userId': userId,
      'playedAs': playedAs,
      'opponentType': opponentType,
      'winner': winner,
      'durationSeconds': durationSeconds,
      'boardTheme': boardTheme,
      'timeControl': timeControl,
      'totalMoves': totalMoves,
      'goatsCaptured': goatsCaptured,
      'playedAt': DateTime.now().toIso8601String(),
      'isGuestGame': isGuestGame ? 1 : 0,
    });
  }

  /// Get game history for user
  Future<List<Map<String, dynamic>>> getGameHistory(String userId,
      {int limit = 50}) async {
    final db = await database;
    return await db.query(
      'game_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'playedAt DESC',
      limit: limit,
    );
  }

  // ============ USER STATS OPERATIONS ============

  /// Get user statistics
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    final db = await database;
    final results = await db.query(
      'user_stats',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Update user statistics after a game
  Future<void> updateUserStats({
    required String userId,
    required bool won,
    required bool lost,
    required bool draw,
    required int playTime,
  }) async {
    final db = await database;
    final stats = await getUserStats(userId);

    if (stats == null) return;

    int currentStreak = stats['currentWinStreak'] as int;
    int longestStreak = stats['longestWinStreak'] as int;

    if (won) {
      currentStreak++;
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    } else {
      currentStreak = 0;
    }

    await db.update(
      'user_stats',
      {
        'gamesPlayed': (stats['gamesPlayed'] as int) + 1,
        'gamesWon': (stats['gamesWon'] as int) + (won ? 1 : 0),
        'gamesLost': (stats['gamesLost'] as int) + (lost ? 1 : 0),
        'gamesDraw': (stats['gamesDraw'] as int) + (draw ? 1 : 0),
        'totalPlayTime': (stats['totalPlayTime'] as int) + playTime,
        'currentWinStreak': currentStreak,
        'longestWinStreak': longestStreak,
        'lastPlayedAt': DateTime.now().toIso8601String(),
      },
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // ============ GAME SETTINGS OPERATIONS ============

  /// Get user game settings
  Future<Map<String, dynamic>?> getGameSettings(String userId) async {
    final db = await database;
    final results = await db.query(
      'game_settings',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Update game settings
  Future<void> updateGameSettings(
      String userId, Map<String, dynamic> settings) async {
    final db = await database;
    await db.update(
      'game_settings',
      settings,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // ============ GUEST SESSION OPERATIONS ============

  /// Save guest session data (temporary)
  Future<void> saveGuestData(String key, String value) async {
    final db = await database;
    await db.insert(
      'guest_session',
      {
        'key': key,
        'value': value,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get guest session data
  Future<String?> getGuestData(String key) async {
    final db = await database;
    final results = await db.query(
      'guest_session',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  /// Clear all guest session data (called on sign out)
  Future<void> clearGuestData() async {
    final db = await database;
    await db.delete('guest_session');
    await db.delete('game_history', where: 'isGuestGame = 1');
    await db.delete('saved_games', where: 'isGuestGame = 1');
  }

  // ============ SAVED GAMES OPERATIONS ============

  /// Save game for resume later
  Future<int> saveGame({
    required String userId,
    required String gameState,
    required String boardTheme,
    required String timeControl,
    required String currentTurn,
    required bool isGuestGame,
  }) async {
    final db = await database;
    return await db.insert('saved_games', {
      'userId': userId,
      'gameState': gameState,
      'boardTheme': boardTheme,
      'timeControl': timeControl,
      'currentTurn': currentTurn,
      'status': 'in_progress',
      'savedAt': DateTime.now().toIso8601String(),
      'isGuestGame': isGuestGame ? 1 : 0,
    });
  }

  /// Get saved games for user
  Future<List<Map<String, dynamic>>> getSavedGames(String userId) async {
    final db = await database;
    return await db.query(
      'saved_games',
      where: "userId = ? AND status = 'in_progress'",
      whereArgs: [userId],
      orderBy: 'savedAt DESC',
    );
  }

  /// Delete saved game
  Future<void> deleteSavedGame(int gameId) async {
    final db = await database;
    await db.delete('saved_games', where: 'id = ?', whereArgs: [gameId]);
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

/// Provider for DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});
