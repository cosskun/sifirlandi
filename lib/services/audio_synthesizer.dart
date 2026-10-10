import 'dart:math';
import 'dart:typed_data';

/// AudioSynthesizer generates standalone, 100% offline 16-bit PCM WAV audio buffers
/// with zero external asset dependencies.
class AudioSynthesizer {
  static const int sampleRate = 22050;

  static Uint8List createWav(Int16List samples) {
    final int byteLength = samples.length * 2;
    final int totalLength = 44 + byteLength;
    final ByteData header = ByteData(44);

    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, totalLength - 8, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    header.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
    header.setUint16(32, 2, Endian.little); // BlockAlign (NumChannels * BitsPerSample/8)
    header.setUint16(34, 16, Endian.little); // BitsPerSample

    // data sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, byteLength, Endian.little);

    final Uint8List wavBytes = Uint8List(totalLength);
    wavBytes.setRange(0, 44, header.buffer.asUint8List());

    final Uint8List sampleBytes = samples.buffer.asUint8List();
    wavBytes.setRange(44, totalLength, sampleBytes);

    return wavBytes;
  }

  /// Siren (Loud European / Police emergency wail)
  static Uint8List generateSiren() {
    const double duration = 1.3;
    final int numSamples = (sampleRate * duration).toInt();
    final Int16List samples = Int16List(numSamples);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      // Frequency wails smoothly between 600Hz and 1200Hz at 2.2 Hz cycle
      final double freq = 750.0 + 350.0 * sin(2 * pi * 2.2 * t);
      phase += 2 * pi * freq / sampleRate;

      // Soft envelope (fade in at start, fade out at end)
      double envelope = 1.0;
      if (t < 0.05) envelope = t / 0.05;
      if (t > duration - 0.08) envelope = (duration - t) / 0.08;

      final double sampleVal = sin(phase) * 0.75 * envelope;
      samples[i] = (sampleVal * 32767).toInt().clamp(-32768, 32767);
    }

    return createWav(samples);
  }

  /// Sad Trombone (Wah-Wah-Wah-Waaaaah)
  static Uint8List generateSadTrombone() {
    const double duration = 1.6;
    final int numSamples = (sampleRate * duration).toInt();
    final Int16List samples = Int16List(numSamples);

    final List<Map<String, dynamic>> notes = [
      {'freq': 293.66, 'start': 0.0, 'dur': 0.28}, // D4
      {'freq': 277.18, 'start': 0.32, 'dur': 0.28}, // Db4
      {'freq': 261.63, 'start': 0.64, 'dur': 0.28}, // C4
      {'freq': 246.94, 'start': 0.96, 'dur': 0.60, 'slide': true}, // B3 -> slide down
    ];

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double sampleVal = 0.0;

      for (var note in notes) {
        final double nStart = note['start'];
        final double nDur = note['dur'];
        final double baseFreq = note['freq'];
        final bool isSlide = note['slide'] ?? false;

        if (t >= nStart && t < nStart + nDur) {
          final double localT = t - nStart;
          double currentFreq = baseFreq;

          if (isSlide) {
            // Drop pitch down and add brassy vibrato
            currentFreq = baseFreq - (localT / nDur) * 45.0 + 4.0 * sin(2 * pi * 6.0 * localT);
          } else {
            // Muted wah filter vibrato
            currentFreq = baseFreq + 2.5 * sin(2 * pi * 8.0 * localT);
          }

          phase += 2 * pi * currentFreq / sampleRate;

          // Note envelope with brassy harmonics
          double env = 1.0;
          if (localT < 0.04) env = localT / 0.04;
          if (localT > nDur - 0.05) env = (nDur - localT) / 0.05;

          // Fundamental + 2nd + 3rd harmonic for trombone timbre
          final double signal = (sin(phase) + 0.5 * sin(2 * phase) + 0.25 * sin(3 * phase)) / 1.75;
          sampleVal = signal * 0.8 * env;
          break;
        }
      }

      samples[i] = (sampleVal * 32767).toInt().clamp(-32768, 32767);
    }

    return createWav(samples);
  }

  /// Victory / Level Up (Chime Arpeggio C5 -> E5 -> G5 -> C6)
  static Uint8List generateVictory() {
    const double duration = 0.9;
    final int numSamples = (sampleRate * duration).toInt();
    final Int16List samples = Int16List(numSamples);

    final List<Map<String, dynamic>> notes = [
      {'freq': 523.25, 'start': 0.0, 'dur': 0.15}, // C5
      {'freq': 659.25, 'start': 0.14, 'dur': 0.15}, // E5
      {'freq': 783.99, 'start': 0.28, 'dur': 0.18}, // G5
      {'freq': 1046.50, 'start': 0.44, 'dur': 0.44}, // C6
    ];

    double phase = 0.0;
    double harmonicPhase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double sampleVal = 0.0;

      for (var note in notes) {
        final double nStart = note['start'];
        final double nDur = note['dur'];
        final double freq = note['freq'];

        if (t >= nStart && t < nStart + nDur) {
          final double localT = t - nStart;
          phase += 2 * pi * freq / sampleRate;
          harmonicPhase += 2 * pi * (freq * 2) / sampleRate;

          // Bell-like strike decay
          final double env = exp(-3.5 * localT);
          final double signal = sin(phase) + 0.35 * sin(harmonicPhase);
          sampleVal = (signal / 1.35) * 0.8 * env;
          break;
        }
      }

      samples[i] = (sampleVal * 32767).toInt().clamp(-32768, 32767);
    }

    return createWav(samples);
  }

  /// Crash (Metallic impact & shatter)
  static Uint8List generateCrash() {
    const double duration = 0.55;
    final int numSamples = (sampleRate * duration).toInt();
    final Int16List samples = Int16List(numSamples);
    final Random random = Random(42);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double noise = (random.nextDouble() * 2.0 - 1.0);
      final double impact = sin(2 * pi * 120.0 * t) * exp(-18.0 * t);
      final double rattle = sin(2 * pi * 850.0 * t) * exp(-8.0 * t);

      final double env = exp(-6.0 * t);
      final double sampleVal = (noise * 0.5 * env + impact * 0.4 + rattle * 0.3) * 0.85;
      samples[i] = (sampleVal * 32767).toInt().clamp(-32768, 32767);
    }

    return createWav(samples);
  }

  /// Click / Pop (Crisp UI interaction sound)
  static Uint8List generateClick() {
    const double duration = 0.06;
    final int numSamples = (sampleRate * duration).toInt();
    final Int16List samples = Int16List(numSamples);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      // Fast upward pitch sweep
      final double freq = 600.0 + (t / duration) * 900.0;
      phase += 2 * pi * freq / sampleRate;

      final double env = exp(-35.0 * t);
      final double sampleVal = sin(phase) * 0.8 * env;
      samples[i] = (sampleVal * 32767).toInt().clamp(-32768, 32767);
    }

    return createWav(samples);
  }
}
