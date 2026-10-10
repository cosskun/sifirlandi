class CounterComment {
  final String id;
  final String counterId;
  final String authorName;
  final String content;
  final DateTime timestamp;
  final String reactionEmoji;
  final int likes;

  CounterComment({
    required this.id,
    required this.counterId,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.reactionEmoji = '💬',
    this.likes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'counterId': counterId,
      'authorName': authorName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'reactionEmoji': reactionEmoji,
      'likes': likes,
    };
  }

  factory CounterComment.fromMap(Map<String, dynamic> map) {
    return CounterComment(
      id: map['id'] ?? '',
      counterId: map['counterId'] ?? '',
      authorName: map['authorName'] ?? 'Anonim',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reactionEmoji: map['reactionEmoji'] ?? '💬',
      likes: map['likes'] ?? 0,
    );
  }
}
