import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sparkle_lite/core/theme/app_theme.dart';
import 'package:sparkle_lite/data/models/health_record.dart';
import 'package:sparkle_lite/features/records/health_record_provider.dart';
import 'package:sparkle_lite/features/records/upload_record_screen.dart';

class FakeHealthRecordProvider extends ChangeNotifier
    implements HealthRecordProvider {
  List<HealthRecord> _records = [];

  @override
  List<HealthRecord> get records => _records;
  set records(List<HealthRecord> value) => _records = value;

  @override
  List<HealthRecord> get allRecords => _records;

  @override
  RecordStatus status = RecordStatus.loaded;

  @override
  String? errorMessage;

  @override
  String? activeFilter;

  @override
  bool get hasRecords => _records.isNotEmpty;

  bool addRecordResult = true;
  bool updateRecordResult = true;
  bool deleteRecordResult = true;
  Map<String, dynamic>? lastAddRecordCall;
  Map<String, dynamic>? lastUpdateRecordCall;

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
  }) async {
    lastAddRecordCall = {
      'userId': userId,
      'title': title,
      'recordType': recordType,
      'recordDate': recordDate,
      'doctorName': doctorName,
      'notes': notes,
      'file': file,
    };
    return addRecordResult;
  }

  @override
  Future<bool> deleteRecord(String userId, String recordId) async =>
      deleteRecordResult;

  @override
  void setFilter(String? type) {}

  @override
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  Future<bool> updateRecord({
    required String userId,
    required String recordId,
    required String title,
    required String recordType,
    required DateTime recordDate,
    String? doctorName,
    String? notes,
    String? existingFileUrl,
    String? existingLocalPath,
    File? newFile,
  }) async {
    lastUpdateRecordCall = {
      'userId': userId,
      'recordId': recordId,
      'title': title,
      'recordType': recordType,
      'recordDate': recordDate,
      'doctorName': doctorName,
      'notes': notes,
      'existingFileUrl': existingFileUrl,
      'existingLocalPath': existingLocalPath,
      'newFile': newFile,
    };
    return updateRecordResult;
  }
}

Future<void> tapSaveButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pump();
}

/// Gives the test a much taller virtual screen so long forms (like this one:
/// title + 6 chips + date + file picker + notes + button) never place the
/// Save button below the fold. This avoids flaky off-screen taps that
/// happen with the default 800x600 test surface.
Future<void> pumpWithBigSurface(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(widget);
}

