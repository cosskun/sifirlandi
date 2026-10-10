import 'dart:js_interop';

@JS('window.playSifirlandiSound')
external void _jsPlaySound(JSString effectName);

Future<void> playAudioEffect(String effectName) async {
  try {
    _jsPlaySound(effectName.toJS);
  } catch (_) {
    // Graceful fallback
  }
}
