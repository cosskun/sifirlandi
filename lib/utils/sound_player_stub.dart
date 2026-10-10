import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../services/audio_synthesizer.dart';

AudioPlayer? _player;
final Map<String, Uint8List> _soundCache = {};

void _ensureCache() {
  if (_soundCache.isNotEmpty) return;
  _soundCache['siren'] = AudioSynthesizer.generateSiren();
  _soundCache['sadTrombone'] = AudioSynthesizer.generateSadTrombone();
  _soundCache['victory'] = AudioSynthesizer.generateVictory();
  _soundCache['crash'] = AudioSynthesizer.generateCrash();
  _soundCache['click'] = AudioSynthesizer.generateClick();
}

AudioPlayer _getPlayer() {
  _player ??= AudioPlayer();
  return _player!;
}

Future<void> playAudioEffect(String effectName) async {
  try {
    _ensureCache();
    final bytes = _soundCache[effectName] ?? _soundCache['click']!;
    final player = _getPlayer();
    await player.stop();
    await player.play(BytesSource(bytes), volume: 1.0);
  } catch (e) {
    // Fallback to system feedback if hardware audio device is unavailable
    if (effectName == 'siren' || effectName == 'crash' || effectName == 'sadTrombone') {
      SystemSound.play(SystemSoundType.alert);
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }
}
