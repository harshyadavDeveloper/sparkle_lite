class SymptomLog {
  final String id;
  final String userId;
  final DateTime date;
  final String periodStatus; // no_period, started, ongoing, ended
  final String flowLevel;    // none, light, medium, heavy
  final int painLevel;       // 0–10
  final String mood;         // calm, anxious, tired, irritable, happy, sad
  final List<String> symptoms;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SymptomLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.periodStatus,
    required this.flowLevel,
    required this.painLevel,
    required this.mood,
    this.symptoms = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SymptomLog.fromMap(Map<String, dynamic> map) => SymptomLog(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        date: DateTime.parse(map['date']),
        periodStatus: map['periodStatus'] ?? '',
        flowLevel: map['flowLevel'] ?? 'none',
        painLevel: map['painLevel'] ?? 0,
        mood: map['mood'] ?? '',
        symptoms: List<String>.from(map['symptoms'] ?? []),
        notes: map['notes'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'date': date.toIso8601String(),
        'periodStatus': periodStatus,
        'flowLevel': flowLevel,
        'painLevel': painLevel,
        'mood': mood,
        'symptoms': symptoms,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}