import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sparkle_lite/core/theme/app_theme.dart';
import 'package:sparkle_lite/data/models/symptom_log.dart';
import 'package:sparkle_lite/features/symptom_tracker/add_symptom_screen.dart';
import 'package:sparkle_lite/features/symptom_tracker/symptom_provider.dart';

class FakeSymptomProvider extends ChangeNotifier implements SymptomProvider {
  @override
  SymptomStatus status = SymptomStatus.initial;

  @override
  String? errorMessage;

  @override
  List<SymptomLog> logs = [];

  @override
  bool get hasLogs => logs.isNotEmpty;

  bool addLogResult = true;
  Map<String, dynamic>? lastAddLogCall;

  @override
  Future<bool> addLog({
    required String userId,
    required DateTime date,
    required String periodStatus,
    required String flowLevel,
    required int painLevel,
    required String mood,
    required List<String> symptoms,
    String? notes,
  }) async {
    lastAddLogCall = {
      'userId': userId,
      'date': date,
      'periodStatus': periodStatus,
      'flowLevel': flowLevel,
      'painLevel': painLevel,
      'mood': mood,
      'symptoms': symptoms,
      'notes': notes,
    };
    return addLogResult;
  }

  @override
  Future<void> loadLogs(String userId) async {}

  @override
  Future<bool> updateLog(SymptomLog updatedLog) async => true;

  @override
  Future<bool> deleteLog(String userId, String logId) async => true;

  @override
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}

/// "Save Log" sits below the fold at the default test viewport size,
/// so it must be scrolled into view before tapping — otherwise the
/// tap silently misses and the test fails with confusing downstream errors.
Future<void> tapSaveLog(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save Log'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save Log'));
  await tester.pump();
}

Future<void> tapChip(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  group('AddSymptomScreen Widget Tests', () {
    late FakeSymptomProvider fakeProvider;

    setUp(() {
      fakeProvider = FakeSymptomProvider();
    });

    Widget buildScreen() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider<SymptomProvider>.value(
          value: fakeProvider,
          child: const AddSymptomScreen(userIdOverride: 'test-user-id'),
        ),
      );
    }

    testWidgets('renders all sections', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('Log Symptoms'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Period Status *'), findsOneWidget);
      expect(find.text('Flow Level *'), findsOneWidget);
      expect(find.textContaining('Pain Level:'), findsOneWidget);
      expect(find.text('Mood *'), findsOneWidget);
      expect(find.text('Symptoms'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);
      expect(find.text('Save Log'), findsOneWidget);
    });

    testWidgets(
      'shows all three chip errors when saving with nothing selected',
      (tester) async {
        await tester.pumpWidget(buildScreen());

        await tapSaveLog(tester);

        expect(find.text('Please select a period status'), findsOneWidget);
        expect(find.text('Please select a flow level'), findsOneWidget);
        expect(find.text('Please select a mood'), findsOneWidget);
      },
    );

    testWidgets('selecting a period status chip clears its error', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());

      await tapSaveLog(tester);
      expect(find.text('Please select a period status'), findsOneWidget);

      await tapChip(tester, find.text('Period Started'));

      expect(find.text('Please select a period status'), findsNothing);
    });

    testWidgets('tapping date field opens date picker', (tester) async {
      await tester.pumpWidget(buildScreen());

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarDatePicker), findsOneWidget);
    });

    testWidgets('selecting symptom chips toggles them', (tester) async {
      await tester.pumpWidget(buildScreen());

      final crampsFinder = find.widgetWithText(FilterChip, 'Cramps');
      await tester.ensureVisible(crampsFinder);
      await tester.pumpAndSettle();

      FilterChip chip = tester.widget(crampsFinder);
      expect(chip.selected, isFalse);

      await tester.tap(crampsFinder);
      await tester.pump();

      chip = tester.widget(crampsFinder);
      expect(chip.selected, isTrue);

      await tester.tap(crampsFinder);
      await tester.pump();

      chip = tester.widget(crampsFinder);
      expect(chip.selected, isFalse);
    });

    testWidgets('valid form calls addLog with correct values', (tester) async {
      await tester.pumpWidget(buildScreen());

      await tapChip(tester, find.text('Period Started'));
      await tapChip(tester, find.text('Medium'));
      await tapChip(tester, find.text('Calm'));
      await tapChip(tester, find.widgetWithText(FilterChip, 'Cramps'));

      await tester.ensureVisible(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Feeling okay today');
      await tester.pump();

      await tapSaveLog(tester);

      expect(fakeProvider.lastAddLogCall, isNotNull);
      expect(fakeProvider.lastAddLogCall!['userId'], 'test-user-id');
      expect(fakeProvider.lastAddLogCall!['periodStatus'], 'started');
      expect(fakeProvider.lastAddLogCall!['flowLevel'], 'medium');
      expect(fakeProvider.lastAddLogCall!['mood'], 'calm');
      expect(fakeProvider.lastAddLogCall!['symptoms'], ['cramps']);
      expect(fakeProvider.lastAddLogCall!['notes'], 'Feeling okay today');
    });

    testWidgets('empty notes are passed as null', (tester) async {
      await tester.pumpWidget(buildScreen());

      await tapChip(tester, find.text('Period Started'));
      await tapChip(tester, find.text('Medium'));
      await tapChip(tester, find.text('Calm'));

      await tapSaveLog(tester);

      expect(fakeProvider.lastAddLogCall!['notes'], isNull);
    });

    testWidgets('shows success snackbar and pops on successful save', (
      tester,
    ) async {
      fakeProvider.addLogResult = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<SymptomProvider>.value(
            value: fakeProvider,
            child: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) =>
                    const AddSymptomScreen(userIdOverride: 'test-user-id'),
              ),
            ),
          ),
        ),
      );

      await tapChip(tester, find.text('Period Started'));
      await tapChip(tester, find.text('Medium'));
      await tapChip(tester, find.text('Calm'));

      await tapSaveLog(tester);

      expect(find.text('Symptom log saved ✓'), findsOneWidget);
    });

    testWidgets('shows error snackbar on failed save', (tester) async {
      fakeProvider.addLogResult = false;
      fakeProvider.errorMessage = 'Failed to save log. Please try again.';

      await tester.pumpWidget(buildScreen());

      await tapChip(tester, find.text('Period Started'));
      await tapChip(tester, find.text('Medium'));
      await tapChip(tester, find.text('Calm'));

      await tapSaveLog(tester);

      expect(
        find.text('Failed to save log. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
