import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_lite/data/models/privacy_settings.dart';

void main() {
  group('PrivacySettings Model', () {
    final now = DateTime.now();

    test('generic notifications should be ON by default', () {
      final settings = PrivacySettings(userId: 'user_123', updatedAt: now);
      // Critical — per PDF, sensitive notifications must be generic by default
      expect(settings.useGenericNotificationText, isTrue);
    });

    test('confirmation before sharing should be ON by default', () {
      final settings = PrivacySettings(userId: 'user_123', updatedAt: now);
      expect(settings.requireConfirmationBeforeSharing, isTrue);
    });

    test('family profile access should be OFF by default', () {
      final settings = PrivacySettings(userId: 'user_123', updatedAt: now);
      expect(settings.familyProfileAccessEnabled, isFalse);
    });

    test('toMap() and fromMap() roundtrip preserves all values', () {
      final settings = PrivacySettings(
        userId: 'user_123',
        hideSensitiveDashboardDetails: true,
        useGenericNotificationText: false,
        familyProfileAccessEnabled: true,
        updatedAt: now,
      );

      final map = settings.toMap();
      final restored = PrivacySettings.fromMap(map);

      expect(restored.userId, settings.userId);
      expect(restored.hideSensitiveDashboardDetails, isTrue);
      expect(restored.useGenericNotificationText, isFalse);
      expect(restored.requireConfirmationBeforeSharing, isTrue);
      expect(restored.familyProfileAccessEnabled, isTrue);
    });
  });
}
