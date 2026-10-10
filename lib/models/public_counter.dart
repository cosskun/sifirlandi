import 'counter_comment.dart';

class PublicCounter {
  final String id;
  final String title;
  final String description;
  final String category;
  final String avatarEmoji;
  final DateTime lastResetTime;
  final int resetCount;
  final int likesCount;
  final String locationTag;
  final List<CounterComment> recentComments;

  PublicCounter({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.avatarEmoji,
    required this.lastResetTime,
    this.resetCount = 0,
    this.likesCount = 0,
    this.locationTag = 'Türkiye',
    this.recentComments = const [],
  });

  PublicCounter copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? avatarEmoji,
    DateTime? lastResetTime,
    int? resetCount,
    int? likesCount,
    String? locationTag,
    List<CounterComment>? recentComments,
  }) {
    return PublicCounter(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      lastResetTime: lastResetTime ?? this.lastResetTime,
      resetCount: resetCount ?? this.resetCount,
      likesCount: likesCount ?? this.likesCount,
      locationTag: locationTag ?? this.locationTag,
      recentComments: recentComments ?? this.recentComments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'avatarEmoji': avatarEmoji,
      'lastResetTime': lastResetTime.toIso8601String(),
      'resetCount': resetCount,
      'likesCount': likesCount,
      'locationTag': locationTag,
      'recentComments': recentComments.map((c) => c.toMap()).toList(),
    };
  }

  factory PublicCounter.fromMap(Map<String, dynamic> map) {
    return PublicCounter(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'custom',
      avatarEmoji: map['avatarEmoji'] ?? '🚨',
      lastResetTime: map['lastResetTime'] != null
          ? DateTime.tryParse(map['lastResetTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      resetCount: map['resetCount'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
      locationTag: map['locationTag'] ?? 'Türkiye',
      recentComments: (map['recentComments'] as List<dynamic>?)
              ?.map((c) => CounterComment.fromMap(Map<String, dynamic>.from(c)))
              .toList() ??
          [],
    );
  }
}
