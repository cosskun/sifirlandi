import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/counter_profile.dart';
import '../models/reset_entry.dart';

class StorageService {
  static const String _keyProfiles = 'sifirlandi_profiles';
  static const String _keyOldAccidents = 'ismail_accidents';
  static const String _keyPremium = 'sifirlandi_is_premium';
  static const String _keyThemeMode = 'sifirlandi_theme_mode';

  // Loads the list of profiles from SharedPreferences, handling migration and defaults
  static Future<List<CounterProfile>> loadProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? profilesJson = prefs.getStringList(_keyProfiles);

      if (profilesJson == null) {
        // Run migration or setup defaults
        return await _migrateOrSetupDefaults(prefs);
      }

      return profilesJson
          .map((item) => CounterProfile.fromMap(json.decode(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Saves the list of profiles
  static Future<bool> saveProfiles(List<CounterProfile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> profilesJson =
          profiles.map((item) => json.encode(item.toMap())).toList();
      return await prefs.setStringList(_keyProfiles, profilesJson);
    } catch (e) {
      return false;
    }
  }

  // Helper to migrate old accidents data or create default mock profiles
  static Future<List<CounterProfile>> _migrateOrSetupDefaults(SharedPreferences prefs) async {
    final List<CounterProfile> initialProfiles = [];

    // Check if there is old data to migrate
    final List<String>? oldAccidentsJson = prefs.getStringList(_keyOldAccidents);
    List<ResetEntry> migratedResets = [];

    if (oldAccidentsJson != null && oldAccidentsJson.isNotEmpty) {
      try {
        DateTime? previousTime;
        // Sort chronologically to calculate elapsed time correctly
        final oldAccidents = oldAccidentsJson
            .map((item) => json.decode(item))
            .toList()
          ..sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

        for (var acc in oldAccidents) {
          final time = DateTime.parse(acc['timestamp']);
          final duration = previousTime == null ? Duration.zero : time.difference(previousTime);
          
          migratedResets.add(ResetEntry(
            id: acc['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: time,
            note: acc['description'] ?? '',
            roastMessage: acc['mockingMessage'] ?? '',
            durationSincePrevious: duration,
          ));
          previousTime = time;
        }
        // Reverse back to most recent first
        migratedResets = migratedResets.reversed.toList();
      } catch (e) {
        // Fallback if parsing old data fails
        migratedResets = [];
      }
    }

    // 1. Create İsmail's Profile (using migrated data if present)
    initialProfiles.add(CounterProfile(
      id: 'ismail_default',
      name: 'İsmail',
      title: 'Kaza Yapmadığı Süre',
      category: 'clumsy',
      avatarEmoji: '🚗',
      longestStreakSeconds: _calculateLongestStreak(migratedResets),
      resets: migratedResets,
    ));

    // 2. Pre-populate some other fun profiles if we don't have migrated data
    if (migratedResets.isEmpty) {
      initialProfiles.addAll([
        CounterProfile(
          id: 'ahmet_default',
          name: 'Ahmet',
          title: 'Espri Yapıp Ortamı Soğutmadığı Süre',
          category: 'custom',
          avatarEmoji: '🤦‍♂️',
          longestStreakSeconds: 345600, // 4 Days placeholder rekor
          resets: [
            ResetEntry(
              id: 'ahmet_r1',
              timestamp: DateTime.now().subtract(const Duration(days: 4)),
              note: 'İğrenç bir kelime oyunu yaptı, göz devirdik.',
              roastMessage: 'Ah Ahmet vah Ahmet...',
              durationSincePrevious: Duration.zero,
            )
          ],
        ),
        CounterProfile(
          id: 'elif_default',
          name: 'Elif',
          title: 'Diyeti Bozmadığı Süre',
          category: 'diet',
          avatarEmoji: 'Pizza', // Handled as 🍕
          longestStreakSeconds: 172800, // 2 Days placeholder rekor
          resets: [
            ResetEntry(
              id: 'elif_r1',
              timestamp: DateTime.now().subtract(const Duration(days: 2)),
              note: 'Gece saat 11\'de waffle sipariş etti.',
              roastMessage: 'Diyet yalan oldu, yaşasın yemek yemek! Elif yine dayanamadı 🍕',
              durationSincePrevious: Duration.zero,
            )
          ],
        )
      ]);
    }

    // Save newly initialized profiles list
    await saveProfiles(initialProfiles);
    return initialProfiles;
  }

  // Helper to calculate longest streak in seconds from reset logs
  static int _calculateLongestStreak(List<ResetEntry> resets) {
    if (resets.isEmpty) return 0;
    if (resets.length == 1) {
      return DateTime.now().difference(resets.first.timestamp).inSeconds;
    }

    int maxStreak = DateTime.now().difference(resets.first.timestamp).inSeconds;

    for (int i = 0; i < resets.length - 1; i++) {
      final streak = resets[i].timestamp.difference(resets[i + 1].timestamp).inSeconds;
      if (streak > maxStreak) {
        maxStreak = streak;
      }
    }
    return maxStreak;
  }

  // Checks if the user is a Premium user
  static Future<bool> isPremiumUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPremium) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Sets the Premium user status
  static Future<bool> setPremiumUser(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_keyPremium, value);
    } catch (e) {
      return false;
    }
  }

  // Gets the saved app theme mode (light or dark, default is light)
  static Future<String> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyThemeMode) ?? 'light';
    } catch (e) {
      return 'light';
    }
  }

  // Saves the app theme mode
  static Future<bool> setThemeMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyThemeMode, mode);
    } catch (e) {
      return false;
    }
  }
}
