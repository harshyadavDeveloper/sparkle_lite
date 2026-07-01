import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_lite/data/models/symptom_log.dart';

void main() {
  group('SymptomLog Model', () {
    final now = DateTime.now();

    final testLog = SymptomLog(
      id: 'log_001',
      userId: 'user_123',
      date: now,
      periodStatus: 'ongoing',
      flowLevel: 'medium',
      painLevel: 6,
      mood: 'tired',
      symptoms: ['cramps', 'bloating'],
      notes: 'Pain increased in the evening.',
      createdAt: now,
      updatedAt: now,
    );

    test('should create SymptomLog with correct values', () {
      expect(testLog.id, 'log_001');
      expect(testLog.userId, 'user_123');
      expect(testLog.periodStatus, 'ongoing');
      expect(testLog.flowLevel, 'medium');
      expect(testLog.painLevel, 6);
      expect(testLog.mood, 'tired');
      expect(testLog.symptoms, contains('cramps'));
      expect(testLog.notes, isNotNull);
    });

    test('toMap() should serialize all fields correctly', () {
      final map = testLog.toMap();

      expect(map['id'], 'log_001');
      expect(map['userId'], 'user_123');
      expect(map['periodStatus'], 'ongoing');
      expect(map['flowLevel'], 'medium');
      expect(map['painLevel'], 6);
      expect(map['mood'], 'tired');
      expect(map['symptoms'], isA<List>());
      expect(map['notes'], 'Pain increased in the evening.');
    });

    test('fromMap() should deserialize correctly', () {
      final map = testLog.toMap();
      final restored = SymptomLog.fromMap(map);

      expect(restored.id, testLog.id);
      expect(restored.userId, testLog.userId);
      expect(restored.painLevel, testLog.painLevel);
      expect(restored.symptoms.length, testLog.symptoms.length);
      expect(restored.notes, testLog.notes);
    });

    test('pain level should be between 0 and 10', () {
      expect(testLog.painLevel, greaterThanOrEqualTo(0));
      expect(testLog.painLevel, lessThanOrEqualTo(10));
    });

    test('symptoms list should support multiple entries', () {
      expect(testLog.symptoms.length, 2);
      expect(testLog.symptoms, containsAll(['cramps', 'bloating']));
    });

    test('notes should be optional (nullable)', () {
      final logWithoutNotes = SymptomLog(
        id: 'log_002',
        userId: 'user_123',
        date: now,
        periodStatus: 'no_period',
        flowLevel: 'none',
        painLevel: 0,
        mood: 'calm',
        createdAt: now,
        updatedAt: now,
      );
      expect(logWithoutNotes.notes, isNull);
    });
  });
}
