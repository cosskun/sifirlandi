import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sifirlandi/services/audio_synthesizer.dart';

void main() {
  group('AudioSynthesizer Sound Effects Tests', () {
    void verifyWavHeader(Uint8List wav) {
      expect(wav.length > 44, true);
      // 'RIFF'
      expect(wav[0], 0x52);
      expect(wav[1], 0x49);
      expect(wav[2], 0x46);
      expect(wav[3], 0x46);
      // 'WAVE'
      expect(wav[8], 0x57);
      expect(wav[9], 0x41);
      expect(wav[10], 0x56);
      expect(wav[11], 0x45);
    }

    test('generateSiren creates valid emergency siren WAV', () {
      final wav = AudioSynthesizer.generateSiren();
      verifyWavHeader(wav);
      expect(wav.length, greaterThan(20000));
    });

    test('generateSadTrombone creates valid comedy trombone WAV', () {
      final wav = AudioSynthesizer.generateSadTrombone();
      verifyWavHeader(wav);
      expect(wav.length, greaterThan(25000));
    });

    test('generateVictory creates valid victory fanfare WAV', () {
      final wav = AudioSynthesizer.generateVictory();
      verifyWavHeader(wav);
      expect(wav.length, greaterThan(15000));
    });

    test('generateCrash creates valid crash sound WAV', () {
      final wav = AudioSynthesizer.generateCrash();
      verifyWavHeader(wav);
      expect(wav.length, greaterThan(10000));
    });

    test('generateClick creates valid UI click WAV', () {
      final wav = AudioSynthesizer.generateClick();
      verifyWavHeader(wav);
      expect(wav.length, greaterThan(1000));
    });
  });
}
