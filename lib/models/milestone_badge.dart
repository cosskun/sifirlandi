class MilestoneBadge {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final int targetDays;
  final String tier; // bronze, silver, gold, diamond, legendary

  const MilestoneBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.targetDays,
    required this.tier,
  });

  bool isUnlocked(Duration currentStreak) {
    return currentStreak.inDays >= targetDays;
  }
}
