// Generates the game's WAV sound assets (16-bit PCM mono, 44.1 kHz).
//
// Run from the project root:
//   dart run tool/gen_sounds.dart
//
// Sounds:
//   goat_move.wav     - light, cheerful rising blip when a goat moves/places
//   tiger_move.wav    - low, rumbling growl when a tiger moves
//   tiger_capture.wav - dramatic impact + descending roar when a tiger captures
//   select.wav        - short tick when a piece is selected
//   button_tap.wav    - soft tap for UI buttons
//   game_start.wav    - rising flourish when a game begins
//   game_win.wav      - ascending major arpeggio
//   game_lose.wav     - descending minor arpeggio
//   timer_warning.wav - urgent double beep when time runs low
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data' show BytesBuilder;

const int sampleRate = 44100;
const String outDir = 'assets/sounds';

void main() {
  Directory(outDir).createSync(recursive: true);

  _writeWav('goat_move.wav', _goatMove());
  _writeWav('tiger_move.wav', _tigerMove());
  _writeWav('tiger_capture.wav', _tigerCapture());
  _writeWav('select.wav', _tone(1200, 0.06, amp: 0.35));
  _writeWav('button_tap.wav', _tone(800, 0.05, amp: 0.3));
  _writeWav('game_start.wav', _gameStart());
  _writeWav('game_win.wav', _arpeggio(const [523.25, 659.25, 783.99, 1046.5], 0.8));
  _writeWav('game_lose.wav', _arpeggio(const [523.25, 415.30, 349.23], 0.8, gap: 0.14));
  _writeWav('timer_warning.wav', _doubleBeep());

  stdout.writeln('Generated 9 sound files in $outDir');
}

/// Render a list of floating-point samples (-1..1) to a WAV file.
void _writeWav(String name, List<double> samples) {
  final bytes = BytesBuilder();
  final dataSize = samples.length * 2;

  void writeAscii(String s) => bytes.add(s.codeUnits);

  // RIFF header
  writeAscii('RIFF');
  _writeUint32(bytes, 36 + dataSize);
  writeAscii('WAVE');
  // fmt chunk
  writeAscii('fmt ');
  _writeUint32(bytes, 16);
  _writeUint16(bytes, 1); // PCM
  _writeUint16(bytes, 1); // mono
  _writeUint32(bytes, sampleRate);
  _writeUint32(bytes, sampleRate * 2); // byte rate
  _writeUint16(bytes, 2); // block align
  _writeUint16(bytes, 16); // bits per sample
  // data chunk
  writeAscii('data');
  _writeUint32(bytes, dataSize);
  for (final s in samples) {
    final clamped = s.clamp(-1.0, 1.0);
    _writeInt16(bytes, (clamped * 32767).round());
  }

  File('$outDir/$name').writeAsBytesSync(bytes.toBytes());
  stdout.writeln('  $name (${(samples.length / sampleRate * 1000).round()} ms)');
}

void _writeUint16(BytesBuilder b, int v) {
  b.addByte(v & 0xFF);
  b.addByte((v >> 8) & 0xFF);
}

void _writeUint32(BytesBuilder b, int v) {
  b.addByte(v & 0xFF);
  b.addByte((v >> 8) & 0xFF);
  b.addByte((v >> 16) & 0xFF);
  b.addByte((v >> 24) & 0xFF);
}

void _writeInt16(BytesBuilder b, int v) {
  b.addByte(v & 0xFF);
  b.addByte((v >> 8) & 0xFF);
}

/// Amplitude envelope with quick attack and exponential-ish decay.
double _envelope(double t, double dur, {double attack = 0.01}) {
  final a = (t / attack).clamp(0.0, 1.0);
  final decay = math.pow(1.0 - t / dur, 1.5).toDouble();
  return a * decay;
}

/// A single sine tone with a soft envelope.
List<double> _tone(double freq, double dur, {double amp = 0.4}) {
  final n = (dur * sampleRate).round();
  final out = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    out[i] = amp * math.sin(2 * math.pi * freq * t) * _envelope(t, dur);
  }
  return out;
}

