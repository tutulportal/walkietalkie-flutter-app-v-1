import 'dart:math';
import 'dart:typed_data';

/// Pure Dart procedural audio generator that synthesizes realistic walkie-talkie
/// audio effects: PTT clicks, Roger beeps, Squelch tails, Call chimes, and Radio static.
class SoundGenerator {
  static const int sampleRate = 44100;

  /// Synthesizes a PTT Press Tactical Chirp (Motorola/Baofeng style)
  static Uint8List createPttPressChirp() {
    final samples = <int>[];

    // 1. Initial mechanical switch transient (sharp click, 4ms)
    final clickCount = (sampleRate * 0.004).toInt();
    final random = Random(42);
    for (int i = 0; i < clickCount; i++) {
      final env = 1.0 - (i / clickCount);
      final noise = (random.nextDouble() * 2 - 1) * 0.7;
      samples.add((noise * env * 32767).toInt());
    }

    // 2. High-tech radio key chirp (frequency sweep 1300Hz -> 2500Hz, 35ms)
    final chirpDuration = 0.038;
    final chirpCount = (sampleRate * chirpDuration).toInt();
    double phase = 0.0;
    for (int i = 0; i < chirpCount; i++) {
      final t = i / chirpCount;
      // Frequency ramps up
      final freq = 1300.0 + (1200.0 * t);
      phase += 2.0 * pi * freq / sampleRate;

      // ADSR envelope
      double env;
      if (t < 0.1) {
        env = t / 0.1;
      } else if (t > 0.8) {
        env = (1.0 - t) / 0.2;
      } else {
        env = 1.0;
      }

      final sample = sin(phase) * env * 0.65;
      samples.add((sample * 32767).clamp(-32768, 32767).toInt());
    }

    return _buildWav(samples);
  }

  /// Synthesizes a Roger Beep based on style
  static Uint8List createRogerBeep(String style) {
    switch (style.toUpperCase()) {
      case 'BAOFENG':
        return _createToneBeep(1050, 0.09, volume: 0.7);

      case 'NASA_QUINDAR':
        // Iconic Apollo Quindar tone (2525 Hz)
        return _createToneBeep(2525, 0.065, volume: 0.6);

      case 'KENWOOD_DUAL':
        // 2-Tone chirp: 1250 Hz (35ms) -> 1750 Hz (40ms)
        return _createMultiToneBeep([
          ToneSpec(freq: 1250, durationSec: 0.035, volume: 0.7),
          ToneSpec(freq: 1750, durationSec: 0.045, volume: 0.75),
        ]);

      case 'MILITARY_TRIAD':
        // 3-Tone military beep: 880Hz -> 1175Hz -> 1760Hz
        return _createMultiToneBeep([
          ToneSpec(freq: 880, durationSec: 0.03, volume: 0.6),
          ToneSpec(freq: 1175, durationSec: 0.03, volume: 0.65),
          ToneSpec(freq: 1760, durationSec: 0.045, volume: 0.7),
        ]);

      case 'STANDARD':
      default:
        // Classic Motorola chirp: 1400Hz followed by 1800Hz
        return _createMultiToneBeep([
          ToneSpec(freq: 1400, durationSec: 0.04, volume: 0.7),
          ToneSpec(freq: 1850, durationSec: 0.05, volume: 0.75),
        ]);
    }
  }

