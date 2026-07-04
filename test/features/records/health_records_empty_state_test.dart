import 'dart:io';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sparkle_lite/core/theme/app_theme.dart';
import 'package:sparkle_lite/data/models/health_record.dart';
import 'package:sparkle_lite/features/records/health_record_provider.dart';
import 'package:sparkle_lite/features/records/health_records_screen.dart';

class FakeHealthRecordProvider extends ChangeNotifier
    implements HealthRecordProvider {
  @override
  List<HealthRecord> get records => [];

  @override
  List<HealthRecord> get allRecords => [];

  @override
  RecordStatus status = RecordStatus.loaded;

  @override
  String? errorMessage;

  @override
  String? activeFilter;

  @override
  bool get hasRecords => false;

  @override
  Future<void> loadRecords(String userId) async {}

  @override
  Future<bool> addRecord({
    required String userId,
    required String title,
    required String recordType,
    required DateTime recordDate,
    String? doctorName,
    String? notes,
    File? file,
  }) async => false;

  @override
  Future<bool> deleteRecord(String userId, String recordId) async => false;

  @override
  void setFilter(String? type) {}

  @override
  void clearError() {}
}

void main() {
  late FakeHealthRecordProvider fakeProvider;
  late MockFirebaseAuth mockAuth;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() async {
    mockAuth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'test_user_123', email: 'test@example.com'),
      signedIn: true,
    );

    await mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password',
    );

    fakeProvider = FakeHealthRecordProvider();
  });

  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ChangeNotifierProvider<HealthRecordProvider>.value(
        value: fakeProvider,
        child: const HealthRecordsScreen(),
      ),
    );
  }

  group('HealthRecordsScreen Empty State', () {
    testWidgets('shows empty state when no records exist', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No health records yet'), findsOneWidget);
      expect(find.text('Tap + to upload your first record'), findsOneWidget);
    });

    testWidgets('shows empty state emoji', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('🗂️'), findsOneWidget);
    });

    testWidgets('FAB is visible in empty state', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows loading indicator when status is loading', (
      tester,
    ) async {
      fakeProvider.status = RecordStatus.loading;

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No health records yet'), findsNothing);
    });

    testWidgets('shows error state correctly', (tester) async {
      fakeProvider.status = RecordStatus.error;
      fakeProvider.errorMessage = 'Failed to load records. Please try again.';

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to load records. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