/// A quick sequence of tones (an arpeggio / fanfare).
List<double> _arpeggio(List<double> freqs, double dur, {double gap = 0.12}) {
  final out = <double>[];
  final noteDur = dur / freqs.length - gap;
  for (final f in freqs) {
    out.addAll(_tone(f, noteDur, amp: 0.4));
    out.addAll(List.filled((gap * sampleRate).round(), 0));
  }
  return out;
}

/// Two urgent beeps for the timer warning.
List<double> _doubleBeep() {
  final beep = _tone(1000, 0.12, amp: 0.45);
  final silence = List.filled((0.09 * sampleRate).round(), 0.0);
  return [...beep, ...silence, ..._tone(1000, 0.2, amp: 0.45)];
}

/// Rising two-note flourish for game start.
List<double> _gameStart() {
  final out = <double>[];
  out.addAll(_tone(392.0, 0.18, amp: 0.35)); // G4
  out.addAll(List.filled((0.05 * sampleRate).round(), 0.0));
  out.addAll(_tone(523.25, 0.18, amp: 0.35)); // C5
  out.addAll(List.filled((0.05 * sampleRate).round(), 0.0));
  out.addAll(_tone(659.25, 0.3, amp: 0.4)); // E5
  return out;
}

/// Goat move: light rising blip.
List<double> _goatMove() {
  const dur = 0.18;
  final n = (dur * sampleRate).round();
  final out = List<double>.filled(n, 0);
  final rng = math.Random(7);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    // Rising pitch 700 -> 1050 Hz with a touch of vibrato.
    final phase = 2 * math.pi * (700 * t + (350 * t * t) / (2 * dur));
    final tone = 0.8 * math.sin(phase) + 0.16 * math.sin(2 * phase);
    final noise = (rng.nextDouble() * 2 - 1) * 0.03;
    out[i] = (tone + noise) * _envelope(t, dur, attack: 0.008);
  }
  return out;
}

/// Tiger move: low, rumbling descending growl.
List<double> _tigerMove() {
  const dur = 0.4;
  final n = (dur * sampleRate).round();
  final out = List<double>.filled(n, 0);
  final rng = math.Random(13);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    // Descending 170 -> 100 Hz with wobble.
    final phase = 2 * math.pi * (170 * t - (70 * t * t) / (2 * dur));
    // Sawtooth-ish via harmonics for a rough growl.
    var tone = 0.0;
    for (var h = 1; h <= 5; h++) {
      tone += math.sin(h * phase) / h;
    }
    tone *= 0.55;
    final noise = (rng.nextDouble() * 2 - 1) * 0.1 * (1 - t / dur);
    out[i] = (tone + noise) * _envelope(t, dur, attack: 0.02);
  }
  return out;
}

/// Tiger captures a goat: impact thump + dramatic descending roar.
List<double> _tigerCapture() {
  const dur = 1.1;
  final n = (dur * sampleRate).round();
  final out = List<double>.filled(n, 0);
  final rng = math.Random(29);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;

    // Low impact thump at t=0 (decaying 85 Hz thud).
    final thump = t < 0.25
        ? math.sin(2 * math.pi * 85 * t) * math.pow(1 - t / 0.25, 2).toDouble()
        : 0.0;

    // Descending roar sweep 480 -> 60 Hz, most energy after the thump.
    const sweepStart = 0.04;
    const sweepDur = 0.75;
    var sweep = 0.0;
    if (t > sweepStart && t < sweepStart + sweepDur) {
      final st = t - sweepStart;
      final phase = 2 * math.pi * (480 * st - (420 * st * st) / (2 * sweepDur));
      sweep = 0.6 * math.sin(phase) + 0.2 * math.sin(2 * phase) + 0.08 * math.sin(3 * phase);
      sweep *= math.pow(1 - st / sweepDur, 1.2).toDouble();
    }

    // Sparse crackle during the sweep for drama.
    final crackle = (rng.nextDouble() * 2 - 1) * 0.04 *
        (t > 0.05 && t < 0.8 ? 1.0 : 0.0) * (1 - t / 0.8);

    // Tail rumble.
    final tail = t > 0.8
        ? math.sin(2 * math.pi * 55 * t) * math.pow((1 - t) / 0.2, 1.5).toDouble() * 0.25
        : 0.0;

    // Balanced so the peak stays well under clipping.
    out[i] = (thump * 0.55 + sweep * 0.8 + crackle + tail) * _envelope(t, dur, attack: 0.004);
  }
  return out;
}
