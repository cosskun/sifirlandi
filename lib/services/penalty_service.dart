import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/penalty_item.dart';

class PenaltyService {
  static const String _prefKey = 'custom_user_penalties';
  static final Random _random = Random();

  static final List<PenaltyItem> defaultPenalties = [
    const PenaltyItem(
      id: 'p1',
      title: 'Gruba Kahve Ismarla',
      emoji: '☕',
      description: 'Gruptaki herkese sıradaki buluşmada veya online kahve ısmarla!',
    ),
    const PenaltyItem(
      id: 'p2',
      title: 'Sıradaki Yemek Hesabı',
      emoji: '🍕',
      description: 'Sıradaki toplu yemekte veya siparişte tatlıları/hesabı sen öde!',
    ),
    const PenaltyItem(
      id: 'p3',
      title: '10 Şınav Çek & Video At',
      emoji: '💪',
      description: 'Hemen 10 şınav çek ve grubun sohbetine kanıt videosu gönder!',
    ),
    const PenaltyItem(
      id: 'p4',
      title: 'Rezil Hikaye Paylaş',
      emoji: '📸',
      description: 'Instagram/WhatsApp hikayene komik bir fotoğrafını 24 saatliğine koy!',
    ),
    const PenaltyItem(
      id: 'p5',
      title: 'Grupta Sesli Şarkı Söyle',
      emoji: '🎤',
      description: 'Grup sohbetine 30 saniyelik ses kaydıyla arabesk/pop şarkı söyle!',
    ),
    const PenaltyItem(
      id: 'p6',
      title: '1 Gün Herkese "Hocam" De',
      emoji: '🤡',
      description: 'Yarın akşama kadar gruptaki herkese istisnasız "Hocam" diye hitap et!',
    ),
    const PenaltyItem(
      id: 'p7',
      title: 'Ortak Kasaya 100 TL',
      emoji: '💸',
      description: 'Grubun tatil/etkinlik fonuna 100 TL ceza ödemesi yap!',
    ),
    const PenaltyItem(
      id: 'p8',
      title: 'Sadece Emojiyle Konuş',
      emoji: '🤫',
      description: 'Önümüzdeki 2 saat boyunca grupta harf kullanmadan sadece emojiyle yaz!',
    ),
    const PenaltyItem(
      id: 'p9',
      title: 'Bugün Sadece Salata / Sebze',
      emoji: '🥗',
      description: 'Günün geri kalanında fast food yasak, sadece sağlıklı beslen!',
    ),
    const PenaltyItem(
      id: 'p10',
      title: 'Bulaşıkları / Masayı Topla',
      emoji: '🧽',
      description: 'Bir sonraki buluşmada masayı ve servisi tek başına üstlen!',
    ),
    const PenaltyItem(
      id: 'p11',
      title: '1 Kilometre Koş / Yürü',
      emoji: '🏃‍♂️',
      description: 'Telefonun adım sayarıyla 1 km tempolu yürüyüş/koşu kanıtı paylaş!',
    ),
    const PenaltyItem(
      id: 'p12',
      title: 'Kralın Dileği (1 İstek)',
      emoji: '👑',
      description: 'Grup liderinin veya sayacı açanın söyleyeceği masum 1 isteği yerine getir!',
    ),
  ];

  static Future<List<PenaltyItem>> getAllPenalties() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefKey);
    if (raw == null || raw.isEmpty) {
      return defaultPenalties;
    }

    try {
      final customList = raw
          .map((str) => PenaltyItem.fromMap(jsonDecode(str)))
          .toList();
      return [...defaultPenalties, ...customList];
    } catch (_) {
      return defaultPenalties;
    }
  }

  static Future<void> addCustomPenalty(PenaltyItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefKey) ?? [];
    raw.add(jsonEncode(item.toMap()));
    await prefs.setStringList(_prefKey, raw);
  }

  static PenaltyItem getRandomPenalty(List<PenaltyItem> list) {
    if (list.isEmpty) return defaultPenalties.first;
    return list[_random.nextInt(list.length)];
  }
}
