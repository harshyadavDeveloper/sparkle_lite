import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/privacy_settings.dart';

class PrivacyProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PrivacySettings? _settings;
  bool _isLoading = true;

  PrivacySettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get hideSensitive => _settings?.hideSensitiveDashboardDetails ?? false;
  bool get requireConfirmation =>
      _settings?.requireConfirmationBeforeSharing ?? true;
  bool get useGenericNotifications =>
      _settings?.useGenericNotificationText ?? true;

  Future<void> loadSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection('privacySettings')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        _settings = PrivacySettings.fromMap(doc.data()!);
      } else {
        // Default settings — privacy first
        _settings = PrivacySettings(userId: userId, updatedAt: DateTime.now());
      }
    } catch (e) {
      debugPrint('Failed to load privacy settings: $e');
      _settings = PrivacySettings(userId: userId, updatedAt: DateTime.now());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSettings(PrivacySettings updated) {
    _settings = updated;
    notifyListeners();
  }
}
