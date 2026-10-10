class PenaltyItem {
  final String id;
  final String title;
  final String emoji;
  final String description;

  const PenaltyItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
      'description': description,
    };
  }

  factory PenaltyItem.fromMap(Map<String, dynamic> map) {
    return PenaltyItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      emoji: map['emoji'] ?? '🎯',
      description: map['description'] ?? '',
    );
  }
}
