import 'dart:convert';

class Accident {
  final String id;
  final DateTime timestamp;
  final String description;
  final String mockingMessage;

  Accident({
    required this.id,
    required this.timestamp,
    required this.description,
    required this.mockingMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'mockingMessage': mockingMessage,
    };
  }

  factory Accident.fromMap(Map<String, dynamic> map) {
    return Accident(
      id: map['id'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      description: map['description'] ?? '',
      mockingMessage: map['mockingMessage'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Accident.fromJson(String source) => Accident.fromMap(json.decode(source));
}
