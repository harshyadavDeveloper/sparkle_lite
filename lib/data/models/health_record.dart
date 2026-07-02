class HealthRecord {
  final String id;
  final String userId;
  final String title;
  final String
  recordType; // lab_report, prescription, scan, doctor_note, vaccination, other
  final DateTime recordDate;
  final String? doctorName;
  final String? fileUrl;
  final String? localFilePath;
  final String? notes;
  final DateTime createdAt;

  HealthRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.recordType,
    required this.recordDate,
    this.doctorName,
    this.fileUrl,
    this.localFilePath,
    this.notes,
    required this.createdAt,
  });

  factory HealthRecord.fromMap(Map<String, dynamic> map) => HealthRecord(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    title: map['title'] ?? '',
    recordType: map['recordType'] ?? '',
    recordDate: DateTime.parse(map['recordDate']),
    doctorName: map['doctorName'],
    fileUrl: map['fileUrl'],
    notes: map['notes'],
    createdAt: DateTime.parse(map['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'recordType': recordType,
    'recordDate': recordDate.toIso8601String(),
    'doctorName': doctorName,
    'fileUrl': fileUrl,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };
}
