import 'package:equatable/equatable.dart';
import '../../game/models/game_models.dart';
import '../../game/models/game_state.dart';

/// A completed game record
class GameRecord extends Equatable {
  final String id;
  final DateTime playedAt;
  final BoardLevel level;
  final GameMode mode;
  final GameTimer timer;
  final Duration gameDuration;

  // Players
  final String tigerPlayerId;
  final String tigerPlayerName;
  final int tigerPlayerRating;
  final String goatPlayerId;
  final String goatPlayerName;
  final int goatPlayerRating;

  // Result
  final GameWinner winner;
  final int goatsCaptured;
  final int totalMoves;

  // Move history for replay
  final List<RecordedMove> moves;

  // Rating changes
  final int tigerRatingChange;
  final int goatRatingChange;

  const GameRecord({
    required this.id,
    required this.playedAt,
    required this.level,
    required this.mode,
    required this.timer,
    required this.gameDuration,
    required this.tigerPlayerId,
    required this.tigerPlayerName,
    required this.tigerPlayerRating,
    required this.goatPlayerId,
    required this.goatPlayerName,
    required this.goatPlayerRating,
    required this.winner,
    required this.goatsCaptured,
    required this.totalMoves,
    required this.moves,
    required this.tigerRatingChange,
    required this.goatRatingChange,
  });

  bool didWin(String odStatsId) {
    if (winner == GameWinner.tigers && odStatsId == tigerPlayerId) return true;
    if (winner == GameWinner.goats && odStatsId == goatPlayerId) return true;
    return false;
  }

  String getOpponentName(String odStatsId) {
    return odStatsId == tigerPlayerId ? goatPlayerName : tigerPlayerName;
  }

  PieceType getPlayerRole(String odStatsId) {
    return odStatsId == tigerPlayerId ? PieceType.tiger : PieceType.goat;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'playedAt': playedAt.toIso8601String(),
        'level': level.name,
        'mode': mode.name,
        'timer': timer.minutes,
        'gameDuration': gameDuration.inSeconds,
        'tigerPlayerId': tigerPlayerId,
        'tigerPlayerName': tigerPlayerName,
        'tigerPlayerRating': tigerPlayerRating,
        'goatPlayerId': goatPlayerId,
        'goatPlayerName': goatPlayerName,
        'goatPlayerRating': goatPlayerRating,
        'winner': winner.name,
        'goatsCaptured': goatsCaptured,
        'totalMoves': totalMoves,
        'moves': moves.map((m) => m.toJson()).toList(),
        'tigerRatingChange': tigerRatingChange,
        'goatRatingChange': goatRatingChange,
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      id: json['id'] as String,
      playedAt: DateTime.parse(json['playedAt'] as String),
      level: BoardLevel.values.firstWhere((e) => e.name == json['level']),
      mode: GameMode.values.firstWhere((e) => e.name == json['mode']),
      timer: GameTimer.values.firstWhere((e) => e.minutes == json['timer']),
      gameDuration: Duration(seconds: json['gameDuration'] as int),
      tigerPlayerId: json['tigerPlayerId'] as String,
      tigerPlayerName: json['tigerPlayerName'] as String,
      tigerPlayerRating: json['tigerPlayerRating'] as int,
      goatPlayerId: json['goatPlayerId'] as String,
      goatPlayerName: json['goatPlayerName'] as String,
      goatPlayerRating: json['goatPlayerRating'] as int,
      winner: GameWinner.values.firstWhere((e) => e.name == json['winner']),
      goatsCaptured: json['goatsCaptured'] as int,
      totalMoves: json['totalMoves'] as int,
      moves: (json['moves'] as List)
          .map((m) => RecordedMove.fromJson(m as Map<String, dynamic>))
          .toList(),
      tigerRatingChange: json['tigerRatingChange'] as int,
      goatRatingChange: json['goatRatingChange'] as int,
    );
  }

  @override
  List<Object?> get props => [id];
}

/// A recorded move for replay
class RecordedMove {
  final Position from;
  final Position to;
  final Position? capturedAt;
  final PieceType pieceType;
  final Duration timestamp;

  const RecordedMove({
    required this.from,
    required this.to,
    this.capturedAt,
    required this.pieceType,
    required this.timestamp,
  });

  Move toMove() => Move(
        from: from,
        to: to,
        capturedAt: capturedAt,
        pieceType: pieceType,
      );

  Map<String, dynamic> toJson() => {
        'from': {'row': from.row, 'col': from.col},
        'to': {'row': to.row, 'col': to.col},
        'capturedAt': capturedAt != null
            ? {'row': capturedAt!.row, 'col': capturedAt!.col}
            : null,
        'pieceType': pieceType.name,
        'timestamp': timestamp.inMilliseconds,
      };

  factory RecordedMove.fromJson(Map<String, dynamic> json) {
    return RecordedMove(
      from: Position(
        json['from']['row'] as int,
        json['from']['col'] as int,
      ),
      to: Position(
        json['to']['row'] as int,
        json['to']['col'] as int,
      ),
      capturedAt: json['capturedAt'] != null
          ? Position(
              json['capturedAt']['row'] as int,
              json['capturedAt']['col'] as int,
            )
          : null,
      pieceType: PieceType.values.firstWhere(
        (e) => e.name == json['pieceType'],
      ),
      timestamp: Duration(milliseconds: json['timestamp'] as int),
    );
  }
}
