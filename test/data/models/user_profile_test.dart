import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_lite/data/models/user_profile.dart';

void main() {
  group('UserProfile Model', () {
    final now = DateTime.now();

    final testProfile = UserProfile(
      userId: 'user_123',
      displayName: 'Priya',
      ageRange: '26–35',
      lifeStage: 'Period tracking',
      menstrualCycleStatus: 'Regular',
      knownConditions: ['PCOS'],
      currentMedications: ['Metformin'],
      createdAt: now,
      updatedAt: now,
    );

    test('should create UserProfile with correct values', () {
      expect(testProfile.displayName, 'Priya');
      expect(testProfile.ageRange, '26–35');
      expect(testProfile.lifeStage, 'Period tracking');
      expect(testProfile.knownConditions, contains('PCOS'));
    });

    test('toMap() serializes correctly', () {
      final map = testProfile.toMap();
      expect(map['displayName'], 'Priya');
      expect(map['lifeStage'], 'Period tracking');
      expect(map['knownConditions'], isA<List>());
    });

    test('fromMap() deserializes correctly', () {
      final map = testProfile.toMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.userId, testProfile.userId);
      expect(restored.displayName, testProfile.displayName);
      expect(restored.knownConditions.length, 1);
      expect(restored.currentMedications, contains('Metformin'));
    });

    test('conditions and medications default to empty list', () {
      final minimalProfile = UserProfile(
        userId: 'user_456',
        displayName: 'Ananya',
        ageRange: '18–25',
        lifeStage: 'General wellness',
        menstrualCycleStatus: 'Regular',
        createdAt: now,
        updatedAt: now,
      );
      expect(minimalProfile.knownConditions, isEmpty);
      expect(minimalProfile.currentMedications, isEmpty);
    });
  });
}
