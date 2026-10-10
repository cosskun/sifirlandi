import 'web_downloader_stub.dart' if (dart.library.js_interop) 'web_downloader_web.dart';

void downloadFileOnWeb(String base64Str, String fileName) {
  triggerWebDownload(base64Str, fileName);
}
