import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/public_counter.dart';
import '../models/counter_comment.dart';
import 'firebase_config.dart';
import 'firebase_service.dart';

class PublicCountersService {
  static const String _publicCountersLocalKey = 'local_public_trending_counters';
  static final StreamController<List<PublicCounter>> _localStreamController =
      StreamController<List<PublicCounter>>.broadcast();

  static bool get _useFirebase => FirebaseConfig.isValid;

  static List<PublicCounter> _getDefaultTrendingCounters() {
    final now = DateTime.now();
    return [
      PublicCounter(
        id: 'trend_istanbul_trafik',
        title: 'İstanbul Trafiksiz Geçen Süre',
        description: 'E-5 ve TEM üzerinde akıcı trafik rekoru sayacı!',
        category: 'clumsy',
        avatarEmoji: '🚗',
        lastResetTime: now.subtract(const Duration(hours: 1, minutes: 42)),
        resetCount: 148,
        likesCount: 524,
        locationTag: 'İstanbul 🇹🇷',
        recentComments: [
          CounterComment(
            id: 'c1',
            counterId: 'trend_istanbul_trafik',
            authorName: 'Metrobüs Yolcusu',
            content: 'Köprü girişinde yine kilit, rekor bitti geçmiş olsun 😂',
            timestamp: now.subtract(const Duration(minutes: 15)),
            reactionEmoji: '💀',
            likes: 12,
          ),
          CounterComment(
            id: 'c2',
            counterId: 'trend_istanbul_trafik',
            authorName: 'Taksici Hasan',
            content: 'Yağmur yağdı 1 dakikada sıfırlandı haha',
            timestamp: now.subtract(const Duration(minutes: 40)),
            reactionEmoji: '🚗',
            likes: 7,
          ),
        ],
      ),
      PublicCounter(
        id: 'trend_dolar_kuru',
        title: 'Doların Sabit Kaldığı Süre',
        description: 'Piyasalarda döviz kurunun nefes aldığı saniyeler.',
        category: 'custom',
        avatarEmoji: '📈',
        lastResetTime: now.subtract(const Duration(hours: 3, minutes: 12)),
        resetCount: 382,
        likesCount: 890,
        locationTag: 'Ekonomi 💸',
        recentComments: [
          CounterComment(
            id: 'c3',
            counterId: 'trend_dolar_kuru',
            authorName: 'Yatırımcı Ali',
            content: 'Maaş yattığı an sıfırlanıyor bu sayaç...',
            timestamp: now.subtract(const Duration(hours: 1)),
            reactionEmoji: '💸',
            likes: 19,
          ),
        ],
      ),
      PublicCounter(
        id: 'trend_pazartesi_diyeti',
        title: 'Pazartesi Diyetinin Bozulmadığı Süre',
        description: 'Ülke genelinde tatlı ve çiğ köfte krizine karşı verilen mücadele!',
        category: 'diet',
        avatarEmoji: '🍕',
        lastResetTime: now.subtract(const Duration(hours: 5, minutes: 28)),
        resetCount: 420,
        likesCount: 670,
        locationTag: 'Mutfak 🍔',
        recentComments: [
          CounterComment(
            id: 'c4',
            counterId: 'trend_pazartesi_diyeti',
            authorName: 'Tatlıkolik Ece',
            content: 'Ofise baklava geldi, irademiz 5 dakika dayanamadı 😭',
            timestamp: now.subtract(const Duration(hours: 2)),
            reactionEmoji: '🍰',
            likes: 24,
          ),
        ],
      ),
      PublicCounter(
        id: 'trend_hakem_tartismasi',
        title: 'Süper Lig\'de Hakem Tartışması Olmayan Süre',
        description: 'Maç sonu açıklamaları ve VAR kararlarının sessiz kaldığı anlar.',
        category: 'custom',
        avatarEmoji: '⚽',
        lastResetTime: now.subtract(const Duration(hours: 2, minutes: 05)),
        resetCount: 915,
        likesCount: 1204,
        locationTag: 'Süper Lig 🏆',
        recentComments: [
          CounterComment(
            id: 'c5',
            counterId: 'trend_hakem_tartismasi',
            authorName: 'Tribün Lideri',
            content: 'Daha düdük çalmadan basın toplantısı başladı bile!',
            timestamp: now.subtract(const Duration(minutes: 50)),
            reactionEmoji: '🤡',
            likes: 15,
          ),
        ],
      ),
      PublicCounter(
        id: 'trend_kahvesiz_kodlama',
        title: 'Yazılımcının Kahvesiz Kod Yazdığı Süre',
        description: 'Kafeinsiz bug çözmeye çalışan yazılımcıların direnişi.',
        category: 'custom',
        avatarEmoji: '☕',
        lastResetTime: now.subtract(const Duration(hours: 4, minutes: 19)),
        resetCount: 210,
        likesCount: 430,
        locationTag: 'Teknoloji 💻',
        recentComments: [
          CounterComment(
            id: 'c6',
            counterId: 'trend_kahvesiz_kodlama',
            authorName: 'Flutter Dev',
            content: 'Kahve makinesi bozuldu, üretim durdu ☕💀',
            timestamp: now.subtract(const Duration(hours: 3)),
            reactionEmoji: '☕',
            likes: 31,
          ),
        ],
      ),
    ];
  }

