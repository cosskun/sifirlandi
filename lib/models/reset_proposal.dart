class ResetProposal {
  final String id;
  final String counterId;
  final String proposerName;
  final String targetName;
  final String allegedReason;
  final DateTime createdAt;
  final DateTime expiresAt;
  final Map<String, bool> votes; // userId -> true (approve reset) or false (veto)
  final String status; // 'pending', 'approved', 'vetoed'

  ResetProposal({
    required this.id,
    required this.counterId,
    required this.proposerName,
    required this.targetName,
    required this.allegedReason,
    required this.createdAt,
    required this.expiresAt,
    this.votes = const {},
    this.status = 'pending',
  });

  int get yesVotes => votes.values.where((v) => v == true).length;
  int get noVotes => votes.values.where((v) => v == false).length;
  int get totalVotes => votes.length;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'counterId': counterId,
      'proposerName': proposerName,
      'targetName': targetName,
      'allegedReason': allegedReason,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'votes': votes.map((k, v) => MapEntry(k, v)),
      'status': status,
    };
  }

  factory ResetProposal.fromMap(Map<String, dynamic> map) {
    final rawVotes = map['votes'] as Map<dynamic, dynamic>? ?? {};
    final parsedVotes = rawVotes.map((k, v) => MapEntry(k.toString(), v == true));

    return ResetProposal(
      id: map['id'] ?? '',
      counterId: map['counterId'] ?? '',
      proposerName: map['proposerName'] ?? 'Biri',
      targetName: map['targetName'] ?? 'Arkadaş',
      allegedReason: map['allegedReason'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'])
          : DateTime.now().add(const Duration(seconds: 60)),
      votes: parsedVotes,
      status: map['status'] ?? 'pending',
    );
  }
}
