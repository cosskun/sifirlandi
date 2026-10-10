class ResetEntry {
  final String id;
  final DateTime timestamp;
  final String note;
  final String roastMessage;
  final Duration durationSincePrevious;

  ResetEntry({
    required this.id,
    required this.timestamp,
    required this.note,
    required this.roastMessage,
    required this.durationSincePrevious,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'roastMessage': roastMessage,
      'durationSincePreviousMs': durationSincePrevious.inMilliseconds,
    };
  }

  factory ResetEntry.fromMap(Map<String, dynamic> map) {
    return ResetEntry(
      id: map['id'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      note: map['note'] ?? '',
      roastMessage: map['roastMessage'] ?? '',
      durationSincePrevious: Duration(milliseconds: map['durationSincePreviousMs'] ?? 0),
    );
  }
}
