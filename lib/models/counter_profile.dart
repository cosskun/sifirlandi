import 'reset_entry.dart';

class CounterProfile {
  final String id;
  final String name;
  final String title;
  final String category; // clumsy, meeting, diet, relationship, custom
  final String avatarEmoji;
  final int longestStreakSeconds;
  final List<ResetEntry> resets;

  // Multiplayer properties
  final bool isShared;
  final String? roomCode;
  final String? creatorId;
  final Map<String, String> members; // userId -> role ('admin', 'editor', 'viewer')
  final Map<String, String> memberNames; // userId -> display name

  CounterProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.category,
    required this.avatarEmoji,
    this.longestStreakSeconds = 0,
    required this.resets,
    this.isShared = false,
    this.roomCode,
    this.creatorId,
    this.members = const {},
    this.memberNames = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'category': category,
      'avatarEmoji': avatarEmoji,
      'longestStreakSeconds': longestStreakSeconds,
      'resets': resets.map((x) => x.toMap()).toList(),
      'isShared': isShared,
      'roomCode': roomCode,
      'creatorId': creatorId,
      'members': members,
      'memberNames': memberNames,
    };
  }

  factory CounterProfile.fromMap(Map<String, dynamic> map) {
    // Safely cast dynamic maps to Map<String, String>
    Map<String, String> castMap(dynamic source) {
      if (source == null) return const {};
      if (source is Map) {
        return source.map((key, val) => MapEntry(key.toString(), val.toString()));
      }
      return const {};
    }

    return CounterProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'custom',
      avatarEmoji: map['avatarEmoji'] ?? '📝',
      longestStreakSeconds: map['longestStreakSeconds'] ?? 0,
      resets: List<ResetEntry>.from(
        (map['resets'] as List<dynamic>? ?? []).map((x) => ResetEntry.fromMap(x)),
      ),
      isShared: map['isShared'] ?? false,
      roomCode: map['roomCode'],
      creatorId: map['creatorId'],
      members: castMap(map['members']),
      memberNames: castMap(map['memberNames']),
    );
  }

  // CopyWith helper to easily mutate instances
  CounterProfile copyWith({
    String? id,
    String? name,
    String? title,
    String? category,
    String? avatarEmoji,
    int? longestStreakSeconds,
    List<ResetEntry>? resets,
    bool? isShared,
    String? roomCode,
    String? creatorId,
    Map<String, String>? members,
    Map<String, String>? memberNames,
  }) {
    return CounterProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      category: category ?? this.category,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      longestStreakSeconds: longestStreakSeconds ?? this.longestStreakSeconds,
      resets: resets ?? this.resets,
      isShared: isShared ?? this.isShared,
      roomCode: roomCode ?? this.roomCode,
      creatorId: creatorId ?? this.creatorId,
      members: members ?? this.members,
      memberNames: memberNames ?? this.memberNames,
    );
  }
}
