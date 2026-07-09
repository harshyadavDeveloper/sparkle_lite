import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sparkle_lite/core/utils/logger.dart';
import '../../data/services/firebase_auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  User? _user;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      _user = user;
      _status = user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  Future<bool> signUp({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(email: email, password: password);
      Logger.info('User signed up successfully: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      Logger.error('Error signing up user: $email');
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      Logger.info('User signed in successfully: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      Logger.error('Error signing in user: $email');
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();

      if (credential == null) {
        Logger.info('Google sign-in cancelled by user');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      Logger.info('User signed in with Google: ${credential.user?.email}');
      return true;
    } on FirebaseAuthException catch (e) {
      Logger.error('FirebaseAuthException during Google sign-in: ${e.code}');
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      Logger.error('Unexpected error during Google sign-in: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Google sign-in failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    Logger.info('Signing out user');
    await _authService.signOut();
  }

  String _mapFirebaseError(String code) {
    Logger.error('FirebaseAuthException code: $code');
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'invalid-credential':
        return 'Invalid credentials provided. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
