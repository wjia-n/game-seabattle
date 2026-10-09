import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Procedural audio for Sea Battle — all sounds synthesized in code as WAV
/// bytes. No asset files. Cannon booms, splashes, explosions, wooden creaks.
///
/// Reliability design (every call is safe to repeat and safe to overlap):
/// - Music clips are synthesized ONCE and cached; starting music never blocks
///   the UI thread after the first build.
/// - A [_musicGen] generation counter serializes track changes: every
///   start/stop bumps the generation, in-flight work from an older request
///   aborts, and the LATEST request always wins. Music is app-scoped and
///   never silently dies.
/// - Lifecycle uses pause()/resume() so an interruption (call, backgrounding)
///   resumes exactly where it left off instead of restarting or dying.
/// - Every public method catches player errors; audio can never crash the app.
class SeaAudio {
  static const int _rate = 22050;
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  final _rand = Random();

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;

  final Map<String, Uint8List> _cache = {};

  int _musicGen = 0;
  bool _musicBusy = false;
  String? _currentTrack; // 'menu' | 'game' | null
  bool _pausedByLifecycle = false;
  bool _disposed = false;

  SeaAudio() {
    _music.setReleaseMode(ReleaseMode.loop);
  }

  void configure(
      {required bool musicOn, required bool sfxOn, required double volume}) {
    this.musicOn = musicOn;
    this.sfxOn = sfxOn;
    volume = volume.clamp(0.0, 1.0);
    this.volume = volume;
    _music.setVolume(musicOn ? volume * 0.55 : 0.0);
    _sfx.setVolume(sfxOn ? volume : 0.0);
    if (!musicOn) {
      stopMusic();
    }
  }

  /// Pre-build music clips off the critical path. Safe to call any time.
  Future<void> prewarm() async {
    if (_disposed) return;
    await Future(() {});
    _menuBytes();
    _gameBytes();
  }

  // ---------------------------------------------------------- WAV synthesis
  Uint8List _wav(List<double> samples) {
    final n = samples.length;
    final data = ByteData(44 + n * 2);
    void writeStr(int o, String s) {
      for (int i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, _rate, Endian.little);
    data.setUint32(28, _rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (int i = 0; i < n; i++) {
      final v = samples[i].clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  double _env(int i, int n, {double attack = 0.02}) {
    final t = i / n;
    final a = (t / attack).clamp(0.0, 1.0);
    final d = pow(1 - t, 2.2).toDouble();
    return a * d;
  }

  List<double> _tone(double freq, double secs,
      {double freqEnd = 0, double attack = 0.02, double harmonics = 0.25}) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final f = freqEnd > 0 ? freq + (freqEnd - freq) * (i / n) : freq;
      final ph = 2 * pi * f * t;
      out[i] = _env(i, n, attack: attack) *
          (sin(ph) + harmonics * sin(2 * ph) + harmonics * 0.5 * sin(3 * ph));
    }
    return out;
  }

  List<double> _noiseBurst(double secs, double decay,
      {double lowpass = 0.25}) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    double prev = 0;
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final raw = _rand.nextDouble() * 2 - 1;
      prev = prev * (1 - lowpass) + raw * lowpass; // crude low-pass
      out[i] = _env(i, n, attack: 0.004) * prev * exp(-t * decay);
    }
    return out;
  }

  List<double> _cannon() {
    // Deep boom: low sine thump + filtered noise blast.
    final n = (_rate * 0.55).round();
    final out = List<double>.filled(n, 0);
    final boom = _tone(70, 0.55, freqEnd: 38, harmonics: 0.6);
    final blast = _noiseBurst(0.55, 9, lowpass: 0.35);
    for (int i = 0; i < n; i++) {
      out[i] = boom[i] * 0.9 + blast[i] * 0.55;
    }
    return out;
  }

