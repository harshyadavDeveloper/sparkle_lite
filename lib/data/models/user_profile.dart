class UserProfile {
  final String userId;
  final String displayName;
  final String ageRange;
  final String lifeStage;
  final String menstrualCycleStatus;
  final List<String> knownConditions;
  final List<String> currentMedications;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.ageRange,
    required this.lifeStage,
    required this.menstrualCycleStatus,
    this.knownConditions = const [],
    this.currentMedications = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    userId: map['userId'] ?? '',
    displayName: map['displayName'] ?? '',
    ageRange: map['ageRange'] ?? '',
    lifeStage: map['lifeStage'] ?? '',
    menstrualCycleStatus: map['menstrualCycleStatus'] ?? '',
    knownConditions: List<String>.from(map['knownConditions'] ?? []),
    currentMedications: List<String>.from(map['currentMedications'] ?? []),
    createdAt: DateTime.parse(map['createdAt']),
    updatedAt: DateTime.parse(map['updatedAt']),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'displayName': displayName,
    'ageRange': ageRange,
    'lifeStage': lifeStage,
    'menstrualCycleStatus': menstrualCycleStatus,
    'knownConditions': knownConditions,
    'currentMedications': currentMedications,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