  /// Synthesizes the iconic Squelch Tail static burst ("KRRSSSH-TCHK")
  /// Heard when a remote transmission terminates abruptly.
  static Uint8List createSquelchTail() {
    final samples = <int>[];
    final random = Random(1234);

    // Static burst duration: 110ms
    final burstCount = (sampleRate * 0.11).toInt();

    // Simple 1-pole low-pass and high-pass filter state to simulate RF FM discriminator noise
    double lowPass = 0.0;
    double highPass = 0.0;

    for (int i = 0; i < burstCount; i++) {
      final t = i / burstCount;
      final rawNoise = (random.nextDouble() * 2 - 1);

      // Bandpass shaping: approx 350Hz - 3400Hz voice band radio static
      lowPass += 0.28 * (rawNoise - lowPass);
      highPass += 0.08 * (lowPass - highPass);
      final bandpassed = lowPass - highPass;

      // Envelope: punchy onset, slightly decaying, then abrupt squelch cutoff
      double env;
      if (t < 0.05) {
        env = t / 0.05;
      } else if (t > 0.85) {
        env = (1.0 - t) / 0.15;
      } else {
        env = 0.95 - (t * 0.2);
      }

      // Add a touch of crackle
      final crackle = (random.nextDouble() > 0.96) ? (random.nextDouble() * 2 - 1) * 0.5 : 0.0;
      final val = (bandpassed + crackle) * env * 0.85;

      samples.add((val * 32767).clamp(-32768, 32767).toInt());
    }

    // Abrupt switch closure "tchk" at the end (8ms)
    final tchkCount = (sampleRate * 0.008).toInt();
    for (int i = 0; i < tchkCount; i++) {
      final env = 1.0 - (i / tchkCount);
      final click = sin(2 * pi * 800 * i / sampleRate) * env * 0.5;
      samples.add((click * 32767).toInt());
    }

    return _buildWav(samples);
  }

  /// Synthesizes continuous radio background static loop (used for MONI squelch open)
  static Uint8List createRadioStaticLoop({double durationSec = 1.5}) {
    final samples = <int>[];
    final count = (sampleRate * durationSec).toInt();
    final random = Random(777);

    double lp = 0.0;
    double hp = 0.0;

    for (int i = 0; i < count; i++) {
      final raw = (random.nextDouble() * 2 - 1);
      lp += 0.22 * (raw - lp);
      hp += 0.05 * (lp - hp);
      final filtered = (lp - hp) * 0.5;

      // Gentle fade in and fade out so it can loop seamlessly
      double edge = 1.0;
      if (i < 500) edge = i / 500;
      if (i > count - 500) edge = (count - i) / 500;

      samples.add((filtered * edge * 32767).clamp(-32768, 32767).toInt());
    }

    return _buildWav(samples);
  }

  /// Synthesizes Call Tone alert (Motorola 1750 Hz / alternating 2-tone alarm chime)
  static Uint8List createCallAlert() {
    final samples = <int>[];
    final bursts = [
      ToneSpec(freq: 853, durationSec: 0.12, volume: 0.8),
      ToneSpec(freq: 960, durationSec: 0.12, volume: 0.8),
      ToneSpec(freq: 853, durationSec: 0.12, volume: 0.8),
      ToneSpec(freq: 960, durationSec: 0.18, volume: 0.85),
    ];

    for (final tone in bursts) {
      final count = (sampleRate * tone.durationSec).toInt();
      for (int i = 0; i < count; i++) {
        final t = i / count;
        // Envelope with soft attack/decay
        double env = 1.0;
        if (t < 0.08) env = t / 0.08;
        if (t > 0.90) env = (1.0 - t) / 0.10;

        final sample = sin(2 * pi * tone.freq * i / sampleRate) * env * tone.volume;
        samples.add((sample * 32767).clamp(-32768, 32767).toInt());
      }
    }

    return _buildWav(samples);
  }

  /// Synthesizes mechanical rotary knob click sound
  static Uint8List createKnobClick() {
    final samples = <int>[];
    final count = (sampleRate * 0.012).toInt(); // 12ms click

    for (int i = 0; i < count; i++) {
      final env = pow(1.0 - (i / count), 2.5);
      // High-frequency resonant impulse
      final s = sin(2 * pi * 3200 * i / sampleRate) * 0.7 * env;
      samples.add((s * 32767).toInt());
    }

    return _buildWav(samples);
  }

  // --- Helper methods ---

  static Uint8List _createToneBeep(double freq, double durationSec, {double volume = 0.7}) {
    final samples = <int>[];
    final count = (sampleRate * durationSec).toInt();

    for (int i = 0; i < count; i++) {
      final t = i / count;
      double env = 1.0;
      if (t < 0.08) env = t / 0.08;
      if (t > 0.85) env = (1.0 - t) / 0.15;

      final s = sin(2 * pi * freq * i / sampleRate) * env * volume;
      samples.add((s * 32767).clamp(-32768, 32767).toInt());
    }

    return _buildWav(samples);
  }