  /// Stream of all public trending counters
  static Stream<List<PublicCounter>> streamPublicCounters() {
    if (_useFirebase) {
      return FirebaseFirestore.instance
          .collection('public_counters')
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return _getDefaultTrendingCounters();
        }
        return snapshot.docs
            .map((doc) => PublicCounter.fromMap(doc.data()))
            .toList();
      });
    } else {
      _emitLocalCounters();
      return _localStreamController.stream;
    }
  }

  /// Get specific public counter by ID
  static Future<PublicCounter?> getPublicCounter(String id) async {
    final list = await _loadLocalCounters();
    final match = list.where((c) => c.id == id);
    if (match.isNotEmpty) return match.first;
    return null;
  }

  /// Reset a public counter
  static Future<void> resetPublicCounter(String counterId, String reason) async {
    final now = DateTime.now();
    final author = FirebaseService.displayName;
    final newComment = CounterComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      counterId: counterId,
      authorName: author,
      content: '🚨 Sayacı Sıfırladı: "$reason"',
      timestamp: now,
      reactionEmoji: '🚨',
      likes: 1,
    );

    final list = await _loadLocalCounters();
    final idx = list.indexWhere((c) => c.id == counterId);
    if (idx != -1) {
      final old = list[idx];
      final updated = old.copyWith(
        lastResetTime: now,
        resetCount: old.resetCount + 1,
        recentComments: [newComment, ...old.recentComments],
      );
      list[idx] = updated;
      await _saveLocalCounters(list);
    }
  }

  /// Add comment & reaction to a public counter
  static Future<void> addComment({
    required String counterId,
    required String content,
    String emoji = '💬',
  }) async {
    final author = FirebaseService.displayName;
    final comment = CounterComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      counterId: counterId,
      authorName: author,
      content: content.trim(),
      timestamp: DateTime.now(),
      reactionEmoji: emoji,
      likes: 0,
    );

    final list = await _loadLocalCounters();
    final idx = list.indexWhere((c) => c.id == counterId);
    if (idx != -1) {
      final old = list[idx];
      final updatedComments = [comment, ...old.recentComments];
      list[idx] = old.copyWith(recentComments: updatedComments);
      await _saveLocalCounters(list);
    }
  }

  /// Like a public counter
  static Future<void> likeCounter(String counterId) async {
    final list = await _loadLocalCounters();
    final idx = list.indexWhere((c) => c.id == counterId);
    if (idx != -1) {
      final old = list[idx];
      list[idx] = old.copyWith(likesCount: old.likesCount + 1);
      await _saveLocalCounters(list);
    }
  }

  // --- Local Storage Helpers ---
  static Future<List<PublicCounter>> _loadLocalCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_publicCountersLocalKey);
    if (rawList == null || rawList.isEmpty) {
      final defaults = _getDefaultTrendingCounters();
      await _saveLocalCounters(defaults);
      return defaults;
    }

    final List<PublicCounter> list = [];
    for (var s in rawList) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) {
          list.add(PublicCounter.fromMap(decoded));
        }
      } catch (_) {}
    }

    if (list.isEmpty) {
      final defaults = _getDefaultTrendingCounters();
      await _saveLocalCounters(defaults);
      return defaults;
    }

    return list;
  }

  static Future<void> _saveLocalCounters(List<PublicCounter> list) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = list.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList(_publicCountersLocalKey, rawList);
    _localStreamController.add(list);
  }

  static Future<void> _emitLocalCounters() async {
    final list = await _loadLocalCounters();
    _localStreamController.add(list);
  }
}
