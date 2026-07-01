import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_lite/data/models/health_record.dart';

void main() {
  group('HealthRecord Model', () {
    final now = DateTime.now();

    final testRecord = HealthRecord(
      id: 'record_001',
      userId: 'user_123',
      title: 'Blood Test Report',
      recordType: 'lab_report',
      recordDate: now,
      doctorName: 'Dr. Rao',
      notes: 'Uploaded before gynaecology appointment.',
      createdAt: now,
    );

    test('should create HealthRecord with correct values', () {
      expect(testRecord.title, 'Blood Test Report');
      expect(testRecord.recordType, 'lab_report');
      expect(testRecord.doctorName, 'Dr. Rao');
    });

    test('toMap() and fromMap() roundtrip works correctly', () {
      final map = testRecord.toMap();
      final restored = HealthRecord.fromMap(map);

      expect(restored.id, testRecord.id);
      expect(restored.title, testRecord.title);
      expect(restored.recordType, testRecord.recordType);
      expect(restored.doctorName, testRecord.doctorName);
      expect(restored.notes, testRecord.notes);
    });

    test('fileUrl and doctorName should be optional', () {
      final minimalRecord = HealthRecord(
        id: 'record_002',
        userId: 'user_123',
        title: 'Vaccination Record',
        recordType: 'vaccination',
        recordDate: now,
        createdAt: now,
      );
      expect(minimalRecord.fileUrl, isNull);
      expect(minimalRecord.doctorName, isNull);
    });

    test('valid record types are accepted', () {
      const validTypes = [
        'lab_report',
        'prescription',
        'scan',
        'doctor_note',
        'vaccination',
        'other',
      ];
      expect(validTypes, contains(testRecord.recordType));
    });
  });
}
