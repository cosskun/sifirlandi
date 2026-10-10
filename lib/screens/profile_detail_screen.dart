import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../utils/web_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/counter_profile.dart';
import '../models/reset_entry.dart';
import '../services/storage_service.dart';
import '../services/roast_generator.dart';
import '../services/firebase_service.dart';
import '../services/sound_service.dart';
import '../services/gemini_service.dart';
import '../services/invite_service.dart';
import '../models/milestone_badge.dart';
import '../services/milestone_service.dart';
import '../widgets/penalty_wheel_dialog.dart';
import '../widgets/milestone_certificate_dialog.dart';
import '../widgets/court_veto_dialog.dart';
import '../models/reset_proposal.dart';

class ProfileDetailScreen extends StatefulWidget {
  final CounterProfile profile;
  final String currentLanguage;
  final bool isPremium;
  final String themeMode;
  final Function(CounterProfile) onProfileUpdated;
  final Function(String) onProfileDeleted;
  final Function(bool) onPremiumStatusChanged;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
    required this.currentLanguage,
    required this.isPremium,
    required this.themeMode,
    required this.onProfileUpdated,
    required this.onProfileDeleted,
    required this.onPremiumStatusChanged,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> with SingleTickerProviderStateMixin {
  late CounterProfile _profile;
  Timer? _timer;
  Duration _timeSinceLast = Duration.zero;
  late AnimationController _shakeController;
  final GlobalKey _shareCardKey = GlobalKey();
  StreamSubscription<CounterProfile>? _roomSubscription;
  
  // Premium & Theme State
  late bool _isPremium;
  late String _themeMode;

  // Interstitial Ad Simulation
  bool _showInterstitial = false;
  int _interstitialCountdown = 5;
  Timer? _interstitialTimer;
  String _tempResetNote = "";

  // Localizations mapping
  final Map<String, Map<String, String>> _localized = {
    'tr': {
      'title': 'Sayaç Detayı',
      'resetBtn': 'SIFIRLA! 🚨',
      'shareBtn': 'Paylaş 📸',
      'widgetBtn': 'Widget Ekle 📱',
      'statsHeader': 'İSTATİSTİKLER',
      'totalResets': 'TOPLAM SIFIRLAMA',
      'frequency': 'SIFIRLAMA SIKLIĞI',
      'longestStreak': 'EN UZUN REKOR (KAZASIZ SÜRE)',
      'historyHeader': 'GEÇMİŞ SIFIRLAMALAR',
      'firstReset': 'İlk kayıt 🎬',
      'sincePrev': 'Önceki kayıttan {diff} sonra',
      'placeholder': 'Henüz sıfırlanmadı! 🥳',
      'subPlaceholder': 'Rekor sonsuzluğa gidiyor, bozmamaya çalışın!',
      'sec': 'SN', 'min': 'DK', 'hour': 'SAAT', 'day': 'GÜN',
      'addResetTitle': 'Sayaç Sıfırla',
      'addResetDesc': 'Neden sıfırladınız? Nedeni kısaca yazın:',
      'hintText': 'Örn: Yine geç kaldı...',
      'cancel': 'Vazgeç',
      'confirm': 'Sıfırla!',
      'roastTitle': 'EYVAH! SIFIRLANDI!',
      'roastClose': 'Kapat',
      'deleteTitle': 'Kaydı Sil?',
      'deleteDesc': 'Bu sıfırlama kaydını silmek istediğinize emin misiniz?',
      'delete': 'Sil',
      'clumsy': 'Sakarlık', 'meeting': 'Buluşma', 'diet': 'Diyet', 'relationship': 'İlişki', 'custom': 'Özel',
      'noHistory': 'Sıfırlama geçmişi temiz.',
      'noHistorySub': 'Kurallara harika uyuluyor!',
      'averageLabel': 'Ortalama',
      'worstLabel': 'Rekor',
      'widgetTitle': 'Widget Önizleme',
      'widgetDesc': 'Bu sayacı telefonunun ana ekranına eklediğinde böyle görünecektir:',
      'shareTitle': 'Paylaşım Kartı',
      'shareSub': 'Aşağıdaki kartı ekran görüntüsü (screenshot) alarak Instagram veya TikTok\'ta paylaşabilirsin!',
      'adTitle': 'SPONSORLU REKLAM',
      'adDesc': 'İsmail Çekici ve Sanayi Hizmetleri 📞🚛\n"İsmail yolda kaldığında bizi aradı, siz de arayın! 7/24 kesintisiz çekici ve sanayi desteği."',
      'adClose': 'Reklamı Kapat ({time}s)',
      'adCloseActive': 'Reklamı Kapat [X]',
      'adRemove': 'Reklamları Kaldır (Premium) 👑',
      'adBanner': 'Sponsorlu Reklam: Coca-Cola - Susuzluğunu Sıfırla! 🥤',
      'shopTitle': 'SIFIRLANDI! PREMIUM 👑',
      'shopDesc': 'Arkadaş gruplarınız için en eğlenceli özellikleri hemen açın!',
      'shopFeat1': '🚫 Tüm Reklamları Kaldır',
      'shopFeat2': '🎨 Koyu Tema & Özel Neon Arayüzü Aç',
      'shopFeat3': '🎵 Komik Ses Paketleri (Çok Yakında)',
      'shopBuy': 'Premium Üye Ol (29.99 TL)',
      'shopSuccess': 'Tebrikler! Artık Premium Üyesiniz! 🎉',
      'deleteProfileTitle': 'Sayaç Profilini Sil?',
      'deleteProfileDesc': '"{name}" adlı arkadaşın bu sayacını ve tüm geçmişini kalıcı olarak silmek istiyor musunuz?',
    },
    'en': {
      'title': 'Counter Details',
      'resetBtn': 'RESET! 🚨',
      'shareBtn': 'Share 📸',
      'widgetBtn': 'Add Widget 📱',
      'statsHeader': 'STATISTICS',
      'totalResets': 'TOTAL RESETS',
      'frequency': 'RESET FREQUENCY',
      'longestStreak': 'PERSONAL BEST RECORD',
      'historyHeader': 'RESET HISTORY',
      'firstReset': 'First record 🎬',
      'sincePrev': '{diff} after previous reset',
      'placeholder': 'No resets yet! 🥳',
      'subPlaceholder': 'The streak is going to infinity, keep it up!',
      'sec': 'SEC', 'min': 'MIN', 'hour': 'HRS', 'day': 'DAYS',
      'addResetTitle': 'Reset Counter',
      'addResetDesc': 'Why are you resetting? Enter a brief reason:',
      'hintText': 'e.g., Showed up 40 mins late...',
      'cancel': 'Cancel',
      'confirm': 'Reset!',
      'roastTitle': 'OH NO! RESET!',
      'roastClose': 'Close',
      'deleteTitle': 'Delete Record?',
      'deleteDesc': 'Are you sure you want to delete this reset record?',
      'delete': 'Delete',
      'clumsy': 'Clumsiness', 'meeting': 'Meeting', 'diet': 'Diet', 'relationship': 'Relationship', 'custom': 'Custom',
      'noHistory': 'No reset history yet.',
      'noHistorySub': 'Rules are being followed perfectly!',
      'averageLabel': 'Average',
      'worstLabel': 'Best',
      'widgetTitle': 'Widget Preview',
      'widgetDesc': 'This is how the live widget will look on your smartphone home screen:',
      'shareTitle': 'Sharing Card',
      'shareSub': 'Take a screenshot of this vertical card to share on Instagram or TikTok!',
      'adTitle': 'SPONSORED ADVERTISEMENT',
      'adDesc': 'Ismail Towing & Garage Services 📞🚛\n"Ismail called us when he got stuck, and so should you! 24/7 towing and mechanical repairs."',
      'adClose': 'Close Ad ({time}s)',
      'adCloseActive': 'Close Ad [X]',
      'adRemove': 'Remove Ads (Premium) 👑',
      'adBanner': 'Sponsored Ad: Coca-Cola - Reset Your Thirst! 🥤',
      'shopTitle': 'RESETED! PREMIUM 👑',
      'shopDesc': 'Unlock the ultimate fun features for your friend groups!',
      'shopFeat1': '🚫 Remove All Advertisements',
      'shopFeat2': '🎨 Unlock Dark Theme & Neon Cyber Interface',
      'shopFeat3': '🎵 Humorous Sound Effects Pack (Coming Soon)',
      'shopBuy': 'Unlock Premium (\$0.99)',
      'shopSuccess': 'Congratulations! You are now a Premium Member! 🎉',
      'deleteProfileTitle': 'Delete Counter Profile?',
      'deleteProfileDesc': 'Are you sure you want to delete this counter for "{name}" and all its history permanently?',
    }
  };

  String _getTxt(String key) {
    return _localized[widget.currentLanguage]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _isPremium = widget.isPremium;
    _themeMode = widget.themeMode;
    _updateTimer();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_profile.resets.isNotEmpty) {
        setState(() {
          _timeSinceLast = DateTime.now().difference(_profile.resets.first.timestamp);
        });
      }
    });

    if (_profile.isShared && _profile.roomCode != null) {
      _roomSubscription = FirebaseService.streamRoom(_profile.roomCode!).listen((updatedRoom) {
        if (mounted) {
          setState(() {
            _profile = updatedRoom;
            _updateTimer();
          });
        }
      }, onError: (err) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.currentLanguage == 'tr' 
                  ? "Sayaç grubu silindi veya erişim yetkiniz sonlandırıldı. ❌"
                  : "Counter group deleted or access revoked. ❌"),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      });
    }

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _timer?.cancel();
    _interstitialTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _updateTimer() {
    if (_profile.resets.isNotEmpty) {
      _timeSinceLast = DateTime.now().difference(_profile.resets.first.timestamp);
    } else {
      _timeSinceLast = Duration.zero;
    }
  }

  // Pre-reset route check: if not premium, show interstitial first!
  void _triggerReset(String note) {
    if (!_isPremium) {
      setState(() {
        _tempResetNote = note;
        _showInterstitial = true;
        _interstitialCountdown = 5;
      });
      
      _interstitialTimer?.cancel();
      _interstitialTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          if (_interstitialCountdown > 0) {
            _interstitialCountdown--;
          } else {
            _interstitialTimer?.cancel();
          }
        });
      });
    } else {
      _executeReset(note);
    }
  }

  // Registers the actual reset
  Future<void> _executeReset(String note) async {
    final cleanNote = note.trim().isEmpty 
        ? (widget.currentLanguage == 'tr' ? "Sebep belirtilmedi 🤫" : "No reason provided 🤫")
        : note.trim();
    
    // Play Siren Sound Effect
    await SoundService.play(SoundEffect.siren);

    // Calculate elapsed duration since last reset
    final Duration elapsed = _profile.resets.isEmpty 
        ? Duration.zero 
        : DateTime.now().difference(_profile.resets.first.timestamp);

    // Generate Dynamic AI Roast
    final roast = await RoastGenerator.generateDynamicRoast(
      name: _profile.name,
      category: _profile.category,
      note: cleanNote,
      counterTitle: _profile.title,
      elapsedTime: _formatDuration(elapsed),
      lang: widget.currentLanguage,
    );

    final newReset = ResetEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      note: cleanNote,
      roastMessage: roast,
      durationSincePrevious: elapsed,
    );

    // Trigger shake animation
    _shakeController.forward(from: 0.0);

    // Save profile with updated resets list
    final List<ResetEntry> updatedResets = List.from(_profile.resets)..insert(0, newReset);
    
    // Calculate new longest streak
    int newLongest = _profile.longestStreakSeconds;
    if (elapsed.inSeconds > newLongest) {
      newLongest = elapsed.inSeconds;
    }

    CounterProfile updatedProfile;
    if (_profile.isShared) {
      await FirebaseService.resetSharedCounter(_profile, cleanNote, roast);
      updatedProfile = _profile.copyWith(
        longestStreakSeconds: newLongest,
        resets: updatedResets,
      );
    } else {
      updatedProfile = CounterProfile(
        id: _profile.id,
        name: _profile.name,
        title: _profile.title,
        category: _profile.category,
        avatarEmoji: _profile.avatarEmoji,
        longestStreakSeconds: newLongest,
        resets: updatedResets,
      );

      final allProfiles = await StorageService.loadProfiles();
      final idx = allProfiles.indexWhere((p) => p.id == _profile.id);
      if (idx != -1) {
        allProfiles[idx] = updatedProfile;
        await StorageService.saveProfiles(allProfiles);
      }
      widget.onProfileUpdated(updatedProfile);
    }

    setState(() {
      _profile = updatedProfile;
      _updateTimer();
    });

    // Show Custom Roast dialog overlay
    _showRoastDialog(newReset);
  }

  // Deletes a reset entry
  Future<void> _deleteResetEntry(String resetId) async {
    final List<ResetEntry> updatedResets = List.from(_profile.resets)
      ..removeWhere((r) => r.id == resetId);

    // Recalculate longest streak
    int newLongest = 0;
    if (updatedResets.isNotEmpty) {
      final chrono = List<ResetEntry>.from(updatedResets).reversed.toList();
      DateTime? prevTime;
      for (var r in chrono) {
        if (prevTime != null) {
          final diff = r.timestamp.difference(prevTime).inSeconds;
          if (diff > newLongest) newLongest = diff;
        }
        prevTime = r.timestamp;
      }
      
      final activeStreak = DateTime.now().difference(updatedResets.first.timestamp).inSeconds;
      if (activeStreak > newLongest) newLongest = activeStreak;
    }

    final updatedProfile = CounterProfile(
      id: _profile.id,
      name: _profile.name,
      title: _profile.title,
      category: _profile.category,
      avatarEmoji: _profile.avatarEmoji,
      longestStreakSeconds: newLongest,
      resets: updatedResets,
    );

    final allProfiles = await StorageService.loadProfiles();
    final idx = allProfiles.indexWhere((p) => p.id == _profile.id);
    if (idx != -1) {
      allProfiles[idx] = updatedProfile;
      await StorageService.saveProfiles(allProfiles);
    }

    setState(() {
      _profile = updatedProfile;
      _updateTimer();
    });

    widget.onProfileUpdated(updatedProfile);
  }

  // Helper formatting for durations
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return "${duration.inDays} ${_getTxt('day')}, ${(duration.inHours % 24)} ${_getTxt('hour')}";
    } else if (duration.inHours > 0) {
      return "${duration.inHours} ${_getTxt('hour')}, ${(duration.inMinutes % 60)} ${_getTxt('min')}";
    } else {
      return "${duration.inMinutes} ${_getTxt('min')}";
    }
  }

  // Calculate Average Reset Interval
  String _calculateAverageTimeBetween() {
    if (_profile.resets.length < 2) return "- 📊";

    int totalSeconds = 0;
    for (int i = 0; i < _profile.resets.length - 1; i++) {
      totalSeconds += _profile.resets[i].timestamp
          .difference(_profile.resets[i + 1].timestamp)
          .inSeconds;
    }

    final int avgSeconds = (totalSeconds / (_profile.resets.length - 1)).round();
    return _formatDuration(Duration(seconds: avgSeconds));
  }

  // Dialog to submit reset reasons
  void _showResetDialog() {
    final noteController = TextEditingController();
    final isDark = _themeMode == 'dark';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020), size: 28),
            const SizedBox(width: 10),
            Text(
              _getTxt('addResetTitle'),
              style: TextStyle(
                color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTxt('addResetDesc'),
              style: TextStyle(color: isDark ? Colors.grey.shade300 : const Color(0xFF4A3E3F), fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: _getTxt('hintText'),
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF3E8EB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTxt('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final note = noteController.text;
              Navigator.pop(context);
              _triggerReset(note);
            },
            child: Text(_getTxt('confirm'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Shows fun dialog presenting the roast statement
  void _showRoastDialog(ResetEntry reset) {
    final isDark = _themeMode == 'dark';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF3E8EB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flash_on_rounded,
                    color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _getTxt('roastTitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology_rounded, color: Colors.purpleAccent, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "GEMINI AI ROAST 🧠",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.purpleAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF281E24) : const Color(0xFFFCEFF1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE8D0D5), width: 1.5),
                  ),
                  child: Text(
                    reset.roastMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (reset.note.isNotEmpty)
                  Text(
                    "\"${reset.note}\"",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9500),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (ctx) => PenaltyWheelDialog(
                              targetName: _profile.name,
                              currentLanguage: widget.currentLanguage,
                              isDark: isDark,
                            ),
                          );
                        },
                        icon: const Icon(Icons.casino_rounded, color: Colors.white, size: 16),
                        label: Text(
                          widget.currentLanguage == 'tr' ? "Ceza Çarkı 🎯" : "Penalty Wheel 🎯",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          _getTxt('roastClose'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Deletion Confirmation Dialog
  void _showDeleteConfirmDialog(ResetEntry entry) {
    final isDark = _themeMode == 'dark';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
        title: Text(
          _getTxt('deleteTitle'),
          style: TextStyle(color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020), fontWeight: FontWeight.bold),
        ),
        content: Text(
          _getTxt('deleteDesc'),
          style: TextStyle(color: isDark ? Colors.grey.shade300 : const Color(0xFF4A3E3F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTxt('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteResetEntry(entry.id);
            },
            child: Text(_getTxt('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteProfileConfirmDialog() {
    final isDark = _themeMode == 'dark';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
        title: Text(
          _getTxt('deleteProfileTitle'),
          style: TextStyle(color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020), fontWeight: FontWeight.bold),
        ),
        content: Text(
          _getTxt('deleteProfileDesc').replaceAll('{name}', _profile.name),
          style: TextStyle(color: isDark ? Colors.grey.shade300 : const Color(0xFF4A3E3F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTxt('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onProfileDeleted(_profile.id);
            },
            child: Text(_getTxt('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Category Translators
  String _getCategoryTranslation(String category) {
    return _getTxt(category);
  }

  Color _getCategoryColor(String category) {
    final isDark = _themeMode == 'dark';
    if (isDark) {
      switch (category) {
        case 'clumsy': return const Color(0xFF3A1E1A);
        case 'meeting': return const Color(0xFF1E2E3E);
        case 'diet': return const Color(0xFF1E3A24);
        case 'relationship': return const Color(0xFF3E1E3A);
        default: return const Color(0xFF281E24);
      }
    } else {
      switch (category) {
        case 'clumsy': return const Color(0xFFFDEAE6);
        case 'meeting': return const Color(0xFFE6F0FD);
        case 'diet': return const Color(0xFFE6FDE8);
        case 'relationship': return const Color(0xFFFDE6FA);
        default: return const Color(0xFFF3E8EB);
      }
    }
  }

  // Visual helper mapping category gradients (for premium look)
  List<Color> _getCategoryIconGradient(String category) {
    switch (category) {
      case 'clumsy': return [const Color(0xFFFF5252), const Color(0xFFFF7A00)];
      case 'meeting': return [const Color(0xFF007AFF), const Color(0xFF00C6FF)];
      case 'diet': return [const Color(0xFF00E676), const Color(0xFF81C784)];
      case 'relationship': return [const Color(0xFFF50057), const Color(0xFFFF4081)];
      default: return [const Color(0xFF8E24AA), const Color(0xFFD81B60)];
    }
  }

  // Custom Emoji Resolver for pizza, etc.
  String _resolveEmoji(String value) {
    if (value.toLowerCase() == 'pizza') return '🍕';
    return value;
  }

  String get _currentUserRole {
    if (!_profile.isShared) return 'admin';
    final uid = FirebaseService.userId;
    return _profile.members[uid] ?? 'viewer';
  }

  bool get _canReset {
    final role = _currentUserRole;
    return role == 'admin' || role == 'editor';
  }

  bool get _isAdmin {
    final role = _currentUserRole;
    return role == 'admin';
  }

  void _showMembersPanel() {
    final isDark = _themeMode == 'dark';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final membersList = _profile.members.keys.toList();
            
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.currentLanguage == 'tr' ? "Sayaç Üyeleri" : "Counter Members",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF3E8EB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.currentLanguage == 'tr' ? "ODA KATILIM KODU" : "ROOM JOIN CODE",
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _profile.roomCode ?? "",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                tooltip: "Kodu Kopyala",
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _profile.roomCode ?? ""));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(widget.currentLanguage == 'tr' 
                                          ? "Davet kodu kopyalandı! 📋" 
                                          : "Invite code copied! 📋"),
                                      backgroundColor: const Color(0xFF800020),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onPressed: () {
                                    InviteService.shareToWhatsApp(
                                      counterTitle: _profile.title,
                                      roomCode: _profile.roomCode ?? '',
                                      lang: widget.currentLanguage,
                                    );
                                  },
                                  icon: const Icon(Icons.chat_rounded, size: 16),
                                  label: Text(
                                    widget.currentLanguage == 'tr' ? "WhatsApp'ta Davet Et" : "Invite on WhatsApp",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onPressed: () {
                                  InviteService.copyLink(roomCode: _profile.roomCode ?? '');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(widget.currentLanguage == 'tr' ? "Doğrudan katılma linki kopyalandı! 🔗" : "Join link copied! 🔗"),
                                      backgroundColor: const Color(0xFF800020),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.link_rounded, size: 16),
                                label: Text(
                                  widget.currentLanguage == 'tr' ? "Linki Kopyala" : "Copy Link",
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text(
                      widget.currentLanguage == 'tr' ? "Üyeler Listesi (${membersList.length})" : "Members List (${membersList.length})",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: membersList.length,
                      itemBuilder: (context, index) {
                        final mId = membersList[index];
                        final mName = _profile.memberNames[mId] ?? "Katılımcı";
                        final mRole = _profile.members[mId] ?? "viewer";
                        final isMe = mId == FirebaseService.userId;
                        
                        String roleText = "İzleyici";
                        Color roleColor = Colors.grey;
                        if (mRole == 'admin') {
                          roleText = "Kurucu";
                          roleColor = Colors.amber.shade800;
                        } else if (mRole == 'editor') {
                          roleText = "Resetçi";
                          roleColor = Colors.blue.shade600;
                        }
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C32) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : const Color(0xFFE8D0D5).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$mName ${isMe ? ' (Siz)' : ''}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF2C2526),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mRole == 'admin' ? "Tam Yetki" : (mRole == 'editor' ? "Sıfırlama Yetkisi" : "Sadece İzleme"),
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: roleColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      roleText,
                                      style: TextStyle(
                                        color: roleColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (_isAdmin && mRole != 'admin')
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                                      onSelected: (action) async {
                                        if (action == 'make_editor') {
                                          await FirebaseService.updateMemberRole(_profile.roomCode!, mId, 'editor');
                                        } else if (action == 'make_viewer') {
                                          await FirebaseService.updateMemberRole(_profile.roomCode!, mId, 'viewer');
                                        } else if (action == 'kick') {
                                          await FirebaseService.removeMember(_profile.roomCode!, mId);
                                        }
                                        if (context.mounted) {
                                          setSheetState(() {});
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        if (mRole != 'editor')
                                          PopupMenuItem(
                                            value: 'make_editor',
                                            child: Text(widget.currentLanguage == 'tr' ? "Resetçi Yap" : "Make Resetter"),
                                          ),
                                        if (mRole != 'viewer')
                                          PopupMenuItem(
                                            value: 'make_viewer',
                                            child: Text(widget.currentLanguage == 'tr' ? "İzleyici Yap" : "Make Viewer"),
                                          ),
                                        PopupMenuItem(
                                          value: 'kick',
                                          child: Text(
                                            widget.currentLanguage == 'tr' ? "Odadan At" : "Kick Out",
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Shows Premium Shop from detail screen
  void _showPremiumShop() {
    final isDark = _themeMode == 'dark';
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setShopState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFFAF6F0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24),
                        Icon(Icons.stars_rounded, color: Colors.amber.shade700, size: 36),
                        IconButton(
                          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getTxt('shopTitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.amber.shade600 : const Color(0xFF800020),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTxt('shopDesc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    _buildShopFeatureRow(_getTxt('shopFeat1'), isDark),
                    const SizedBox(height: 12),
                    _buildShopFeatureRow(_getTxt('shopFeat2'), isDark),
                    const SizedBox(height: 12),
                    _buildShopFeatureRow(_getTxt('shopFeat3'), isDark),
                    const SizedBox(height: 32),
                    isProcessing
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF800020),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () async {
                                setShopState(() {
                                  isProcessing = true;
                                });
                                await Future.delayed(const Duration(milliseconds: 1200));
                                await StorageService.setPremiumUser(true);
                                
                                if (mounted) {
                                  setState(() {
                                    _isPremium = true;
                                  });
                                }
                                widget.onPremiumStatusChanged(true);

                                setShopState(() {
                                  isProcessing = false;
                                });
                                Navigator.pop(context);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_getTxt('shopSuccess')),
                                    backgroundColor: const Color(0xFF800020),
                                  ),
                                );
                              },
                              child: Text(_getTxt('shopBuy'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShopFeatureRow(String text, bool isDark) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF2C2526),
            ),
          ),
        ),
      ],
    );
  }

  // Shows Widget Mockup Preview Screen
  void _showWidgetMockup() {
    final isDark = _themeMode == 'dark';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      _getTxt('widgetTitle'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getTxt('widgetDesc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mockup Phone Homescreen Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black, width: 8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "18:19",
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.wifi_sharp, color: Colors.white, size: 10),
                          ],
                        ),
                      ),

                      // The Simulated Counter Widget
                      Center(
                        child: Container(
                          width: 170,
                          height: 170,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? const Color(0xFF1E1E22).withOpacity(0.95)
                                : const Color(0xFFFAF6F0).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                            border: Border.all(
                              color: isDark 
                                  ? const Color(0xFFFF2D55).withOpacity(0.3)
                                  : const Color(0xFF800020).withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: _getCategoryColor(_profile.category),
                                    child: Text(
                                      _resolveEmoji(_profile.avatarEmoji),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _profile.resets.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : const Color(0xFF2C2526),
                                    ),
                                  ),
                                  Text(
                                    _profile.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _profile.resets.isEmpty 
                                    ? _getTxt('placeholder') 
                                    : _formatDuration(_timeSinceLast),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _copyShareTextToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.currentLanguage == 'tr'
            ? "Paylaşım detayları kopyalandı! Panodaki yazıyı doğrudan hikayenize yapıştırabilirsiniz. 📸"
            : "Sharing details copied! You can now paste directly into your story. 📸"),
        backgroundColor: const Color(0xFF800020),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _launchSocialUrl(String webUrl) async {
    final Uri uri = Uri.parse(webUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _shareImage(String shareText, String targetPlatform) async {
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _copyShareTextToClipboard(shareText);
        return;
      }
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _copyShareTextToClipboard(shareText);
        return;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      if (kIsWeb) {
        final base64Str = base64Encode(pngBytes);
        final fileName = 'sifirlandi_${_profile.name.replaceAll(' ', '_')}.png';
        downloadFileOnWeb(base64Str, fileName);
        
        Clipboard.setData(ClipboardData(text: shareText));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.currentLanguage == 'tr'
                ? "Görsel indirildi ve metin kopyalandı! Şimdi hikayenizde paylaşabilirsiniz. 📸"
                : "Image downloaded and text copied! You can now share it in your story. 📸"),
            backgroundColor: const Color(0xFF800020),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        final xFile = XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: 'sifirlandi_${_profile.name}.png',
        );
        
        await Share.shareXFiles(
          [xFile],
          text: shareText,
        );
      }
      
      if (targetPlatform.toLowerCase() == 'instagram') {
        await _launchSocialUrl('https://www.instagram.com/');
      } else if (targetPlatform.toLowerCase() == 'tiktok') {
        await _launchSocialUrl('https://www.tiktok.com/');
      }
    } catch (e) {
      _copyShareTextToClipboard(shareText);
      if (targetPlatform.toLowerCase() == 'instagram') {
        await _launchSocialUrl('https://www.instagram.com/');
      } else if (targetPlatform.toLowerCase() == 'tiktok') {
        await _launchSocialUrl('https://www.tiktok.com/');
      }
    }
  }

  // Shows 9:16 Instagram Story Social Media Sharing Card Preview
  void _showShareOverlay() {
    final isDark = _themeMode == 'dark';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final activeStreak = _profile.resets.isEmpty
            ? "0"
            : _formatDuration(_timeSinceLast);
        
        final latestReason = _profile.resets.isEmpty
            ? ""
            : _profile.resets.first.note;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Column(
                  children: [
                    Text(
                      _getTxt('shareTitle'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTxt('shareSub'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // The 9:16 vertical card mockup
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    key: _shareCardKey,
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark 
                              ? [const Color(0xFF9E1B32), const Color(0xFF121214)]
                              : [const Color(0xFF800020), const Color(0xFFB57C8A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 360,
                          height: 640,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _resolveEmoji(_profile.avatarEmoji),
                                            style: const TextStyle(fontSize: 22),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _profile.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Main Card Content
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                      )
                                    ],
                                    border: Border.all(
                                      color: isDark ? Colors.grey.shade800 : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          widget.currentLanguage == 'tr' ? "🚨 SIFIRLANDI!" : "🚨 RESET!",
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 24,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        widget.currentLanguage == 'tr'
                                            ? "${_profile.name} arkadaşımızın \"${_profile.title}\" sayacı sıfırlandı."
                                            : "${_profile.name}'s \"${_profile.title}\" counter has been reset.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white : const Color(0xFF2C2526),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          activeStreak,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        widget.currentLanguage == 'tr' ? "boyunca dayanmıştı." : "streak is gone.",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB57C8A),
                                        ),
                                      ),
                                      if (latestReason.isNotEmpty) ...[
                                        const SizedBox(height: 20),
                                        const Divider(),
                                        const SizedBox(height: 10),
                                        Text(
                                          widget.currentLanguage == 'tr' ? "Sıfırlama Nedeni:" : "Reset Reason:",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "\"$latestReason\"",
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF2C2526),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),

                                Column(
                                  children: [
                                    Text(
                                      "Sıfırlandı! App",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ),
              const SizedBox(height: 8),

              // Instagram & TikTok share action buttons
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0, top: 4.0),
                child: Row(
                  children: [
                    // Instagram Share Button
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF56040)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            final shareText = widget.currentLanguage == 'tr'
                                ? "🚨 SIFIRLANDI! 🚨\n${_profile.name} arkadaşımızın \"${_profile.title}\" sayacı sıfırlandı! Bu rekor $activeStreak sürdü. Sen de kendi grubunu kur: Sıfırlandı!"
                                : "🚨 RESETED! 🚨\n${_profile.name}'s \"${_profile.title}\" counter has reset! The record lasted $activeStreak. Set up your group: Sıfırlandı!";
                            _shareImage(shareText, 'Instagram');
                          },
                          icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                          label: Text(
                            widget.currentLanguage == 'tr' ? "Instagram" : "Instagram",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // TikTok Share Button
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00F2FE), width: 1.5),
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            final shareText = widget.currentLanguage == 'tr'
                                ? "🚨 SIFIRLANDI! 🚨\n${_profile.name} arkadaşımızın \"${_profile.title}\" sayacı sıfırlandı! Bu rekor $activeStreak sürdü. Sen de kendi grubunu kur: Sıfırlandı!"
                                : "🚨 RESETED! 🚨\n${_profile.name}'s \"${_profile.title}\" counter has reset! The record lasted $activeStreak. Set up your group: Sıfırlandı!";
                            _shareImage(shareText, 'TikTok');
                          },
                          icon: const Icon(Icons.music_note_rounded, color: Color(0xFFFE2C55), size: 18),
                          label: Text(
                            widget.currentLanguage == 'tr' ? "TikTok" : "TikTok",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Timer Tick visual component (with Neon glows for Dark mode)
  Widget _buildTimerTicker() {
    final isDark = _themeMode == 'dark';
    if (_profile.resets.isEmpty) {
      return Column(
        children: [
          Icon(Icons.shield_rounded, color: Colors.green.shade700, size: 48),
          const SizedBox(height: 12),
          Text(
            _getTxt('placeholder'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _getTxt('subPlaceholder'),
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
          ),
        ],
      );
    }

    final int days = _timeSinceLast.inDays;
    final int hours = _timeSinceLast.inHours % 24;
    final int minutes = _timeSinceLast.inMinutes % 60;
    final int seconds = _timeSinceLast.inSeconds % 60;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeSegment(days.toString().padLeft(2, '0'), _getTxt('day')),
            _buildTimeColon(),
            _buildTimeSegment(hours.toString().padLeft(2, '0'), _getTxt('hour')),
            _buildTimeColon(),
            _buildTimeSegment(minutes.toString().padLeft(2, '0'), _getTxt('min')),
            _buildTimeColon(),
            _buildTimeSegment(seconds.toString().padLeft(2, '0'), _getTxt('sec')),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSegment(String val, String label) {
    final isDark = _themeMode == 'dark';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C32) : const Color(0xFF800020),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? const Color(0xFFFF2D55).withOpacity(0.2) 
                    : const Color(0xFF800020).withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(
              color: isDark ? const Color(0xFFFF2D55).withOpacity(0.5) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            val,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFFF2D55) : const Color(0xFFFAF6F0),
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeColon() {
    final isDark = _themeMode == 'dark';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: [
          Text(
            ":",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  double _getShakeOffsetX(double animationValue) {
    return sin(animationValue * pi * 8) * 8.0 * (1.0 - animationValue);
  }

  // Simulated Bottom AdBanner Widget
  Widget _buildAdBanner() {
    final isDark = _themeMode == 'dark';
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF3E8EB),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFE8D0D5),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "AD",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getTxt('adBanner'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _showPremiumShop,
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Full-Screen Interstitial Ad overlay
  Widget _buildInterstitialOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.96),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF2D55), width: 2),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFFFF2D55),
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _getTxt('adTitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getTxt('adDesc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 64),

            // Close button or timer
            _interstitialCountdown > 0
                ? Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _getTxt('adClose').replaceAll('{time}', _interstitialCountdown.toString()),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _showInterstitial = false;
                        });
                        _executeReset(_tempResetNote);
                      },
                      child: Text(
                        _getTxt('adCloseActive'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 16),

            // Go Premium Link
            TextButton(
              onPressed: () {
                _showPremiumShop();
              },
              child: Text(
                _getTxt('adRemove'),
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == 'dark';
    final String avgTime = _calculateAverageTimeBetween();
    final String longestStreakText = _profile.longestStreakSeconds == 0 
        ? "- 📊" 
        : _formatDuration(Duration(seconds: _profile.longestStreakSeconds));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121214) : const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: Text(
          _profile.name.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.2,
            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFFFAF6F0),
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFF800020),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFFFAF6F0)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              SoundService.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: isDark ? Colors.white : const Color(0xFFFAF6F0),
            ),
            tooltip: "Ses Efektleri",
            onPressed: () async {
              await SoundService.toggleSound();
              setState(() {});
            },
          ),
          if (_profile.isShared) ...[
            IconButton(
              icon: Icon(Icons.people_outline_rounded, color: isDark ? Colors.white : const Color(0xFFFAF6F0)),
              onPressed: _showMembersPanel,
            ),
            if (!_isAdmin)
              IconButton(
                icon: Icon(Icons.exit_to_app_rounded, color: isDark ? Colors.red.shade400 : const Color(0xFFFAF6F0)),
                onPressed: () async {
                  final leave = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
                      title: Text(
                        widget.currentLanguage == 'tr' ? "Odadan Ayrıl?" : "Leave Room?",
                        style: TextStyle(color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020), fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        widget.currentLanguage == 'tr' 
                            ? "Bu ortak sayaç grubundan ayrılmak istediğinize emin misiniz?"
                            : "Are you sure you want to leave this shared counter group?",
                        style: TextStyle(color: isDark ? Colors.grey.shade300 : const Color(0xFF4A3E3F)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(_getTxt('cancel'), style: const TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(widget.currentLanguage == 'tr' ? "Ayrıl" : "Leave", style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  
                  if (leave == true) {
                    await FirebaseService.leaveSharedRoom(_profile.roomCode!);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              )
            else
              IconButton(
                icon: Icon(Icons.delete_outline, color: isDark ? Colors.red.shade400 : const Color(0xFFFAF6F0)),
                onPressed: () async {
                  final delete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
                      title: Text(
                        widget.currentLanguage == 'tr' ? "Sayacı Tamamen Sil?" : "Delete Counter Permanently?",
                        style: TextStyle(color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020), fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        widget.currentLanguage == 'tr' 
                            ? "Bu ortak sayacı ve tüm geçmişini silmek istediğinize emin misiniz? Bu işlem geri alınamaz!"
                            : "Are you sure you want to delete this shared counter and all its history? This action cannot be undone!",
                        style: TextStyle(color: isDark ? Colors.grey.shade300 : const Color(0xFF4A3E3F)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(_getTxt('cancel'), style: const TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(widget.currentLanguage == 'tr' ? "Sil" : "Delete", style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  
                  if (delete == true) {
                    await FirebaseService.deleteSharedRoom(_profile.roomCode!);
                  }
                },
              ),
          ] else
            IconButton(
              icon: Icon(Icons.delete_outline, color: isDark ? Colors.red.shade400 : const Color(0xFFFAF6F0)),
              onPressed: _showDeleteProfileConfirmDialog,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main Body Screen
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Card containing Emoji and Title
                        AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_getShakeOffsetX(_shakeController.value), 0),
                              child: child,
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 10,
                                    )
                                  ],
                                  border: Border.all(
                                    color: isDark ? Colors.grey.shade800 : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Visual Gradient Category Avatar
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _getCategoryIconGradient(_profile.category),
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _resolveEmoji(_profile.avatarEmoji),
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getCategoryTranslation(_profile.category).toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                            ),
                                          ),
                                          Text(
                                            _profile.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? Colors.white : const Color(0xFF2C2526),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Shared Room Invite Banner
                              if (_profile.isShared) ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFFFF2D55).withOpacity(0.3) : const Color(0xFFE8D0D5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFFFF2D55).withOpacity(0.2) : const Color(0xFF800020).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  "🔑 ${_profile.roomCode ?? ''}",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.5,
                                                    color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                widget.currentLanguage == 'tr' ? "Arkadaşlarını Çağır" : "Invite Friends",
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy_rounded, size: 18),
                                            tooltip: "Kodu Kopyala",
                                            onPressed: () {
                                              InviteService.copyFullInvite(
                                                counterTitle: _profile.title,
                                                roomCode: _profile.roomCode ?? '',
                                                lang: widget.currentLanguage,
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(widget.currentLanguage == 'tr' ? "Davet mesajı ve linki kopyalandı! 📋" : "Invite message and link copied! 📋"),
                                                  backgroundColor: const Color(0xFF800020),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF25D366),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                              ),
                                              onPressed: () {
                                                InviteService.shareToWhatsApp(
                                                  counterTitle: _profile.title,
                                                  roomCode: _profile.roomCode ?? '',
                                                  lang: widget.currentLanguage,
                                                );
                                              },
                                              icon: const Icon(Icons.chat_rounded, size: 16),
                                              label: Text(
                                                widget.currentLanguage == 'tr' ? "WhatsApp'ta Davet Et" : "Share on WhatsApp",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            ),
                                            onPressed: () {
                                              InviteService.copyLink(roomCode: _profile.roomCode ?? '');
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(widget.currentLanguage == 'tr' ? "Doğrudan katılma linki kopyalandı! 🔗" : "Join link copied! 🔗"),
                                                  backgroundColor: const Color(0xFF800020),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.link_rounded, size: 16),
                                            label: Text(
                                              widget.currentLanguage == 'tr' ? "Linki Al" : "Copy Link",
                                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Dashboard Ticking Card
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF3E8EB),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFFFF2D55).withOpacity(0.3) : const Color(0xFFE8D0D5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: _buildTimerTicker(),
                              ),
                              const SizedBox(height: 16),

                              // Milestone Badges & Level Progress Card
                              _buildMilestoneBadgesCard(_getActiveStreak(), isDark),
                              const SizedBox(height: 14),

                              // Social Actions: Ceza Çarkı & Grup Mahkemesi
                              _buildSocialActionsRow(isDark),
                              const SizedBox(height: 14),

                              // Statistics Rows
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: _getTxt('totalResets'),
                                      value: _profile.resets.length.toString(),
                                      icon: Icons.numbers_rounded,
                                      color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: _getTxt('frequency'),
                                      value: avgTime,
                                      icon: Icons.access_time_filled_rounded,
                                      color: const Color(0xFFB57C8A),
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildLongestStreakCard(longestStreakText, isDark),
                              const SizedBox(height: 20),

                              // Large reset and share action row
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 60,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _canReset
                                              ? (isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020))
                                              : (isDark ? Colors.grey.shade800 : Colors.grey.shade400),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: _canReset ? 4 : 0,
                                          shadowColor: isDark 
                                              ? const Color(0xFFFF2D55).withOpacity(0.3)
                                              : const Color(0xFF800020).withOpacity(0.3),
                                        ),
                                        onPressed: _canReset ? _showResetDialog : () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(widget.currentLanguage == 'tr'
                                                  ? "Sıfırlama yapmak için kurucudan yetki almalısınız! 🔒"
                                                  : "You must get reset permission from the creator! 🔒"),
                                              backgroundColor: Colors.red.shade800,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          _canReset
                                              ? _getTxt('resetBtn')
                                              : (widget.currentLanguage == 'tr' ? "🔒 Sadece İzleme" : "🔒 View Only"),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020), 
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        onPressed: _showShareOverlay,
                                        child: Text(
                                          _getTxt('shareBtn'),
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFB57C8A), width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        onPressed: _showWidgetMockup,
                                        child: Text(
                                          _getTxt('widgetBtn'),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFB57C8A),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // History Logs list
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getTxt('historyHeader'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              "${_profile.resets.length} ${_profile.resets.length == 1 ? 'Log' : 'Logs'}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB57C8A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _profile.resets.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFDFCFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.event_note, color: Colors.grey.shade600, size: 40),
                                    const SizedBox(height: 12),
                                    Text(
                                      _getTxt('noHistory'),
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      _getTxt('noHistorySub'),
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _profile.resets.length,
                                itemBuilder: (context, index) {
                                  final item = _profile.resets[index];
                                  final String formattedDate = DateFormat('dd MMMM yyyy, HH:mm', widget.currentLanguage == 'tr' ? 'tr_TR' : 'en_US')
                                      .format(item.timestamp);

                                  String intervalText = "";
                                  if (index < _profile.resets.length - 1) {
                                    final older = _profile.resets[index + 1];
                                    final diff = item.timestamp.difference(older.timestamp);
                                    intervalText = _getTxt('sincePrev')
                                        .replaceAll('{diff}', _formatDuration(diff));
                                  } else {
                                    intervalText = _getTxt('firstReset');
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.015),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                      border: Border.all(
                                        color: isDark ? Colors.grey.shade800 : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFFCEFF1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.history_toggle_off_rounded,
                                          color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : const Color(0xFF2C2526),
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            item.note,
                                            style: TextStyle(
                                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.roastMessage,
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.timelapse,
                                                size: 12,
                                                color: Color(0xFFB57C8A),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                intervalText,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFB57C8A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: _isAdmin
                                          ? IconButton(
                                              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                                              onPressed: () => _showDeleteConfirmDialog(item),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom Banner Ad (if not Premium)
              if (!_isPremium) _buildAdBanner(),
            ],
          ),

          // Interstitial Fullscreen Ad Overlay
          if (_showInterstitial) _buildInterstitialOverlay(),
        ],
      ),
    );
  }

  // Stat Card builder
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF2C2526),
            ),
          ),
        ],
      ),
    );
  }

  // Longest Streak record card builder
  Widget _buildLongestStreakCard(String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events, color: Colors.amber.shade800, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTxt('longestStreak'),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF2C2526),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Duration _getActiveStreak() {
    if (_profile.resets.isEmpty) return Duration.zero;
    final lastReset = _profile.resets.last.timestamp;
    return DateTime.now().difference(lastReset);
  }

  Widget _buildMilestoneBadgesCard(Duration streak, bool isDark) {
    final unlocked = MilestoneService.getUnlockedBadges(streak);
    final next = MilestoneService.getNextMilestone(streak);
    final progress = MilestoneService.calculateProgress(streak);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE8D0D5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("🏅", style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    widget.currentLanguage == 'tr' ? "BAŞARI ROZETLERİ" : "MILESTONES",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                    ),
                  ),
                ],
              ),
              Text(
                "${unlocked.length}/${MilestoneService.badges.length} ${widget.currentLanguage == 'tr' ? 'Açık' : 'Unlocked'}",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Badges Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: MilestoneService.badges.map((badge) {
                final isAchieved = badge.isUnlocked(streak);
                return GestureDetector(
                  onTap: () {
                    if (isAchieved) {
                      showDialog(
                        context: context,
                        builder: (ctx) => MilestoneCertificateDialog(
                          badge: badge,
                          userName: _profile.name,
                          counterTitle: _profile.title,
                          currentLanguage: widget.currentLanguage,
                          isDark: isDark,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.currentLanguage == 'tr'
                              ? "🔒 ${badge.title}: ${badge.targetDays} gün sıfırlanmadan dayanarak bu rozeti açabilirsin!"
                              : "🔒 ${badge.title}: Reach ${badge.targetDays} days without reset to unlock!"),
                          backgroundColor: const Color(0xFF800020),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAchieved
                          ? (isDark ? const Color(0xFF2C2415) : const Color(0xFFFFF9E6))
                          : (isDark ? const Color(0xFF141416) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isAchieved ? Colors.amber : Colors.grey.shade400.withOpacity(0.3),
                        width: isAchieved ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          badge.iconEmoji,
                          style: TextStyle(
                            fontSize: 18,
                            color: isAchieved ? null : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAchieved
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              "${badge.targetDays} ${widget.currentLanguage == 'tr' ? 'Gün' : 'Days'}",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isAchieved ? Colors.amber.shade700 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Next Milestone Progress Bar
          if (next != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.currentLanguage == 'tr'
                        ? "Sıradaki: ${next.title} (${next.targetDays} Gün)"
                        : "Next: ${next.title} (${next.targetDays} Days)",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "%${(progress * 100).toInt()}",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialActionsRow(bool isDark) {
    return Row(
      children: [
        // Ceza Çarkı Button
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9500),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 2,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => PenaltyWheelDialog(
                  targetName: _profile.name,
                  currentLanguage: widget.currentLanguage,
                  isDark: isDark,
                ),
              );
            },
            icon: const Icon(Icons.casino_rounded, size: 18),
            label: Text(
              widget.currentLanguage == 'tr' ? "Ceza Çarkı 🎯" : "Penalty Wheel 🎯",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        if (_profile.isShared) ...[
          const SizedBox(width: 10),
          // Grup Mahkemesi Oylama Button
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF5856D6) : const Color(0xFF4A148C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 2,
              ),
              onPressed: _startCourtSession,
              icon: const Icon(Icons.gavel_rounded, size: 18),
              label: Text(
                widget.currentLanguage == 'tr' ? "Mahkeme ⚖️" : "Group Court ⚖️",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _startCourtSession() {
    final proposal = ResetProposal(
      id: 'prop_${DateTime.now().millisecondsSinceEpoch}',
      counterId: _profile.id,
      proposerName: FirebaseService.displayName,
      targetName: _profile.name,
      allegedReason: "Sayacı bozduğu iddia ediliyor!",
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(seconds: 60)),
    );

    showDialog(
      context: context,
      builder: (ctx) => CourtVetoDialog(
        proposal: proposal,
        currentLanguage: widget.currentLanguage,
        isDark: widget.themeMode == 'dark',
        onVote: (isYes) {},
        onVerdictApproved: () {
          Navigator.pop(context);
          _showResetDialog();
        },
        onVerdictVetoed: () {
          Navigator.pop(context);
          SoundService.play(SoundEffect.victory);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.currentLanguage == 'tr'
                  ? "Mahkeme Kararı: Masum! İtiraz kabul edildi, sayaç sıfırlanmadı! 🛡️⚖️"
                  : "Verdict: Innocent! Veto passed, counter not reset! 🛡️⚖️"),
              backgroundColor: Colors.green.shade800,
            ),
          );
        },
      ),
    );
  }
}

