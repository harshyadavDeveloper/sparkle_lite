class AiInsight {
  final String id;
  final String userId;
  final String summary;
  final String possiblePattern;
  final String careGuidance;
  final List<String> doctorQuestions;
  final String disclaimer;
  final DateTime createdAt;

  AiInsight({
    required this.id,
    required this.userId,
    required this.summary,
    required this.possiblePattern,
    required this.careGuidance,
    required this.doctorQuestions,
    required this.disclaimer,
    required this.createdAt,
  });

  factory AiInsight.fromMap(Map<String, dynamic> map) => AiInsight(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        summary: map['summary'] ?? '',
        possiblePattern: map['possiblePattern'] ?? '',
        careGuidance: map['careGuidance'] ?? '',
        doctorQuestions: List<String>.from(map['doctorQuestions'] ?? []),
        disclaimer: map['disclaimer'] ??
            'This is not a diagnosis and does not replace medical advice.',
        createdAt: DateTime.parse(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'summary': summary,
        'possiblePattern': possiblePattern,
        'careGuidance': careGuidance,
        'doctorQuestions': doctorQuestions,
        'disclaimer': disclaimer,
        'createdAt': createdAt.toIso8601String(),
      };
}