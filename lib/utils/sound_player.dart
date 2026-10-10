import 'sound_player_stub.dart' if (dart.library.js_interop) 'sound_player_web.dart' as impl;

Future<void> playAudioEffect(String effectName) async {
  await impl.playAudioEffect(effectName);
}
