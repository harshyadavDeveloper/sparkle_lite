import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sparkle_lite/core/utils/logger.dart';
import 'package:sparkle_lite/data/repositories/doctor_summary_repository.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/doctor_summary.dart';
import '../../data/models/health_record.dart';
import '../../data/models/symptom_log.dart';
import '../../data/models/user_profile.dart';

enum DoctorSummaryStatus { initial, loading, generated, saved, error }

class DoctorSummaryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DoctorSummaryRepository _repository = DoctorSummaryRepository();
  List<DoctorSummary> _savedSummaries = [];
  List<DoctorSummary> get savedSummaries => _savedSummaries;

  DoctorSummary? _currentSummary;
  DoctorSummaryStatus _status = DoctorSummaryStatus.initial;
  String? _errorMessage;

  DoctorSummary? get currentSummary => _currentSummary;
  DoctorSummaryStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> generateSummary({
    required UserProfile profile,
    required List<SymptomLog> recentLogs,
    required List<HealthRecord> records,
    String? userNotes,
  }) async {
    _status = DoctorSummaryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final recentSymptoms = recentLogs
          .take(5)
          .map(
            (l) =>
                'Pain ${l.painLevel}/10, ${l.mood}, '
                '${l.periodStatus.replaceAll('_', ' ')}'
                '${l.symptoms.isNotEmpty ? ' — ${l.symptoms.join(', ')}' : ''}',
          )
          .toList();

      final periodHistory = recentLogs
          .take(5)
          .map(
            (l) =>
                '${l.date.toLocal().toString().split(' ')[0]}: '
                '${l.periodStatus.replaceAll('_', ' ')}, '
                'flow: ${l.flowLevel}',
          )
          .toList();

      final recordTitles = records.take(5).map((r) => r.title).toList();

      final questions = _generateQuestions(profile, recentLogs);

      _currentSummary = DoctorSummary(
        id: const Uuid().v4(),
        userId: userId,
        profileSnapshot:
            '${profile.displayName}, ${profile.ageRange}, '
            '${profile.lifeStage}, cycle: ${profile.menstrualCycleStatus}'
            '${profile.knownConditions.isNotEmpty ? ', conditions: ${profile.knownConditions.join(', ')}' : ''}'
            '${profile.currentMedications.isNotEmpty ? ', medications: ${profile.currentMedications.join(', ')}' : ''}',
        recentSymptoms: recentSymptoms,
        periodHistory: periodHistory,
        uploadedRecordTitles: recordTitles,
        currentMedications: profile.currentMedications,
        questionsForDoctor: questions,
        userNotes: userNotes,
        generatedAt: DateTime.now(),
      );
      Logger.info('Generated Doctor Summary: ${_currentSummary?.toMap()}');
      Logger.info('Questions for doctor: ${questions.join('; ')}');
      Logger.info('Recent symptoms: ${recentSymptoms.join('; ')}');
      Logger.info('Period history: ${periodHistory.join('; ')}');

      _status = DoctorSummaryStatus.generated;
    } catch (e) {
      _status = DoctorSummaryStatus.error;
      _errorMessage = 'Failed to generate summary. Please try again.';
    }
    notifyListeners();
  }

  List<String> _generateQuestions(UserProfile profile, List<SymptomLog> logs) {
    final questions = <String>[];

    final hasHighPain = logs.any((l) => l.painLevel >= 7);
    final hasIrregular = logs.any(
      (l) => l.symptoms.contains('irregular bleeding'),
    );
    final hasMoodIssues = logs.any(
      (l) => l.mood == 'anxious' || l.mood == 'irritable',
    );

    if (hasHighPain) {
      questions.add(
        'I have been experiencing pain levels of 7 or above — '
        'what could be causing this?',
      );
    }
    if (hasIrregular) {
      questions.add(
        'I have noticed irregular bleeding — should I be concerned?',
      );
    }
    if (hasMoodIssues) {
      questions.add('My mood has been affected — could this be cycle-related?');
    }
    if (profile.knownConditions.contains('PCOS')) {
      questions.add('How should I be monitoring my PCOS symptoms?');
    }
    if (profile.lifeStage == 'Fertility planning') {
      questions.add('What steps should I take to support fertility planning?');
    }

    questions.addAll([
      'Are there any routine tests or screenings I should schedule?',
      'Are my current medications appropriate for my situation?',
    ]);

    return questions;
  }

  Future<bool> saveSummaryToTimeline() async {
    if (_currentSummary == null) return false;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _firestore
          .collection('doctorSummaries')
          .doc(userId)
          .collection('summaries')
          .doc(_currentSummary!.id)
          .set(_currentSummary!.toMap());

      _status = DoctorSummaryStatus.saved;
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error saving doctor summary: $e');
      _errorMessage = 'Failed to save summary.';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadSummaries(String userId) async {
    try {
      _savedSummaries = await _repository.getSummaries(userId);
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to load summaries: $e');
    }
  }

  void reset() {
    _currentSummary = null;
    _status = DoctorSummaryStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
