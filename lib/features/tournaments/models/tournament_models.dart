import 'package:equatable/equatable.dart';
import '../../game/models/game_models.dart';

/// Tournament format types
enum TournamentFormat {
  knockout('Knockout', 'Single elimination bracket'),
  swiss('Swiss', 'Multiple rounds, paired by score'),
  roundRobin('Round Robin', 'Everyone plays everyone'),
  arena('Arena', 'Play as many games as possible');

  final String name;
  final String description;

  const TournamentFormat(this.name, this.description);
}

/// Tournament status
enum TournamentStatus {
  upcoming,    // Not started yet
  registering, // Open for registration
  inProgress,  // Currently running
  completed,   // Finished
  cancelled,   // Cancelled
}

/// A tournament
class Tournament extends Equatable {
  final String id;
  final String name;
  final String description;
  final TournamentFormat format;
  final TournamentStatus status;
  final BoardLevel boardLevel;
  final GameTimer timeControl;
  final DateTime startTime;
  final DateTime? endTime;
  final int maxPlayers;
  final int currentPlayers;
  final int minRating;
  final int maxRating;
  final List<TournamentPrize> prizes;
  final String createdBy;
  final bool isFeatured;
  final int entryFee; // In points, 0 = free
  final List<String> registeredPlayers;

  const Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.format,
    required this.status,
    required this.boardLevel,
    required this.timeControl,
    required this.startTime,
    this.endTime,
    required this.maxPlayers,
    required this.currentPlayers,
    this.minRating = 0,
    this.maxRating = 9999,
    required this.prizes,
    required this.createdBy,
    this.isFeatured = false,
    this.entryFee = 0,
    this.registeredPlayers = const [],
  });

  bool get isOpen => status == TournamentStatus.registering;
  bool get isFull => currentPlayers >= maxPlayers;
  bool get canRegister => isOpen && !isFull;

  Duration get timeUntilStart => startTime.difference(DateTime.now());
  bool get hasStarted => DateTime.now().isAfter(startTime);

  @override
  List<Object?> get props => [id];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'format': format.name,
        'status': status.name,
        'boardLevel': boardLevel.name,
        'timeControl': timeControl.minutes,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'maxPlayers': maxPlayers,
        'currentPlayers': currentPlayers,
        'minRating': minRating,
        'maxRating': maxRating,
        'prizes': prizes.map((p) => p.toJson()).toList(),
        'createdBy': createdBy,
        'isFeatured': isFeatured,
        'entryFee': entryFee,
        'registeredPlayers': registeredPlayers,
      };

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      format: TournamentFormat.values.firstWhere(
        (e) => e.name == json['format'],
      ),
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      boardLevel: BoardLevel.values.firstWhere(
        (e) => e.name == json['boardLevel'],
      ),
      timeControl: GameTimer.values.firstWhere(
        (e) => e.minutes == json['timeControl'],
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      maxPlayers: json['maxPlayers'] as int,
      currentPlayers: json['currentPlayers'] as int,
      minRating: json['minRating'] as int? ?? 0,
      maxRating: json['maxRating'] as int? ?? 9999,
      prizes: (json['prizes'] as List)
          .map((p) => TournamentPrize.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdBy: json['createdBy'] as String,
      isFeatured: json['isFeatured'] as bool? ?? false,
      entryFee: json['entryFee'] as int? ?? 0,
      registeredPlayers: List<String>.from(json['registeredPlayers'] ?? []),
    );
  }
}

/// Tournament prize
class TournamentPrize {
  final int position;
  final String title;
  final int points;
  final String? badge;

  const TournamentPrize({
    required this.position,
    required this.title,
    required this.points,
    this.badge,
  });

  Map<String, dynamic> toJson() => {
        'position': position,
        'title': title,
        'points': points,
        'badge': badge,
      };

  factory TournamentPrize.fromJson(Map<String, dynamic> json) {
    return TournamentPrize(
      position: json['position'] as int,
      title: json['title'] as String,
      points: json['points'] as int,
      badge: json['badge'] as String?,
    );
  }
}

/// Tournament standings entry
class TournamentStanding {
  final String odStatsId;
  final String playerName;
  final int playerRating;
  final int position;
  final int wins;
  final int losses;
  final int draws;
  final int points;
  final double buchholz; // Tiebreaker

  const TournamentStanding({
    required this.odStatsId,
    required this.playerName,
    required this.playerRating,
    required this.position,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.points,
    this.buchholz = 0,
  });

  int get gamesPlayed => wins + losses + draws;
}

/// A tournament match
class TournamentMatch {
  final String id;
  final String tournamentId;
  final int round;
  final String player1Id;
  final String? player2Id; // Null for bye
  final String? odStatsId;
  final int? player1Score;
  final int? player2Score;
  final String? gameId;
  final DateTime? scheduledTime;
  final bool isCompleted;

  const TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.player1Id,
    this.player2Id,
    this.odStatsId,
    this.player1Score,
    this.player2Score,
    this.gameId,
    this.scheduledTime,
    this.isCompleted = false,
  });

  bool get isBye => player2Id == null;
  bool get hasWinner => odStatsId != null;
}

/// Bracket node for knockout tournaments
class BracketNode {
  final int round;
  final int position;
  final TournamentMatch? match;
  final BracketNode? child1;
  final BracketNode? child2;

  const BracketNode({
    required this.round,
    required this.position,
    this.match,
    this.child1,
    this.child2,
  });
}
