import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/user_profile.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfile? _profile;
  ProfileStatus _status = ProfileStatus.initial;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  ProfileStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _profile != null;

  Future<void> loadProfile(String userId) async {
    _status = ProfileStatus.loading;
    notifyListeners();

    try {
      final doc = await _firestore.collection('profiles').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        _profile = UserProfile.fromMap(doc.data()!);
      }
      _status = ProfileStatus.loaded;
    } catch (e) {
      _status = ProfileStatus.error;
      _errorMessage = 'Failed to load profile.';
    }
    notifyListeners();
  }

  Future<bool> updateProfile(UserProfile updated) async {
    try {
      await _firestore
          .collection('profiles')
          .doc(updated.userId)
          .update(updated.toMap());
      _profile = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile.';
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _profile = null;
    _status = ProfileStatus.initial;
    notifyListeners();
  }
}
