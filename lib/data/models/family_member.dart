class FamilyMember {
  final String id;
  final String userId; // owner's userId — keeps data scoped
  final String name;
  final String relationship;
  final String ageRange;
  final String? notes;
  final DateTime createdAt;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    required this.ageRange,
    this.notes,
    required this.createdAt,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) => FamilyMember(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        name: map['name'] ?? '',
        relationship: map['relationship'] ?? '',
        ageRange: map['ageRange'] ?? '',
        notes: map['notes'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'relationship': relationship,
        'ageRange': ageRange,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };
}