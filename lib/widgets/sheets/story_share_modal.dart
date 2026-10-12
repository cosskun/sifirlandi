import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/counter_profile.dart';
import '../../core/constants/app_categories.dart';
import '../../core/theme/app_colors.dart';
import '../../services/sound_service.dart';

class StoryShareModal extends StatefulWidget {
  final CounterProfile profile;
  final Duration activeStreak;
  final String currentLanguage;
  final bool isDark;

  const StoryShareModal({
    super.key,
    required this.profile,
    required this.activeStreak,
    required this.currentLanguage,
    required this.isDark,
  });

  @override
  State<StoryShareModal> createState() => _StoryShareModalState();
}

class _StoryShareModalState extends State<StoryShareModal> {
  final GlobalKey _cardKey = GlobalKey();
  int _selectedGradientIdx = 0;
  bool _isSharing = false;

  final List<List<Color>> _storyGradients = [
    [const Color(0xFF800020), const Color(0xFF140006)], // Classic Deep Burgundy
    [const Color(0xFFFF2D55), const Color(0xFF4A0012)], // Neon Crimson
    [const Color(0xFF111118), const Color(0xFF000000)], // Pure Obsidian
    [const Color(0xFF5856D6), const Color(0xFF1B1A40)], // Deep Indigo
    [const Color(0xFF00C7BE), const Color(0xFF003836)], // Cyber Emerald
    [const Color(0xFFFF9500), const Color(0xFF4A2800)], // Amber Gold
  ];

  Future<void> _captureAndShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    SoundService.play(SoundEffect.click);

    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          final days = widget.activeStreak.inDays;
          final isTr = widget.currentLanguage == 'tr';
          final text = isTr
              ? "🔥 ${widget.profile.name} tam $days gündür sıfırlanmadı! #Sıfırlandı"
              : "🔥 ${widget.profile.name} has not reset for $days days! #Reseted";

          await SharePlus.instance.share(
            ShareParams(
              text: text,
              files: [
                XFile.fromData(
                  pngBytes,
                  mimeType: 'image/png',
                  name: 'sifirlandi_story_${widget.profile.id}.png',
                )
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Share Error: $e");
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final gradient = _storyGradients[_selectedGradientIdx];
    final days = widget.activeStreak.inDays;
    final hours = widget.activeStreak.inHours % 24;
    final minutes = widget.activeStreak.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.currentLanguage == 'tr' ? "Hikayede Paylaş 📸" : "Share Story 📸",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary(isDark),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textPrimary(isDark)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 9:16 Story Card Preview (Fitted)
          RepaintBoundary(
            key: _cardKey,
            child: AspectRatio(
              aspectRatio: 9 / 13,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top App Header & Category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              Text("🚨", style: TextStyle(fontSize: 14)),
                              SizedBox(width: 4),
                              Text(
                                "SIFIRLANDI!",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppCategories.getLabel(widget.profile.category, widget.currentLanguage).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),

                    // Center Big Number & Person Info
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            widget.profile.avatarEmoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.profile.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Days Counter Display
                        Text(
                          days.toString(),
                          style: const TextStyle(
                            fontSize: 76,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Courier',
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          widget.currentLanguage == 'tr' ? "GÜNDÜR SIFIRLANMADI" : "DAYS STREAK",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Sub-stats Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "${days}g ${hours}s ${minutes}d",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gradient Color Selectors
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _storyGradients.length,
              itemBuilder: (ctx, idx) {
                final isSelected = _selectedGradientIdx == idx;
                return GestureDetector(
                  onTap: () {
                    SoundService.play(SoundEffect.click);
                    setState(() => _selectedGradientIdx = idx);
                  },
                  child: Container(
                    width: 38,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: _storyGradients[idx]),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Share Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentNeonCrimson,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: _isSharing ? null : _captureAndShare,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: Text(
                _isSharing
                    ? (widget.currentLanguage == 'tr' ? "Hazırlanıyor..." : "Preparing...")
                    : (widget.currentLanguage == 'tr' ? "HİKAYEDE PAYLAŞ" : "SHARE TO STORY"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
