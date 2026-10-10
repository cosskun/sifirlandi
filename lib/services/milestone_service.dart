import '../models/milestone_badge.dart';

class MilestoneService {
  static const List<MilestoneBadge> badges = [
    MilestoneBadge(
      id: 'm1',
      title: 'İlk Adım',
      description: '24 saati başarıyla tamamladın!',
      iconEmoji: '🌱',
      targetDays: 1,
      tier: 'bronze',
    ),
    MilestoneBadge(
      id: 'm3',
      title: 'İlk Viraj',
      description: '3 gün boyunca krizi atlattın!',
      iconEmoji: '🥉',
      targetDays: 3,
      tier: 'bronze',
    ),
    MilestoneBadge(
      id: 'm7',
      title: 'Çelik İrade',
      description: 'Tam 1 hafta boyunca sıfırlanmadın!',
      iconEmoji: '🥈',
      targetDays: 7,
      tier: 'silver',
    ),
    MilestoneBadge(
      id: 'm14',
      title: 'Alışkanlık Canavarı',
      description: '2 haftalık disiplin rekoru!',
      iconEmoji: '🦁',
      targetDays: 14,
      tier: 'silver',
    ),
    MilestoneBadge(
      id: 'm30',
      title: 'Efsane Seviyesi',
      description: '1 aylık mükemmel seri!',
      iconEmoji: '🥇',
      targetDays: 30,
      tier: 'gold',
    ),
    MilestoneBadge(
      id: 'm60',
      title: 'Durdurulamaz',
      description: '60 günlük çelik disiplin!',
      iconEmoji: '⚡',
      targetDays: 60,
      tier: 'diamond',
    ),
    MilestoneBadge(
      id: 'm100',
      title: 'İrade Tanrısı',
      description: '100 gün boyunca sıfırlanmayan ölümsüzlük!',
      iconEmoji: '💎',
      targetDays: 100,
      tier: 'legendary',
    ),
  ];

  static List<MilestoneBadge> getUnlockedBadges(Duration activeStreak) {
    return badges.where((b) => b.isUnlocked(activeStreak)).toList();
  }

  static MilestoneBadge? getNextMilestone(Duration activeStreak) {
    for (var b in badges) {
      if (!b.isUnlocked(activeStreak)) {
        return b;
      }
    }
    return null; // All unlocked
  }

  static double calculateProgress(Duration activeStreak) {
    final next = getNextMilestone(activeStreak);
    if (next == null) return 1.0;
    
    // Find previous badge threshold
    int prevDays = 0;
    for (var b in badges) {
      if (b.targetDays < next.targetDays) {
        prevDays = b.targetDays;
      }
    }

    final currentDays = activeStreak.inDays;
    final totalSpan = next.targetDays - prevDays;
    final currentSpan = currentDays - prevDays;

    if (totalSpan <= 0) return 0.0;
    return (currentSpan / totalSpan).clamp(0.0, 1.0);
  }
}
