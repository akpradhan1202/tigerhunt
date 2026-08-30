import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sound engine for non-web platforms (Android, iOS, desktop) backed by
/// `audioplayers`, which plays the bundled asset files.
class AudioEngine {
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  double _volume = 0.6;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(_volume);
    } catch (e) {
      debugPrint('AudioEngine: init error: $e');
    }
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// No-op on mobile - autoplay is not restricted there.
  Future<void> unlock() async {}

  /// Play a bundled asset (path relative to `assets/`, e.g.
  /// `sounds/goat_move.wav`).
  Future<void> play(String assetPath) async {
    await init();
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
      debugPrint('🔊 Native: $assetPath');
    } catch (e) {
      debugPrint('AudioEngine: error playing $assetPath: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
