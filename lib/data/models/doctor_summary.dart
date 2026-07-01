class DoctorSummary {
  final String id;
  final String userId;
  final String profileSnapshot;
  final List<String> recentSymptoms;
  final List<String> periodHistory;
  final List<String> uploadedRecordTitles;
  final List<String> currentMedications;
  final List<String> questionsForDoctor;
  final String? userNotes;
  final DateTime generatedAt;

  DoctorSummary({
    required this.id,
    required this.userId,
    required this.profileSnapshot,
    required this.recentSymptoms,
    required this.periodHistory,
    required this.uploadedRecordTitles,
    required this.currentMedications,
    required this.questionsForDoctor,
    this.userNotes,
    required this.generatedAt,
  });

  factory DoctorSummary.fromMap(Map<String, dynamic> map) => DoctorSummary(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    profileSnapshot: map['profileSnapshot'] ?? '',
    recentSymptoms: List<String>.from(map['recentSymptoms'] ?? []),
    periodHistory: List<String>.from(map['periodHistory'] ?? []),
    uploadedRecordTitles: List<String>.from(map['uploadedRecordTitles'] ?? []),
    currentMedications: List<String>.from(map['currentMedications'] ?? []),
    questionsForDoctor: List<String>.from(map['questionsForDoctor'] ?? []),
    userNotes: map['userNotes'],
    generatedAt: DateTime.parse(map['generatedAt']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'profileSnapshot': profileSnapshot,
    'recentSymptoms': recentSymptoms,
    'periodHistory': periodHistory,
    'uploadedRecordTitles': uploadedRecordTitles,
    'currentMedications': currentMedications,
    'questionsForDoctor': questionsForDoctor,
    'userNotes': userNotes,
    'generatedAt': generatedAt.toIso8601String(),
  };
}