void main() {
  group('UploadRecordScreen — Add mode', () {
    late FakeHealthRecordProvider fakeProvider;

    setUp(() {
      fakeProvider = FakeHealthRecordProvider();
    });

    Widget buildAddScreen() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider<HealthRecordProvider>.value(
          value: fakeProvider,
          child: const UploadRecordScreen(userIdOverride: 'test-user-id'),
        ),
      );
    }

    testWidgets('shows "Upload Health Record" title in add mode', (
      tester,
    ) async {
      await pumpWithBigSurface(tester, buildAddScreen());
      expect(find.text('Upload Health Record'), findsOneWidget);
    });

    testWidgets('shows record type error when saving without selection', (
      tester,
    ) async {
      await pumpWithBigSurface(tester, buildAddScreen());

      await tester.enterText(find.byType(TextFormField).first, 'Blood Test');
      await tapSaveButton(tester, 'Save Record');

      expect(find.text('Please select a record type'), findsOneWidget);
    });

    testWidgets('shows title required error when title is empty', (
      tester,
    ) async {
      await pumpWithBigSurface(tester, buildAddScreen());

      await tapSaveButton(tester, 'Save Record');

      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('calls addRecord with correct values on valid form', (
      tester,
    ) async {
      await pumpWithBigSurface(tester, buildAddScreen());

      await tester.enterText(find.byType(TextFormField).first, 'Blood Test');
      await tester.ensureVisible(find.text('Lab Report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lab Report'));
      await tester.pump();

      await tapSaveButton(tester, 'Save Record');

      expect(fakeProvider.lastAddRecordCall, isNotNull);
      expect(fakeProvider.lastAddRecordCall!['userId'], 'test-user-id');
      expect(fakeProvider.lastAddRecordCall!['title'], 'Blood Test');
      expect(fakeProvider.lastAddRecordCall!['recordType'], 'lab_report');
    });
  });

  group('UploadRecordScreen — Edit mode', () {
    late FakeHealthRecordProvider fakeProvider;
    late HealthRecord existingRecord;

    setUp(() {
      fakeProvider = FakeHealthRecordProvider();
      existingRecord = HealthRecord(
        id: 'record-1',
        userId: 'test-user-id',
        title: 'Old Title',
        recordType: 'lab_report',
        recordDate: DateTime(2026, 1, 15),
        doctorName: 'Dr. Rao',
        notes: 'Old notes',
        fileUrl: 'https://example.com/file.pdf',
        createdAt: DateTime(2026, 1, 15),
        // updatedAt: DateTime(2026, 1, 15),
      );
    });

    Widget buildEditScreen() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider<HealthRecordProvider>.value(
          value: fakeProvider,
          child: UploadRecordScreen(
            existingRecord: existingRecord,
            userIdOverride: 'test-user-id',
          ),
        ),
      );
    }

    testWidgets('shows "Edit Health Record" title in edit mode', (
      tester,
    ) async {
      await pumpWithBigSurface(tester, buildEditScreen());
      expect(find.text('Edit Health Record'), findsOneWidget);
    });

    testWidgets('pre-fills fields with existing record data', (tester) async {
      await pumpWithBigSurface(tester, buildEditScreen());

      final titleField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(titleField.controller?.text, 'Old Title');

      expect(find.text('15 Jan 2026'), findsOneWidget);
    });

    testWidgets('record type chip is pre-selected', (tester) async {
      await pumpWithBigSurface(tester, buildEditScreen());

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Lab Report'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets(
      'calls updateRecord (not addRecord) with correct values on save',
      (tester) async {
        await pumpWithBigSurface(tester, buildEditScreen());

        final titleFieldFinder = find.byType(TextFormField).first;
        await tester.enterText(titleFieldFinder, 'Updated Title');
        await tester.pump();

        await tapSaveButton(tester, 'Save Record');

        expect(fakeProvider.lastUpdateRecordCall, isNotNull);
        expect(fakeProvider.lastAddRecordCall, isNull);

        expect(fakeProvider.lastUpdateRecordCall!['userId'], 'test-user-id');
        expect(fakeProvider.lastUpdateRecordCall!['recordId'], 'record-1');
        expect(fakeProvider.lastUpdateRecordCall!['title'], 'Updated Title');
        expect(fakeProvider.lastUpdateRecordCall!['recordType'], 'lab_report');
        expect(
          fakeProvider.lastUpdateRecordCall!['existingFileUrl'],
          'https://example.com/file.pdf',
        );
        expect(fakeProvider.lastUpdateRecordCall!['newFile'], isNull);
      },
    );

    testWidgets('shows "Record updated ✓" snackbar on successful update', (
      tester,
    ) async {
      fakeProvider.updateRecordResult = true;

      await pumpWithBigSurface(
        tester,
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<HealthRecordProvider>.value(
            value: fakeProvider,
            child: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => UploadRecordScreen(
                  existingRecord: existingRecord,
                  userIdOverride: 'test-user-id',
                ),
              ),
            ),
          ),
        ),
      );

      await tapSaveButton(tester, 'Save Record');

      expect(find.text('Record updated ✓'), findsOneWidget);
    });

    testWidgets('shows error snackbar when update fails', (tester) async {
      fakeProvider.updateRecordResult = false;
      fakeProvider.errorMessage = 'Failed to update record';

      await pumpWithBigSurface(tester, buildEditScreen());

      await tapSaveButton(tester, 'Save Record');

      expect(find.text('Failed to update record'), findsOneWidget);
    });

    testWidgets('preserves existingFileUrl when no new file is picked', (
      tester,
    ) async {
      await pumpWithBigSurface(tester, buildEditScreen());

      await tapSaveButton(tester, 'Save Record');

      expect(
        fakeProvider.lastUpdateRecordCall!['existingFileUrl'],
        existingRecord.fileUrl,
      );
      expect(fakeProvider.lastUpdateRecordCall!['newFile'], isNull);
    });
  });
}