  List<double> _splashSfx() {
    // Watery splatter: bandy noise with a quick pitch-down whistle.
    final n = (_rate * 0.5).round();
    final out = List<double>.filled(n, 0);
    double prev = 0;
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final raw = _rand.nextDouble() * 2 - 1;
      prev = prev * 0.55 + raw * 0.45;
      final whistle = sin(2 * pi * (1400 - 900 * (i / n)) * t) * 0.12;
      out[i] = _env(i, n, attack: 0.01) * (prev * 0.5 + whistle) * exp(-t * 7);
    }
    return out;
  }

  List<double> _explosion() {
    // Ship hit: cannon boom layered with splintering crackle.
    final n = (_rate * 0.9).round();
    final out = List<double>.filled(n, 0);
    final boom = _tone(55, 0.9, freqEnd: 30, harmonics: 0.7);
    final blast = _noiseBurst(0.9, 6, lowpass: 0.4);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final crackle =
          (_rand.nextDouble() * 2 - 1) * exp(-t * 22) * (t < 0.35 ? 1 : 0);
      out[i] = boom[i] + blast[i] * 0.6 + crackle * 0.35;
    }
    return out;
  }

  List<double> _woodCreak() {
    final n = (_rate * 0.22).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final f = 180 + 60 * sin(2 * pi * 9 * t);
      out[i] = _env(i, n, attack: 0.05) *
          (0.6 * sin(2 * pi * f * t) + 0.2 * (_rand.nextDouble() * 2 - 1));
    }
    return out;
  }

  List<double> _arp(List<double> freqs, double noteSecs, double gapSecs) {
    final out = <double>[];
    for (final f in freqs) {
      out.addAll(_tone(f, noteSecs, harmonics: 0.2));
      final gap = List<double>.filled((_rate * gapSecs).round(), 0);
      out.addAll(gap);
    }
    return out;
  }

  List<double> _padChord(List<double> freqs, double secs) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      double v = 0;
      for (final f in freqs) {
        final t = i / _rate;
        v += sin(2 * pi * f * t) + 0.3 * sin(2 * pi * f * 2 * t);
      }
      v /= freqs.length * 1.3;
      final t = i / n;
      final swell = sin(pi * t.clamp(0.0, 1.0));
      out[i] = v * (0.35 + 0.65 * swell);
    }
    return out;
  }

  Uint8List _clip(String key, List<double> Function() build) =>
      _cache.putIfAbsent(key, () => _wav(build()));

  Uint8List _menuBytes() => _clip('music_menu', () {
        // Rolling sea-shanty pads: Dm – Bb – F – C, 16s loop.
        final seq = [
          [146.83, 174.61, 220.0], // Dm
          [116.54, 146.83, 174.61], // Bb
          [174.61, 220.0, 261.63], // F
          [130.81, 164.81, 196.0], // C
        ];
        final out = <double>[];
        for (final chord in seq) {
          out.addAll(_padChord(chord, 4.0));
        }
        return out;
      });

  Uint8List _gameBytes() => _clip('music_game', () {
        // Adventurous horn-like calls over a deep-sea drone, 12s loop.
        final drone = _padChord([98.0, 146.83], 12.0);
        final calls = [293.66, 329.63, 392.0, 440.0, 392.0, 329.63, 293.66, 261.63];
        final n = (_rate * 12).round();
        final out = List<double>.from(drone);
        for (int k = 0; k < calls.length; k++) {
          final start = (n * k / calls.length).round();
          final tone = _tone(calls[k], 0.55, harmonics: 0.4);
          for (int i = 0; i < tone.length && start + i < n; i++) {
            out[start + i] += tone[i] * 0.32;
          }
        }
        return out;
      });

  // ------------------------------------------------------------------ SFX
  Future<void> _play(Uint8List bytes) async {
    if (!sfxOn || _disposed) return;
    try {
      await _sfx.play(BytesSource(bytes));
    } catch (_) {}
  }

  Future<void> click() => _play(_clip('click', () => _tone(1150, 0.06)));
  Future<void> place() => _play(_clip('place', _woodCreak));
  Future<void> cannon() => _play(_clip('cannon', _cannon));
  Future<void> splashSfx() => _play(_clip('splash', _splashSfx));
  Future<void> explosion() => _play(_clip('explosion', _explosion));
  Future<void> invalid() =>
      _play(_clip('invalid', () => _tone(150, 0.16, harmonics: 0.5)));
  Future<void> gameStart() =>
      _play(_clip('start', () => _tone(392, 0.32, freqEnd: 784)));
  Future<void> sunk() => _play(
      _clip('sunk', () => _arp([523.25, 659.25, 783.99], 0.18, 0.03)));
  Future<void> win() => _play(_clip(
      'win', () => _arp([392.0, 523.25, 659.25, 783.99, 1046.5], 0.16, 0.03)));
  Future<void> lose() => _play(
      _clip('lose', () => _arp([329.63, 293.66, 261.63, 196.0], 0.24, 0.05)));

  // ----------------------------------------------------------------- music
  Future<void> _startTrack(String track, Uint8List Function() bytes) async {
    if (_disposed) return;
    final gen = ++_musicGen;
    if (_currentTrack == track && !_pausedByLifecycle) {
      try {
        await _music.resume();
      } catch (_) {}
      return;
    }
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (gen != _musicGen || _disposed || !musicOn) return;
    _musicBusy = true;
    try {
      await _music.stop();
      if (gen != _musicGen || _disposed || !musicOn) return;
      _currentTrack = track;
      _pausedByLifecycle = false;
      await _music.play(BytesSource(bytes()));
    } catch (_) {
      if (gen == _musicGen) _currentTrack = null;
    } finally {
      _musicBusy = false;
    }
  }

  Future<void> startMenuMusic() => _startTrack('menu', _menuBytes);
  Future<void> startGameMusic() => _startTrack('game', _gameBytes);

  /// App-scoped stop: only when the user turns music OFF.
  Future<void> stopMusic() async {
    ++_musicGen;
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (_disposed) return;
    try {
      await _music.stop();
    } catch (_) {}
    _currentTrack = null;
    _pausedByLifecycle = false;
  }

  Future<void> onAppPaused() async {
    if (_disposed || _currentTrack == null) return;
    try {
      await _music.pause();
      _pausedByLifecycle = true;
    } catch (_) {}
  }

  Future<void> onAppResumed() async {
    if (_disposed || !musicOn || !_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    try {
      await _music.resume();
    } catch (_) {
      final track = _currentTrack;
      _currentTrack = null;
      if (track == 'menu') {
        await startMenuMusic();
      } else if (track == 'game') {
        await startGameMusic();
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _sfx.dispose();
      await _music.dispose();
    } catch (_) {}
  }
}
