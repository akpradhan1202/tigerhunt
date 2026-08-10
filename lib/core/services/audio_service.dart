import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound types in the game
enum GameSound {
  // Piece sounds
  move('sounds/move.mp3'),
  capture('sounds/capture.mp3'),
  place('sounds/place.mp3'),
  select('sounds/select.mp3'),

  // Game events
  gameStart('sounds/game_start.mp3'),
  gameWin('sounds/win.mp3'),
  gameLose('sounds/lose.mp3'),
  gameDraw('sounds/draw.mp3'),

  // Timer
  timerWarning('sounds/timer_warning.mp3'),
  timerUrgent('sounds/timer_urgent.mp3'),

  // UI
  buttonTap('sounds/button_tap.mp3'),
  notification('sounds/notification.mp3'),
  achievement('sounds/achievement.mp3'),

  // Ambience (optional)
  backgroundMusic('sounds/background_music.mp3');

  final String path;
  const GameSound(this.path);
}

/// Audio service for managing game sounds
class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();

  AudioService._();

  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.5;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;

  /// Initialize audio service
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _soundVolume = prefs.getDouble('sound_volume') ?? 1.0;
      _musicVolume = prefs.getDouble('music_volume') ?? 0.5;

      await _effectPlayer.setVolume(_soundVolume);
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint('AudioService init error: $e');
    }
  }

  /// Play a sound effect
  Future<void> playSound(GameSound sound) async {
    if (!_soundEnabled) return;

    try {
      await _effectPlayer.stop();
      await _effectPlayer.play(AssetSource(sound.path));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  /// Play background music
  Future<void> playMusic() async {
    if (!_musicEnabled) return;

    try {
      await _musicPlayer.play(AssetSource(GameSound.backgroundMusic.path));
    } catch (e) {
      debugPrint('Error playing music: $e');
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping music: $e');
    }
  }

  /// Pause background music
  Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing music: $e');
    }
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    if (!_musicEnabled) return;

    try {
      await _musicPlayer.resume();
    } catch (e) {
      debugPrint('Error resuming music: $e');
    }
  }

  /// Toggle sound effects
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
  }

  /// Toggle music
  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _musicEnabled);

    if (_musicEnabled) {
      await playMusic();
    } else {
      await stopMusic();
    }
  }

  /// Set sound volume (0.0 - 1.0)
  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    await _effectPlayer.setVolume(_soundVolume);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', _soundVolume);
  }

  /// Set music volume (0.0 - 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', _musicVolume);
  }

  /// Enable sound
  Future<void> enableSound() async {
    _soundEnabled = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', true);
  }

  /// Disable sound
  Future<void> disableSound() async {
    _soundEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', false);
  }

  /// Dispose audio players
  void dispose() {
    _effectPlayer.dispose();
    _musicPlayer.dispose();
  }
}

/// Extension for easy sound playing in widgets
extension GameSoundExtension on GameSound {
  Future<void> play() => AudioService.instance.playSound(this);
}
