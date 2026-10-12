import 'dart:async';
import 'package:flutter/material.dart';
import '../models/counter_profile.dart';
import '../services/sound_service.dart';

class WidgetStudioScreen extends StatefulWidget {
  final List<CounterProfile> profiles;
  final String currentLanguage;
  final bool isDark;

  const WidgetStudioScreen({
    super.key,
    required this.profiles,
    required this.currentLanguage,
    required this.isDark,
  });

  @override
  State<WidgetStudioScreen> createState() => _WidgetStudioScreenState();
}

class _WidgetStudioScreenState extends State<WidgetStudioScreen> {
  late CounterProfile _selectedProfile;
  String _selectedTheme = 'cyber'; // cyber, obsidian, burgundy, emerald
  late Timer _ticker;

  @override
  void initState() {
    super.initState();
    _selectedProfile = widget.profiles.isNotEmpty
        ? widget.profiles.first
        : CounterProfile(
            id: 'sample',
            name: 'Ahmet',
            title: 'Diyeti Bozmama',
            category: 'diet',
            avatarEmoji: '🥗',
            resets: [],
          );

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Duration _getActiveStreak(CounterProfile p) {
    if (p.resets.isEmpty) return const Duration(days: 4, hours: 14, minutes: 22, seconds: 10);
    final lastReset = p.resets.last.timestamp;
    return DateTime.now().difference(lastReset);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final streak = _getActiveStreak(_selectedProfile);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.currentLanguage == 'tr' ? "Ana Ekran Widget Stüdyosu 🧩" : "Widget Studio 🧩",
          style: TextStyle(
            color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subtitle
            Text(
              widget.currentLanguage == 'tr'
                  ? "Telefonunuzun ana ekranına ekleyeceğiniz canlı sayacı özelleştirin:"
                  : "Customize the live counter widget for your phone's home screen:",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            // Live Phone Screen Mockup Preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.grey.shade800, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020)).withOpacity(0.2),
                    blurRadius: 25,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                children: [
                  // Phone Status Bar mock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "09:41",
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: const [
                          Icon(Icons.wifi, color: Colors.white70, size: 12),
                          SizedBox(width: 4),
                          Icon(Icons.battery_full_rounded, color: Colors.white70, size: 14),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // The Live Simulated Widget
                  _buildSimulatedWidget(_selectedProfile, streak),
                  const SizedBox(height: 28),

                  // Home indicator bar
                  Container(
                    width: 100,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Counter Selector
            Text(
              widget.currentLanguage == 'tr' ? "1. GÖSTERİLECEK SAYAÇ" : "1. SELECT COUNTER",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE8D0D5)),
              ),
              child: Builder(
                builder: (context) {
                  final displayProfiles = widget.profiles.isNotEmpty ? widget.profiles : [_selectedProfile];
                  final currentValue = displayProfiles.contains(_selectedProfile) ? _selectedProfile : displayProfiles.first;

                  return DropdownButtonHideUnderline(
                    child: DropdownButton<CounterProfile>(
                      value: currentValue,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
                      items: displayProfiles.map((p) {
                        return DropdownMenuItem<CounterProfile>(
                          value: p,
                          child: Row(
                            children: [
                              Text(p.avatarEmoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          SoundService.play(SoundEffect.click);
                          setState(() => _selectedProfile = val);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 2. Widget Theme
            Text(
              widget.currentLanguage == 'tr' ? "2. WIDGET TEMASI" : "2. WIDGET THEME",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: isDark ? const Color(0xFFFF2D55) : const Color(0xFF800020),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildThemeChip('cyber', '⚡ Cyber Neon', const Color(0xFFFF2D55)),
                const SizedBox(width: 8),
                _buildThemeChip('obsidian', '🖤 Obsidian', const Color(0xFF2C2C32)),
                const SizedBox(width: 8),
                _buildThemeChip('burgundy', '🍷 Bordo', const Color(0xFF800020)),
              ],
            ),
            const SizedBox(height: 24),

            // Save / Install Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
              ),
              onPressed: () {
                SoundService.play(SoundEffect.victory);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.currentLanguage == 'tr'
                        ? "Widget ayarları kaydedildi! Ana ekranınızdan 'Sıfırlandı!' widget'ını ekleyebilirsiniz. 📲"
                        : "Widget settings saved! You can add the 'Sıfırlandı!' widget from your home screen. 📲"),
                    backgroundColor: const Color(0xFF800020),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                widget.currentLanguage == 'tr' ? "WIDGET'I KAYDET & ETKİNLEŞTİR" : "SAVE & ACTIVATE WIDGET",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(String id, String label, Color color) {
    final isSelected = _selectedTheme == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          SoundService.play(SoundEffect.click);
          setState(() => _selectedTheme = id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.white : color,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatedWidget(CounterProfile profile, Duration streak) {
    Color bg = const Color(0xFF1E1E22);
    Color accent = const Color(0xFFFF2D55);

    if (_selectedTheme == 'cyber') {
      bg = const Color(0xFF16161E);
      accent = const Color(0xFFFF2D55);
    } else if (_selectedTheme == 'obsidian') {
      bg = const Color(0xFF0D0D11);
      accent = Colors.white;
    } else if (_selectedTheme == 'burgundy') {
      bg = const Color(0xFF330511);
      accent = const Color(0xFFFF7597);
    }

    final days = streak.inDays;
    final hours = streak.inHours % 24;
    final minutes = streak.inMinutes % 60;
    final seconds = streak.inSeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
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
                    Text(profile.avatarEmoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        profile.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "SIFIRLANDI!",
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ticker display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDigit(days.toString(), "GÜN", accent),
              _buildDigit(hours.toString().padLeft(2, '0'), "SAAT", accent),
              _buildDigit(minutes.toString().padLeft(2, '0'), "DAK", accent),
              _buildDigit(seconds.toString().padLeft(2, '0'), "SN", accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigit(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontFamily: 'Courier',
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ],
    );
  }
}
