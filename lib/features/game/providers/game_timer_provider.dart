import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';

/// Timer state
class TimerState {
  final Duration tigerTime;
  final Duration goatTime;
  final PlayerTurn currentTurn;
  final bool isRunning;
  final bool tigerTimeExpired;
  final bool goatTimeExpired;

  const TimerState({
    required this.tigerTime,
    required this.goatTime,
    required this.currentTurn,
    this.isRunning = false,
    this.tigerTimeExpired = false,
    this.goatTimeExpired = false,
  });

  TimerState copyWith({
    Duration? tigerTime,
    Duration? goatTime,
    PlayerTurn? currentTurn,
    bool? isRunning,
    bool? tigerTimeExpired,
    bool? goatTimeExpired,
  }) {
    return TimerState(
      tigerTime: tigerTime ?? this.tigerTime,
      goatTime: goatTime ?? this.goatTime,
      currentTurn: currentTurn ?? this.currentTurn,
      isRunning: isRunning ?? this.isRunning,
      tigerTimeExpired: tigerTimeExpired ?? this.tigerTimeExpired,
      goatTimeExpired: goatTimeExpired ?? this.goatTimeExpired,
    );
  }

  String get tigerTimeFormatted => _formatDuration(tigerTime);
  String get goatTimeFormatted => _formatDuration(goatTime);

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Game timer notifier
class GameTimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;
  final Duration initialTime;
  final Duration increment;
  final void Function(PlayerTurn)? onTimeExpired;

  GameTimerNotifier({
    required this.initialTime,
    this.increment = Duration.zero,
    this.onTimeExpired,
  }) : super(TimerState(
          tigerTime: initialTime,
          goatTime: initialTime,
          currentTurn: PlayerTurn.goat,
        ));

  /// Start the timer
  void start() {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Pause the timer
  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// Resume the timer
  void resume() {
    if (!state.isRunning && !state.tigerTimeExpired && !state.goatTimeExpired) {
      start();
    }
  }

  /// Add Fischer time increment
  void addIncrement(PlayerTurn player) {
    if (increment == Duration.zero) return;
    if (player == PlayerTurn.tiger) {
      state = state.copyWith(tigerTime: state.tigerTime + increment);
    } else {
      state = state.copyWith(goatTime: state.goatTime + increment);
    }
  }

  /// Switch turn (and optionally apply Fischer increment)
  void switchTurn(PlayerTurn newTurn) {
    state = state.copyWith(currentTurn: newTurn);
  }

  /// Reset timer
  void reset() {
    _timer?.cancel();
    state = TimerState(
      tigerTime: initialTime,
      goatTime: initialTime,
      currentTurn: PlayerTurn.goat,
    );
  }

  /// Tick - decrement current player's time
  void _tick() {
    if (state.currentTurn == PlayerTurn.tiger) {
      final newTime = state.tigerTime - const Duration(seconds: 1);
      if (newTime.inSeconds <= 0) {
        pause();
        state = state.copyWith(
          tigerTime: Duration.zero,
          tigerTimeExpired: true,
        );
        onTimeExpired?.call(PlayerTurn.tiger);
      } else {
        state = state.copyWith(tigerTime: newTime);
      }
    } else {
      final newTime = state.goatTime - const Duration(seconds: 1);
      if (newTime.inSeconds <= 0) {
        pause();
        state = state.copyWith(
          goatTime: Duration.zero,
          goatTimeExpired: true,
        );
        onTimeExpired?.call(PlayerTurn.goat);
      } else {
        state = state.copyWith(goatTime: newTime);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for game timer
final gameTimerProvider = StateNotifierProvider.autoDispose
    .family<GameTimerNotifier, TimerState, GameTimer>((ref, timer) {
  return GameTimerNotifier(
    initialTime: timer.duration,
    increment: timer.increment,
    onTimeExpired: (player) {
      // Handle time expiration
      debugPrint('Time expired for $player');
    },
  );
});
