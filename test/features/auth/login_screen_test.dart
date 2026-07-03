import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sparkle_lite/core/theme/app_theme.dart';
import 'package:sparkle_lite/features/auth/auth_provider.dart';
import 'package:sparkle_lite/features/auth/login/login_screen.dart';

// Fake AuthProvider — no Firebase needed
class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AuthStatus status = AuthStatus.unauthenticated;

  @override
  String? errorMessage;

  @override
  get user => null;

  @override
  bool get isAuthenticated => false;

  bool signInResult = false;
  bool signUpResult = false;
  bool signInWithGoogleResult = false;

  @override
  Future<bool> signIn({required String email, required String password}) async {
    return signInResult;
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    return signUpResult;
  }

  @override
  Future<void> signOut() async {}

  @override
  void clearError() {}

  @override
  Future<bool> signInWithGoogle() async {
    return signInWithGoogleResult;
  }
}

void main() {
  group('LoginScreen Widget Tests', () {
    late FakeAuthProvider fakeAuth;

    setUp(() {
      fakeAuth = FakeAuthProvider();
    });

    Widget buildLoginScreen() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: fakeAuth,
          child: const LoginScreen(),
        ),
      );
    }

    testWidgets('renders email and password fields and sign in button', (
      tester,
    ) async {
      await tester.pumpWidget(buildLoginScreen());

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows error when submitting empty form', (tester) async {
      await tester.pumpWidget(buildLoginScreen());

      // Tap Sign In without filling anything
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await tester.pumpWidget(buildLoginScreen());

      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(buildLoginScreen());

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('no validation errors when form is valid', (tester) async {
      await tester.pumpWidget(buildLoginScreen());

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Password is required'), findsNothing);
      expect(find.text('Enter a valid email address'), findsNothing);
      expect(find.text('Password must be at least 6 characters'), findsNothing);
    });

    testWidgets('sign up link is visible', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      expect(find.text('Sign Up'), findsOneWidget);
    });
  });
}
