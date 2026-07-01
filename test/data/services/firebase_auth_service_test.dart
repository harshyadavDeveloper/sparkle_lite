import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_lite/data/services/firebase_auth_service.dart';

void main() {
  group('FirebaseAuthService', () {
    late MockFirebaseAuth mockAuth;
    late FirebaseAuthService service;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      service = FirebaseAuthService(auth: mockAuth);
    });

    test('currentUser is null before sign in', () {
      expect(service.currentUser, isNull);
    });

    test('authStateChanges emits null when not signed in', () {
      expect(service.authStateChanges, emits(null));
    });

    test('signUp creates a new user successfully', () async {
      final result = await service.signUp(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(result.user, isNotNull);
      expect(result.user?.email, 'test@example.com');
    });

    test('currentUser is set after sign up', () async {
      await service.signUp(email: 'test@example.com', password: 'password123');
      expect(service.currentUser, isNotNull);
      expect(service.currentUser?.email, 'test@example.com');
    });

    test('signOut clears current user', () async {
      await service.signUp(email: 'test@example.com', password: 'password123');
      expect(service.currentUser, isNotNull);

      await service.signOut();
      expect(service.currentUser, isNull);
    });

    test('authStateChanges emits user after sign in', () async {
      await service.signUp(email: 'test@example.com', password: 'password123');

      expect(
        service.authStateChanges.where((user) => user != null),
        emits(isNotNull),
      );
    });
  });
}