  static Uint8List _createMultiToneBeep(List<ToneSpec> tones) {
    final samples = <int>[];

    for (final tone in tones) {
      final count = (sampleRate * tone.durationSec).toInt();
      for (int i = 0; i < count; i++) {
        final t = i / count;
        double env = 1.0;
        if (t < 0.06) env = t / 0.06;
        if (t > 0.90) env = (1.0 - t) / 0.10;

        final s = sin(2 * pi * tone.freq * i / sampleRate) * env * tone.volume;
        samples.add((s * 32767).clamp(-32768, 32767).toInt());
      }
    }

    return _buildWav(samples);
  }

  /// Packs 16-bit mono PCM samples into a valid canonical RIFF WAV container
  static Uint8List _buildWav(List<int> samples) {
    final byteData = ByteData(44 + (samples.length * 2));

    // "RIFF"
    byteData.setUint8(0, 0x52);
    byteData.setUint8(1, 0x49);
    byteData.setUint8(2, 0x46);
    byteData.setUint8(3, 0x46);

    // File size - 8
    final totalSize = 36 + (samples.length * 2);
    byteData.setUint32(4, totalSize, Endian.little);

    // "WAVE"
    byteData.setUint8(8, 0x57);
    byteData.setUint8(9, 0x41);
    byteData.setUint8(10, 0x56);
    byteData.setUint8(11, 0x45);

    // "fmt "
    byteData.setUint8(12, 0x66);
    byteData.setUint8(13, 0x6D);
    byteData.setUint8(14, 0x74);
    byteData.setUint8(15, 0x20);

    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    byteData.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * 1 * 16/8)
    byteData.setUint16(32, 2, Endian.little);  // BlockAlign (1 * 16/8)
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)

    // "data"
    byteData.setUint8(36, 0x64);
    byteData.setUint8(37, 0x61);
    byteData.setUint8(38, 0x74);
    byteData.setUint8(39, 0x61);

    byteData.setUint32(40, samples.length * 2, Endian.little); // Data size

    int offset = 44;
    for (final sample in samples) {
      byteData.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  /// Wraps raw 16-bit PCM byte data into a playable RIFF WAV byte array
  static Uint8List createWavFromPcm16(Uint8List pcmBytes, {int sampleRate = 16000}) {
    final byteData = ByteData(44 + pcmBytes.length);

    // "RIFF"
    byteData.setUint8(0, 0x52);
    byteData.setUint8(1, 0x49);
    byteData.setUint8(2, 0x46);
    byteData.setUint8(3, 0x46);
    byteData.setUint32(4, 36 + pcmBytes.length, Endian.little);

    // "WAVE"
    byteData.setUint8(8, 0x57);
    byteData.setUint8(9, 0x41);
    byteData.setUint8(10, 0x56);
    byteData.setUint8(11, 0x45);

    // "fmt "
    byteData.setUint8(12, 0x66);
    byteData.setUint8(13, 0x6D);
    byteData.setUint8(14, 0x74);
    byteData.setUint8(15, 0x20);

    byteData.setUint32(16, 16, Endian.little); // PCM subchunk size
    byteData.setUint16(20, 1, Endian.little);  // Format = PCM
    byteData.setUint16(22, 1, Endian.little);  // Channels = Mono
    byteData.setUint32(24, sampleRate, Endian.little); // 16000 Hz
    byteData.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
    byteData.setUint16(32, 2, Endian.little);  // Block align
    byteData.setUint16(34, 16, Endian.little); // Bits per sample

    // "data"
    byteData.setUint8(36, 0x64);
    byteData.setUint8(37, 0x61);
    byteData.setUint8(38, 0x74);
    byteData.setUint8(39, 0x61);
    byteData.setUint32(40, pcmBytes.length, Endian.little);

    final out = Uint8List(44 + pcmBytes.length);
    out.setRange(0, 44, byteData.buffer.asUint8List());
    out.setRange(44, 44 + pcmBytes.length, pcmBytes);
    return out;
  }
}

class ToneSpec {
  final double freq;
  final double durationSec;
  final double volume;

  const ToneSpec({
    required this.freq,
    required this.durationSec,
    this.volume = 0.7,
  });
}
