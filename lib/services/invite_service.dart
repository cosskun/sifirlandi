import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteService {
  static const String appBaseUrl = "https://sifirlandi.web.app";

  /// Generates the direct invite URL
  static String generateInviteLink(String roomCode) {
    return "$appBaseUrl/?join=$roomCode";
  }

  /// Generates the formatted text for WhatsApp and social sharing
  static String generateShareMessage({
    required String counterTitle,
    required String roomCode,
    String lang = 'tr',
  }) {
    final link = generateInviteLink(roomCode);
    if (lang == 'tr') {
      return """🚨 SIFIRLANDI! - Ortak Sayaç Daveti

"$counterTitle" ortak sayacımıza katılman için davet edildin!
Kim ne zaman sıfırladı canlı takip et, bildirimleri al ve laf sokma yarışına katıl! 🍿

🔑 Oda Kodu: $roomCode
📲 Doğrudan Katılma Linki: $link

Linke dokunarak veya uygulamada kodu girerek aramıza katılabilirsin! 🔥""";
    } else {
      return """🚨 RESETED! - Shared Counter Invite

You are invited to join the "$counterTitle" shared counter!

🔑 Room Code: $roomCode
📲 Join Link: $link

Tap the link or enter the code to join now! 🔥""";
    }
  }

  /// Share directly to WhatsApp or native share sheet
  static Future<void> shareToWhatsApp({
    required String counterTitle,
    required String roomCode,
    String lang = 'tr',
  }) async {
    final message = generateShareMessage(
      counterTitle: counterTitle,
      roomCode: roomCode,
      lang: lang,
    );

    // Try direct WhatsApp URL scheme first
    final encoded = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse("whatsapp://send?text=$encoded");
    final whatsappWebUri = Uri.parse("https://api.whatsapp.com/send?text=$encoded");

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(whatsappWebUri)) {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback to SharePlus native sheet
    await Share.share(message, subject: "Sıfırlandı! Ortak Sayaç Daveti");
  }

  /// Copy link to clipboard
  static Future<void> copyLink({
    required String roomCode,
  }) async {
    final link = generateInviteLink(roomCode);
    await Clipboard.setData(ClipboardData(text: link));
  }

  /// Copy full invite message to clipboard
  static Future<void> copyFullInvite({
    required String counterTitle,
    required String roomCode,
    String lang = 'tr',
  }) async {
    final message = generateShareMessage(
      counterTitle: counterTitle,
      roomCode: roomCode,
      lang: lang,
    );
    await Clipboard.setData(ClipboardData(text: message));
  }
}
