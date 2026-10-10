import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/milestone_badge.dart';
import 'confetti_overlay.dart';
import '../services/sound_service.dart';

class MilestoneCertificateDialog extends StatelessWidget {
  final MilestoneBadge badge;
  final String userName;
  final String counterTitle;
  final String currentLanguage;
  final bool isDark;

  const MilestoneCertificateDialog({
    super.key,
    required this.badge,
    required this.userName,
    required this.counterTitle,
    required this.currentLanguage,
    required this.isDark,
  });

  void _shareCertificate() {
    final text = """🏆 SIFIRLANDI! BAŞARI ROZETİ KAZANILDI! 🌟

$userName, "$counterTitle" sayacında tam ${badge.targetDays} GÜN boyunca sıfırlanmayarak "${badge.title}" rozetini açtı! 🏅
"${badge.description}"

İrade seviyesi: EFSANE! 🔥💪""";

    Share.share(text, subject: "Sıfırlandı! Başarı Rozeti");
  }

  @override
  Widget build(BuildContext context) {
    SoundService.play(SoundEffect.victory);

    return ConfettiCelebration(
      isPlaying: true,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF6F0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Icon with Glowing Circle
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700),
                      const Color(0xFFFF8C00),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    badge.iconEmoji,
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                currentLanguage == 'tr' ? "YENİ ROZET AÇILDI! 🎉" : "NEW BADGE UNLOCKED! 🎉",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                badge.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF2C2526),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),

              // Streak stats pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C1E24) : const Color(0xFFFDEEF2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.4)),
                ),
                child: Text(
                  currentLanguage == 'tr'
                      ? "🔥 ${badge.targetDays} Günlük Kusursuz Seri"
                      : "🔥 ${badge.targetDays} Days Streak",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF2D55),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        currentLanguage == 'tr' ? "Kapat" : "Close",
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 3,
                      ),
                      onPressed: _shareCertificate,
                      icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                      label: Text(
                        currentLanguage == 'tr' ? "Paylaş" : "Share",
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
  }
}
