import 'package:flutter/foundation.dart';

import 'audio_engine_web.dart' if (dart.library.io) 'audio_engine_io.dart' as engine;

/// Sound types in the game
enum GameSound {
  /// A goat is placed or moved (light, cheerful blip)
  goatMove('sounds/goat_move.wav'),

  /// A tiger slides to a new square (low growl)
  tigerMove('sounds/tiger_move.wav'),

  /// A tiger captures a goat (dramatic impact + roar)
  tigerCapture('sounds/tiger_capture.wav'),

  /// A piece is tapped (short tick)
  select('sounds/select.wav'),

  /// A new game begins (rising flourish)
  gameStart('sounds/game_start.wav'),

  /// The player won (ascending arpeggio)
  gameWin('sounds/game_win.wav'),

  /// The player lost (descending arpeggio)
  gameLose('sounds/game_lose.wav'),

  /// Low on time (urgent double beep)
  timerWarning('sounds/timer_warning.wav'),

  /// A UI button is pressed (soft tap)
  buttonTap('sounds/button_tap.wav');

  /// Asset path relative to `assets/`.
  final String? assetPath;

  const GameSound(this.assetPath);
}

/// Audio service for game sounds - works on web and mobile.
///
/// Web uses a Web Audio API engine ([AudioEngine] from `audio_engine_web.dart`)
/// that unlocks the audio context on the first user gesture, so sounds are
/// actually audible despite browser autoplay policies. Native platforms use
/// the `audioplayers` engine (`audio_engine_io.dart`) with bundled assets.
class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();

  AudioService._();

  final engine.AudioEngine _engine = engine.AudioEngine();
  bool _soundEnabled = true;
  bool _initialized = false;

  bool get soundEnabled => _soundEnabled;

  /// Initialize audio (on web this attaches the gesture listeners that
  /// unlock the audio context). Safe to call any number of times.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _engine.init();
      debugPrint('AudioService initialized');
    } catch (e) {
      debugPrint('AudioService init error: $e');
    }
  }

  /// Play a sound effect
  Future<void> playSound(GameSound sound) async {
    if (!_soundEnabled) return;
    try {
      await init();
      final assetPath = sound.assetPath!;
      // On web, play straight from the served asset URL; elsewhere use the
      // bundled asset.
      if (kIsWeb) {
        await _engine.play('/assets/assets/$assetPath');
      } else {
        await _engine.play(assetPath);
      }
    } catch (e) {
      debugPrint('AudioService error playing $sound: $e');
    }
  }

  /// Toggle sound effects
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    debugPrint('Sound ${_soundEnabled ? "enabled" : "disabled"}');
  }

  /// Enable sound
  void enableSound() {
    _soundEnabled = true;
  }

  /// Disable sound
  void disableSound() {
    _soundEnabled = false;
  }

  /// Dispose audio engine
  Future<void> dispose() async {
    await _engine.dispose();
  }
}

/// Extension for easy sound playing
extension GameSoundExtension on GameSound {
  Future<void> play() => AudioService.instance.playSound(this);
}
