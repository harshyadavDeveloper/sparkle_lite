class FamilyMember {
  final String id;
  final String userId; // owner's userId — keeps data scoped
  final String name;
  final String relationship;
  final String ageRange;
  final String? notes;
  final List<String> conditions;
  final List<String> medications;
  final String? doctorName;
  final String? doctorContact;
  final String? bloodGroup;
  final DateTime createdAt;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    required this.ageRange,
    this.notes,
    this.conditions = const [],
    this.medications = const [],
    this.doctorName,
    this.doctorContact,
    this.bloodGroup,
    required this.createdAt,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) => FamilyMember(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    name: map['name'] ?? '',
    relationship: map['relationship'] ?? '',
    ageRange: map['ageRange'] ?? '',
    notes: map['notes'],
    conditions: List<String>.from(map['conditions'] ?? []),
    medications: List<String>.from(map['medications'] ?? []),
    doctorName: map['doctorName'],
    doctorContact: map['doctorContact'],
    bloodGroup: map['bloodGroup'],
    createdAt: DateTime.parse(map['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'relationship': relationship,
    'ageRange': ageRange,
    'notes': notes,
    'conditions': conditions,
    'medications': medications,
    'doctorName': doctorName,
    'doctorContact': doctorContact,
    'bloodGroup': bloodGroup,
    'createdAt': createdAt.toIso8601String(),
  };
}
