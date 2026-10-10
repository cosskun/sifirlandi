import 'dart:js_interop';

@JS('downloadFileFromBytes')
external void downloadFileFromBytes(JSString base64Str, JSString fileName);

void triggerWebDownload(String base64Str, String fileName) {
  downloadFileFromBytes(base64Str.toJS, fileName.toJS);
}
