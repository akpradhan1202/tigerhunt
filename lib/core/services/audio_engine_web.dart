import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web Audio API based sound engine.
///
/// Browsers block audible playback until the page has received a user
/// gesture. Plain `<audio>`-element playback often fails here because the
/// async `stop()`/`play()` chain loses the gesture token, so the file loads
/// but nothing is heard. This engine instead:
///
///  - creates the [web.AudioContext] eagerly (harmless; it starts suspended),
///  - resumes it from a window-level `pointerdown`/`mousedown`/`touchstart`/
///    `keydown`/`click` listener on the first user gesture, and plays a
///    one-sample silent buffer inside that gesture (required by iOS Safari
///    to fully "activate" the context),
///  - pre-decodes every sound into an [web.AudioBuffer] (cached), and
///  - plays each sound instantly through an `AudioBufferSourceNode`, which is
///    not subject to the media-element autoplay restrictions once the
///    context is running.
class AudioEngine {
  web.AudioContext? _context;
  final Map<String, web.AudioBuffer> _buffers = {};
  final Map<String, Future<web.AudioBuffer>> _loading = {};
  double _volume = 1.0;
  bool _listenersAttached = false;
  bool _unlocking = false;
  bool _unlocked = false;

  Future<void> init() async {
    if (_listenersAttached) return;
    _listenersAttached = true;
    // Create the context now so the first sound has nothing to wait for;
    // browsers start it in the "suspended" state until a gesture resumes it.
    _ensureContext();
    // Unlock (resume + silent kick) on the first user gesture.
    final unlockCallback = ((web.Event _) {
      unawaited(_unlock());
    }).toJS;
    for (final type in [
      'pointerdown',
      'mousedown',
      'touchstart',
      'keydown',
      'click',
    ]) {
      web.window.addEventListener(type, unlockCallback);
    }
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  web.AudioContext _ensureContext() {
    return _context ??= web.AudioContext();
  }

  /// Ensure the audio context exists and is running. Must run inside (or
  /// after) a user gesture the first time, otherwise the browser keeps the
  /// context suspended.
  Future<void> _unlock() async {
    if (_unlocked) return;
    if (_unlocking) return;
    _unlocking = true;
    try {
      final ctx = _ensureContext();
      if (ctx.state == 'suspended') {
        await ctx.resume().toDart;
      }
      // iOS Safari requires a sound to actually start inside the gesture;
      // a one-sample silent buffer is enough to activate the context.
      if (ctx.state == 'running') {
        _silentKick(ctx);
      }
      _unlocked = true;
      debugPrint('AudioEngine: context unlocked (${ctx.state})');
    } catch (e) {
      debugPrint('AudioEngine: unlock failed: $e');
    } finally {
      _unlocking = false;
    }
  }

  /// Start a one-sample silent buffer so the browser marks the context as
  /// user-activated (iOS requirement). Never throws.
  void _silentKick(web.AudioContext ctx) {
    try {
      final source = ctx.createBufferSource();
      final buffer = ctx.createBuffer(1, 1, 22050);
      source.buffer = buffer;
      source.connect(ctx.destination);
      source.start();
    } catch (_) {
      // Ignore: purely a browser-compatibility nudge.
    }
  }

  Future<web.AudioBuffer> _bufferFor(String url) async {
    final cached = _buffers[url];
    if (cached != null) return cached;
    final inFlight = _loading[url];
    if (inFlight != null) return inFlight;
    final future = _loadAndDecode(url);
    _loading[url] = future;
    final buffer = await future;
    _buffers[url] = buffer;
    _loading.remove(url);
    return buffer;
  }

  Future<web.AudioBuffer> _loadAndDecode(String url) async {
    final response = await web.window.fetch(url.toJS).toDart;
    if (!response.ok) {
      throw StateError('Failed to load $url (${response.status})');
    }
    final data = await response.arrayBuffer().toDart;
    final ctx = _ensureContext();
    return await ctx.decodeAudioData(data).toDart;
  }

  /// Play a sound file (already-decoded buffers replay instantly).
  Future<void> play(String url) async {
    final ctx = _ensureContext();
    // If a gesture never unlocked us yet, try once more now.
    if (ctx.state == 'suspended') {
      await _unlock();
    }
    try {
      final buffer = await _bufferFor(url);
      final source = ctx.createBufferSource();
      source.buffer = buffer;
      final gain = ctx.createGain();
      gain.gain.value = _volume;
      source.connect(gain);
      gain.connect(ctx.destination);
      source.start();
      debugPrint('🔊 WebAudio: $url');
    } catch (e) {
      debugPrint('AudioEngine: error playing $url: $e');
    }
  }

  Future<void> dispose() async {
    // Nothing to dispose that outlives the page; let GC handle it.
  }
}
