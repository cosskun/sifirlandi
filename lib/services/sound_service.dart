import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/sound_player.dart';

enum SoundEffect {
  siren,
  crash,
  sadTrombone,
  victory,
  click,
}

class SoundService {
  static const String _soundPrefKey = 'sound_effects_enabled';
  static bool _isSoundEnabled = true;
  static bool _initialized = false;

  static bool get isSoundEnabled => _isSoundEnabled;

  static Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool(_soundPrefKey) ?? true;
    _initialized = true;
  }

  static Future<void> toggleSound() async {
    _isSoundEnabled = !_isSoundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundPrefKey, _isSoundEnabled);
  }

  static Future<void> play(SoundEffect effect) async {
    if (!_isSoundEnabled) return;

    // Haptic feedback for tactile satisfaction
    switch (effect) {
      case SoundEffect.siren:
      case SoundEffect.crash:
        HapticFeedback.heavyImpact();
        break;
      case SoundEffect.sadTrombone:
        HapticFeedback.vibrate();
        break;
      case SoundEffect.victory:
        HapticFeedback.mediumImpact();
        break;
      case SoundEffect.click:
        HapticFeedback.lightImpact();
        break;
    }

    // Play platform audio
    try {
      await playAudioEffect(effect.name);
    } catch (_) {
      // Graceful ignore
    }
  }
}
