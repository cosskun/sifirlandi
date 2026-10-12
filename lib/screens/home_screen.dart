import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/counter_profile.dart';
import '../models/reset_entry.dart';
import '../models/public_counter.dart';
import '../services/storage_service.dart';
import '../services/roast_generator.dart';
import '../services/firebase_config.dart';
import '../services/firebase_service.dart';
import '../services/sound_service.dart';
import '../services/gemini_service.dart';
import '../services/public_counters_service.dart';
import '../services/invite_service.dart';
import 'profile_detail_screen.dart';
import 'public_counter_detail_screen.dart';
import 'widget_studio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CounterProfile> _profiles = [];
  bool _isLoading = true;
  String _currentLanguage = 'tr';
  Timer? _timer;
  
  // Premium & Theme State
  bool _isPremium = false;
  String _themeMode = 'light'; // light or dark

  // Language mapping
  final Map<String, Map<String, String>> _localized = {
    'tr': {
      'title': 'SIFIRLANDI!',
      'profilesHeader': 'SAYAÇLARINIZ',
      'noProfiles': 'Henüz sayaç oluşturulmadı.',
      'noProfilesSub': 'Gruptaki arkadaşlarınızı ekleyerek başlayın!',
      'addProfileTitle': 'Yeni Sayaç Oluştur',
      'addProfileDesc': 'Takip etmek istediğiniz arkadaşı ve olayı girin:',
      'nameLabel': 'Arkadaşının İsmi',
      'titleLabel': 'Takip Edilecek Olay / Sayaç Başlığı',
      'titleHint': 'Örn: Buluşmalara geç kalmadığı süre',
      'categoryLabel': 'Kategori',
      'emojiLabel': 'Simge Seçimi (Emoji)',
      'cancel': 'Vazgeç',
      'create': 'Oluştur',
      'confirm': 'Sıfırla!',
      'clumsy': 'Sakarlık', 'meeting': 'Buluşma', 'diet': 'Diyet', 'relationship': 'İlişki', 'custom': 'Özel',
      'days': 'Gün', 'hours': 'Saat', 'mins': 'Dk', 'secs': 'Sn',
      'resetsCount': '{count} Sıfırlama',
      'noResetsYet': 'Henüz sıfırlanmadı! 🥳',
      'deleteProfileTitle': 'Sayaç Profilini Sil?',
      'deleteProfileDesc': '"{name}" adlı arkadaşın bu sayacını ve tüm geçmişini kalıcı olarak silmek istiyor musunuz?',
      'delete': 'Sil',
      'quickResetTitle': 'Hızlı Sıfırla',
      'quickResetDesc': 'Sayaç sıfırlama nedeni:',
      'quickResetHint': 'Örn: Diyeti bozdu...',
      'roastTitle': 'EYVAH! SIFIRLANDI!',
      'roastClose': 'Kapat',
      'shopTitle': 'SIFIRLANDI! PREMIUM 👑',
      'shopDesc': 'Arkadaş gruplarınız için en eğlenceli özellikleri hemen açın!',
      'shopFeat1': '🚫 Tüm Reklamları Kaldır',
      'shopFeat2': '🎨 Koyu Tema & Özel Neon Arayüzü Aç',
      'shopFeat3': '🎵 Komik Ses Paketleri (Çok Yakında)',
      'shopBuy': 'Premium Üye Ol (29.99 TL)',
      'shopSuccess': 'Tebrikler! Artık Premium Üyesiniz! 🎉',
      'adBanner': 'Sponsorlu Reklam: Coca-Cola - Susuzluğunu Sıfırla! 🥤',
    },
    'en': {
      'title': 'RESETED!',
      'profilesHeader': 'YOUR COUNTERS',
      'noProfiles': 'No counters created yet.',
      'noProfilesSub': 'Start by adding your friends and habits!',
      'addProfileTitle': 'Create New Counter',
      'addProfileDesc': 'Enter the friend and the event you want to track:',
      'nameLabel': 'Friend\'s Name',
      'titleLabel': 'Event / Counter Title',
      'titleHint': 'e.g., Time since showing up late',
      'categoryLabel': 'Category',
      'emojiLabel': 'Select Icon (Emoji)',
      'cancel': 'Cancel',
      'create': 'Create',
      'confirm': 'Reset!',
      'clumsy': 'Clumsiness', 'meeting': 'Meeting', 'diet': 'Diet', 'relationship': 'Relationship', 'custom': 'Custom',
      'days': 'Days', 'hours': 'Hrs', 'mins': 'Mins', 'secs': 'Secs',
      'resetsCount': '{count} Resets',
      'noResetsYet': 'No resets yet! 🥳',
      'deleteProfileTitle': 'Delete Counter Profile?',
      'deleteProfileDesc': 'Are you sure you want to delete this counter for "{name}" and all its history permanently?',
      'delete': 'Delete',
      'quickResetTitle': 'Quick Reset',
      'quickResetDesc': 'Reason for resetting:',
      'quickResetHint': 'e.g., Ate a burger...',
      'roastTitle': 'OH NO! RESET!',
      'roastClose': 'Close',
      'shopTitle': 'RESETED! PREMIUM 👑',
      'shopDesc': 'Unlock the ultimate fun features for your friend groups!',
      'shopFeat1': '🚫 Remove All Advertisements',
      'shopFeat2': '🎨 Unlock Dark Theme & Neon Cyber Interface',
      'shopFeat3': '🎵 Humorous Sound Effects Pack (Coming Soon)',
      'shopBuy': 'Unlock Premium (\$0.99)',
      'shopSuccess': 'Congratulations! You are now a Premium Member! 🎉',
      'adBanner': 'Sponsored Ad: Coca-Cola - Reset Your Thirst! 🥤',
    }
  };

  String _getTxt(String key) {
    return _localized[_currentLanguage]?[key] ?? key;
  }

  // Categories list helper
  List<Map<String, String>> _getCategories() {
    return [
      {'key': 'clumsy', 'label': _getTxt('clumsy')},
      {'key': 'meeting', 'label': _getTxt('meeting')},
      {'key': 'diet', 'label': _getTxt('diet')},
      {'key': 'relationship', 'label': _getTxt('relationship')},
      {'key': 'custom', 'label': _getTxt('custom')},
    ];
  }

  // Preselected emojis for avatar selection (expanded funny & expressive list)
  final List<String> _emojisList = [
    '🚗', '🤦‍♂️', '🍕', '⏰', '💔', '🍺', '🤫', '🏆', '📝', '🏃‍♂️', '🎮', '☕',
    '🤡', '💩', '🥑', '👻', '🦥', '💥', '🥳', '🫠', '💅', '🧠', '💸', '🦄',
    'Dino', '🧘‍♂️', '🚭', '🍿', '🔥', '💀'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();

    // Periodic timer to tick home screen cards live
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });

    // Detect direct invite deep links e.g. ?join=ABC123
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = Uri.base;
      final joinCode = uri.queryParameters['join'] ?? uri.queryParameters['code'];
      if (joinCode != null && joinCode.trim().isNotEmpty) {
        _autoJoinFromLink(joinCode.trim().toUpperCase());
      }
    });
  }

  Future<void> _autoJoinFromLink(String code) async {
    try {
      final joined = await FirebaseService.joinSharedRoom(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_currentLanguage == 'tr' 
                ? "Davet linki ile \"${joined.title}\" sayacına katıldınız! 🎉" 
                : "Joined \"${joined.title}\" via invite link! 🎉"),
            backgroundColor: const Color(0xFF800020),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final list = await StorageService.loadProfiles();
    final isPrem = await StorageService.isPremiumUser();
    final theme = await StorageService.getThemeMode();
    setState(() {
      _profiles = list;
      _isPremium = isPrem;
      _themeMode = theme;
      _isLoading = false;
    });
  }

  // Toggle Theme Mode
  Future<void> _toggleTheme() async {
    // If not premium, block and prompt premium shop
    if (!_isPremium) {
      _showPremiumShop();
      return;
    }
    
    final newTheme = _themeMode == 'light' ? 'dark' : 'light';
    await StorageService.setThemeMode(newTheme);
    setState(() {
      _themeMode = newTheme;
    });
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      String firstChar = word[0];
      if (firstChar == 'i') {
        firstChar = 'İ';
      } else if (firstChar == 'ı') {
        firstChar = 'I';
      } else {
        firstChar = firstChar.toUpperCase();
      }
      return firstChar + word.substring(1);
    }).join(' ');
  }

  // Adds a new profile
  Future<void> _addNewProfile(String name, String title, String category, String emoji) async {
    final cleanName = _capitalizeWords(name.trim().isEmpty ? "İsimsiz" : name.trim());
    final cleanTitle = _capitalizeWords(title.trim().isEmpty ? _getTxt('titleHint') : title.trim());

    final newProfile = CounterProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanName,
      title: cleanTitle,
      category: category,
      avatarEmoji: emoji,
      resets: [],
    );

    final updated = List<CounterProfile>.from(_profiles)..add(newProfile);
    await StorageService.saveProfiles(updated);
    
    setState(() {
      _profiles = updated;
    });
  }

  // Delete profile
  Future<void> _deleteProfile(String profileId) async {
    final updated = List<CounterProfile>.from(_profiles)
      ..removeWhere((p) => p.id == profileId);
    await StorageService.saveProfiles(updated);
    setState(() {
      _profiles = updated;
    });
  }

  // Direct quick reset from home screen card
  Future<void> _quickResetProfile(CounterProfile profile, String note) async {
    final cleanNote = note.trim().isEmpty 
        ? (_currentLanguage == 'tr' ? "Sebep belirtilmedi 🤫" : "No reason provided 🤫")
        : note.trim();
    
    final roast = RoastGenerator.getRoast(profile.category, profile.name, _currentLanguage);

    final Duration elapsed = profile.resets.isEmpty 
        ? Duration.zero 
        : DateTime.now().difference(profile.resets.first.timestamp);

    final newReset = ResetEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      note: cleanNote,
      roastMessage: roast,
      durationSincePrevious: elapsed,
    );

    int newLongest = profile.longestStreakSeconds;
    if (elapsed.inSeconds > newLongest) {
      newLongest = elapsed.inSeconds;
    }

    final updatedProfile = CounterProfile(
      id: profile.id,
      name: profile.name,
      title: profile.title,
      category: profile.category,
      avatarEmoji: profile.avatarEmoji,
      longestStreakSeconds: newLongest,
      resets: List.from(profile.resets)..insert(0, newReset),
    );

    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx != -1) {
      setState(() {
        _profiles[idx] = updatedProfile;
      });
      await StorageService.saveProfiles(_profiles);
      _showRoastDialog(newReset);
    }
  }

  // Visual helper mapping category colors (adjusts depending on theme mode)
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

  // Format countdown string for profile card
  String _formatCountdownText(CounterProfile p) {
    if (p.resets.isEmpty) return _getTxt('noResetsYet');
    
    final diff = DateTime.now().difference(p.resets.first.timestamp);
    final int days = diff.inDays;
    final int hours = diff.inHours % 24;
    final int minutes = diff.inMinutes % 60;
    final int seconds = diff.inSeconds % 60;

    String text = "";
    if (days > 0) {
      text += "$days ${_getTxt('days')}, $hours ${_getTxt('hours')}";
    } else if (hours > 0) {
      text += "$hours ${_getTxt('hours')}, $minutes ${_getTxt('mins')}";
    } else {
      text += "$minutes ${_getTxt('mins')}, $seconds ${_getTxt('secs')}";
    }
    return text;
  }

  // Form to add a new profile
  void _showAddProfileModal() {
    final nameController = TextEditingController();
    final titleController = TextEditingController();
    String selectedCategory = 'custom';
    String selectedEmoji = '🚗';
    final isDark = _themeMode == 'dark';
    bool isSharedCounter = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              padding: EdgeInsets.only(
                bottom: keyboardInset + (bottomPadding > 0 ? bottomPadding : 16) + 12,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getTxt('addProfileTitle'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTxt('addProfileDesc'),
                        style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 12),
                      ),
                      const SizedBox(height: 14),

                      // Name Input
                      Text(
                        _getTxt('nameLabel'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: "Örn: İsmail",
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF3E8EB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : Colors.black),
                      ),
                      const SizedBox(height: 12),

                      // Title Input
                      Text(
                        _getTxt('titleLabel'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: _getTxt('titleHint'),
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF3E8EB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : Colors.black),
                      ),
                      const SizedBox(height: 14),

                      // Category Selection
                      Text(
                        _getTxt('categoryLabel'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _getCategories().map((cat) {
                          final isSelected = selectedCategory == cat['key'];
                          return ChoiceChip(
                            label: Text(
                              cat['label']!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020)),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                            backgroundColor: _getCategoryColor(cat['key']!),
                            checkmarkColor: Colors.white,
                            elevation: 0,
                            pressElevation: 0,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedCategory = cat['key']!;
                                  if (cat['key'] == 'clumsy') selectedEmoji = '🚗';
                                  else if (cat['key'] == 'meeting') selectedEmoji = '⏰';
                                  else if (cat['key'] == 'diet') selectedEmoji = '🍕';
                                  else if (cat['key'] == 'relationship') selectedEmoji = '💔';
                                  else selectedEmoji = '🏆';
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Emoji avatar picker
                      Text(
                        _getTxt('emojiLabel'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 46,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _emojisList.length,
                          itemBuilder: (context, idx) {
                            final em = _emojisList[idx];
                            final isSelected = selectedEmoji == em;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedEmoji = em;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? (isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020)) 
                                      : (isDark ? const Color(0xFF2C2C32) : Colors.white),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.grey.shade800 : const Color(0xFF800020).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    em == 'Dino' ? '🦖' : em,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Shared Counter Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentLanguage == 'tr' ? "Ortak (Çok Oyunculu) Sayaç" : "Shared (Multiplayer) Counter",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                  ),
                                ),
                                Text(
                                  _currentLanguage == 'tr' ? "Arkadaşlarınızla kodu paylaşarak yönetin" : "Share room code with friends to manage",
                                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: isSharedCounter,
                            activeColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                            onChanged: (val) {
                              setModalState(() {
                                isSharedCounter = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(_getTxt('cancel'), style: const TextStyle(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                if (isSharedCounter) {
                                  await FirebaseService.createSharedRoom(
                                    nameController.text,
                                    titleController.text,
                                    selectedCategory,
                                    selectedEmoji == 'Dino' ? '🦖' : selectedEmoji,
                                  );
                                } else {
                                  _addNewProfile(
                                    nameController.text,
                                    titleController.text,
                                    selectedCategory,
                                    selectedEmoji == 'Dino' ? '🦖' : selectedEmoji,
                                  );
                                }
                              },
                              child: Text(
                                _getTxt('create'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Quick reset dialogue
  void _showQuickResetDialog(CounterProfile p) {
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
            Expanded(
              child: Text(
                _getTxt('quickResetTitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${p.name} - ${_getTxt('quickResetDesc')}",
              style: TextStyle(color: isDark ? Colors.grey.shade300 : const Color(0xFF4A3E3F), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: _getTxt('quickResetHint'),
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
              final text = noteController.text;
              Navigator.pop(context);
              _quickResetProfile(p, text);
            },
            child: Text(_getTxt('confirm'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Delete counter profile confirm
  void _showDeleteProfileConfirm(CounterProfile p) {
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
          _getTxt('deleteProfileDesc').replaceAll('{name}', p.name),
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
              _deleteProfile(p.id);
            },
            child: Text(_getTxt('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Custom Roast dialog overlay after quick reset
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
            child: SingleChildScrollView(
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      _getTxt('roastClose'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  // Custom Animated Premium Shop Dialog
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
                    // Shop Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24), // alignment helper
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
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Feature list
                    _buildShopFeatureRow(_getTxt('shopFeat1'), isDark),
                    const SizedBox(height: 12),
                    _buildShopFeatureRow(_getTxt('shopFeat2'), isDark),
                    const SizedBox(height: 12),
                    _buildShopFeatureRow(_getTxt('shopFeat3'), isDark),
                    const SizedBox(height: 32),

                    // Loading or Buy Button
                    isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF800020)),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF800020),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                setShopState(() {
                                  isProcessing = true;
                                });
                                // Mock transaction delay
                                await Future.delayed(const Duration(milliseconds: 1500));
                                await StorageService.setPremiumUser(true);
                                
                                if (mounted) {
                                  setState(() {
                                    _isPremium = true;
                                  });
                                }

                                setShopState(() {
                                  isProcessing = false;
                                });
                                Navigator.pop(context);
                                
                                // Show confirmation toast/snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_getTxt('shopSuccess')),
                                    backgroundColor: const Color(0xFF800020),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                              child: Text(
                                _getTxt('shopBuy'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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

  // Simulated Bottom AdBanner Widget
  Widget _buildAdBanner() {
    final isDark = _themeMode == 'dark';
    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.only(top: 8),
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
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 36),
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
                  Flexible(
                    child: Text(
                      _getTxt('adBanner'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Close button link to go premium
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

  void _showEditNicknameDialog() {
    final nameController = TextEditingController(text: FirebaseService.displayName);
    final isDark = _themeMode == 'dark';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
        title: Text(
          _currentLanguage == 'tr' ? "Profil İsmi Düzenle" : "Edit Profile Name",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: nameController,
          maxLength: 15,
          decoration: InputDecoration(
            hintText: _currentLanguage == 'tr' ? "Rumuzunuz" : "Your Nickname",
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF3E8EB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_currentLanguage == 'tr' ? "İptal" : "Cancel", style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
               backgroundColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await FirebaseService.updateDisplayName(nameController.text.trim());
                setState(() {});
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              _currentLanguage == 'tr' ? "Kaydet" : "Save",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinRoomDialog() {
    final codeController = TextEditingController();
    final isDark = _themeMode == 'dark';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
        title: Text(
          _currentLanguage == 'tr' ? "Ortak Sayaca Katıl" : "Join Shared Counter",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: codeController,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: "Örn: SF-A93B",
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF3E8EB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_currentLanguage == 'tr' ? "İptal" : "Cancel", style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              
              try {
                final joinedProfile = await FirebaseService.joinSharedRoom(code);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_currentLanguage == 'tr' 
                          ? "Ortak sayaca başarıyla katıldınız! 🎉"
                          : "Successfully joined shared counter! 🎉"),
                      backgroundColor: const Color(0xFF800020),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_currentLanguage == 'tr'
                          ? "Sayaç bulunamadı! Lütfen kodu kontrol edin. ❌"
                          : "Counter not found! Please check the code. ❌"),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              }
            },
            child: Text(
              _currentLanguage == 'tr' ? "Katıl" : "Join",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Handle special emojis
  String _resolveEmoji(String value) {
    if (value.toLowerCase() == 'pizza') return '🍕';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == 'dark';
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121214) : const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: Text(
          _getTxt('title'),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2,
            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFFFAF6F0),
          ),
        ),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFF800020),
        elevation: 0,
        actions: [
          // Widget Studio Button
          IconButton(
            icon: Icon(Icons.widgets_rounded, color: isDark ? const Color(0xFFFF2D55) : const Color(0xFFFAF6F0)),
            tooltip: "Widget Stüdyosu",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WidgetStudioScreen(
                    profiles: _profiles,
                    currentLanguage: _currentLanguage,
                    isDark: isDark,
                  ),
                ),
              );
            },
          ),
          // Theme Toggle Button
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : const Color(0xFFFAF6F0),
            ),
            tooltip: isDark ? "Açık Tema" : "Koyu Tema",
            onPressed: _toggleTheme,
          ),
          // More Settings & Actions Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? const Color(0xFFFF2D55) : const Color(0xFFFAF6F0)),
            tooltip: "Seçenekler",
            onSelected: (val) async {
              switch (val) {
                case 'sound':
                  await SoundService.toggleSound();
                  setState(() {});
                  break;
                case 'nickname':
                  _showEditNicknameDialog();
                  break;
                case 'shop':
                  _showPremiumShop();
                  break;
                case 'lang_tr':
                  setState(() => _currentLanguage = 'tr');
                  break;
                case 'lang_en':
                  setState(() => _currentLanguage = 'en');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sound',
                child: Row(
                  children: [
                    Icon(SoundService.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        SoundService.isSoundEnabled
                            ? (_currentLanguage == 'tr' ? "Ses Efektleri (Açık)" : "Sound FX (On)")
                            : (_currentLanguage == 'tr' ? "Ses Efektleri (Kapalı)" : "Sound FX (Off)"),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'nickname',
                child: Row(
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentLanguage == 'tr' ? "Rumuz Değiştir" : "Change Nickname",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isPremium)
                PopupMenuItem(
                  value: 'shop',
                  child: Row(
                    children: [
                      Icon(Icons.stars_rounded, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _currentLanguage == 'tr' ? "Premium Mağaza" : "Premium Shop",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _currentLanguage == 'tr' ? 'lang_en' : 'lang_tr',
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentLanguage == 'tr' ? "Switch to English 🇬🇧" : "Türkçe'ye Geç 🇹🇷",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020)),
              ),
            )
          : DefaultTabController(
              length: 3,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TabBar(
                      labelColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.person_rounded, size: 18),
                          text: _currentLanguage == 'tr' ? "Bireysel" : "Private",
                        ),
                        Tab(
                          icon: const Icon(Icons.people_alt_rounded, size: 18),
                          text: _currentLanguage == 'tr' ? "Ortak" : "Shared",
                        ),
                        Tab(
                          icon: const Icon(Icons.explore_rounded, size: 18),
                          text: _currentLanguage == 'tr' ? "Keşfet 🌍" : "Explore 🌍",
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildLocalProfilesTab(isDark),
                          _buildSharedRoomsTab(isDark),
                          _buildExploreTab(isDark),
                        ],
                      ),
                    ),
                    if (!_isPremium) _buildAdBanner(),
                  ],
                ),
              ),
            ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _isPremium ? 0 : 54),
        child: FloatingActionButton(
          onPressed: _showAddProfileModal,
          backgroundColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildLocalProfilesTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getTxt('profilesHeader'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                "${_profiles.length} ${_currentLanguage == 'tr' ? 'Sayaç' : 'Counter'}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB57C8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _profiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_customize_outlined, color: Colors.grey.shade600, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          _getTxt('noProfiles'),
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTxt('noProfilesSub'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _profiles.length,
                    itemBuilder: (context, idx) {
                      final p = _profiles[idx];
                      return _buildProfileCard(p, isDark, idx, false);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedRoomsTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF3E8EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE8D0D5).withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentLanguage == 'tr' ? "Katılım Kodunuz mu Var?" : "Have a Room Code?",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF2C2526),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentLanguage == 'tr' ? "Arkadaşının sayacına anında dahil ol" : "Instantly join a friend's counter",
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: _showJoinRoomDialog,
                  icon: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 14),
                  label: Text(
                    _currentLanguage == 'tr' ? "Katıl" : "Join",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<CounterProfile>>(
              stream: FirebaseService.streamSharedRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF800020)));
                }

                final rooms = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currentLanguage == 'tr' ? "ORTAK SAYAÇLAR" : "SHARED COUNTERS",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          "${rooms.length} ${_currentLanguage == 'tr' ? 'Ortak Sayaç' : 'Shared Room'}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB57C8A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: rooms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline_rounded, color: Colors.grey.shade600, size: 60),
                                  const SizedBox(height: 16),
                                  Text(
                                    _currentLanguage == 'tr' ? "Ortak sayaç bulunamadı." : "No shared counters found.",
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade500,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentLanguage == 'tr'
                                        ? "Bir ortak sayaç oluşturun veya katılım kodu girin!"
                                        : "Create a shared counter or enter a room code!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: rooms.length,
                              itemBuilder: (context, idx) {
                                final p = rooms[idx];
                                return _buildProfileCard(p, isDark, idx, true);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(CounterProfile p, bool isDark, int idx, bool isSharedRoom) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileDetailScreen(
              profile: p,
              currentLanguage: _currentLanguage,
              isPremium: _isPremium,
              themeMode: _themeMode,
              onProfileUpdated: (updated) {
                if (!isSharedRoom) {
                  setState(() {
                    _profiles[idx] = updated;
                  });
                }
              },
              onProfileDeleted: (deletedId) {
                if (!isSharedRoom) {
                  _deleteProfile(deletedId);
                }
              },
              onPremiumStatusChanged: (premiumUnlocked) {
                setState(() {
                  _isPremium = premiumUnlocked;
                });
              },
            ),
          ),
        );
      },
      onLongPress: () {
        if (!isSharedRoom) {
          _showDeleteProfileConfirm(p);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E22) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFE8D0D5).withOpacity(0.4),
            width: 1,
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
                  backgroundColor: _getCategoryColor(p.category),
                  child: Text(
                    _resolveEmoji(p.avatarEmoji),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                if (isSharedRoom)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          InviteService.copyLink(roomCode: p.roomCode ?? '');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_currentLanguage == 'tr' ? "Davet linki kopyalandı! 🔗" : "Invite link copied! 🔗"),
                              backgroundColor: const Color(0xFF800020),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFFF2D55).withOpacity(0.15) : const Color(0xFF800020).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.roomCode ?? "",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          InviteService.shareToWhatsApp(
                            counterTitle: p.title,
                            roomCode: p.roomCode ?? '',
                            lang: _currentLanguage,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_rounded, color: Colors.white, size: 10),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showQuickResetDialog(p),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFFCEFF1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.rotate_left_rounded,
                            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showDeleteProfileConfirm(p),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFFCEFF1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red.shade400,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF2C2526),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCountdownText(p),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTxt('resetsCount').replaceAll('{count}', p.resets.length.toString()),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB57C8A),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C1E24), const Color(0xFF1E1E22)]
                    : [const Color(0xFFFDEEF2), const Color(0xFFFAF6F0)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFFFF2D55).withOpacity(0.3) : const Color(0xFFE8D0D5)),
            ),
            child: Row(
              children: [
                const Text("🌍", style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentLanguage == 'tr' ? "Trend & Popüler Sayaçlar" : "Trending & Public Counters",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF2C2526),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentLanguage == 'tr'
                            ? "Türkiye çapında canlı takip edilen ve yorumlanan açık sayaçlar!"
                            : "Live public counters tracked and commented across the community!",
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<PublicCounter>>(
              stream: PublicCountersService.streamPublicCounters(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF800020)));
                }

                final list = snapshot.data ?? [];
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildPublicCounterCard(item, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicCounterCard(PublicCounter counter, bool isDark) {
    final elapsed = DateTime.now().difference(counter.lastResetTime);
    final days = elapsed.inDays;
    final hours = elapsed.inHours % 24;
    final mins = elapsed.inMinutes % 60;
    final secs = elapsed.inSeconds % 60;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicCounterDetailScreen(
              counter: counter,
              currentLanguage: _currentLanguage,
              isPremium: _isPremium,
              themeMode: _themeMode,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFE8D0D5).withOpacity(0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF3E8EB),
                        child: Text(counter.avatarEmoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              counter.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF2C2526),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              counter.locationTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: Color(0xFFB57C8A), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D55).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF2D55), size: 14),
                      const SizedBox(width: 2),
                      Text(
                        "${counter.likesCount}",
                        style: const TextStyle(color: Color(0xFFFF2D55), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              counter.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFF8F4F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${days}g ${hours}s ${mins}d ${secs}sn",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${counter.recentComments.length} Yorum",
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
