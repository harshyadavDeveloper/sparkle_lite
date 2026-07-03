import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sparkle_lite/core/utils/logger.dart';
import 'package:sparkle_lite/data/services/gemini_service.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/ai_insight.dart';
import '../../data/models/symptom_log.dart';
import '../../data/repositories/ai_insight_repository.dart';
import '../../data/services/mock_ai_engine.dart';

enum AiInsightStatus { initial, loading, generated, saved, error }

class AiInsightProvider extends ChangeNotifier {
  final AiInsightRepository _repository = AiInsightRepository();

  AiInsight? _currentInsight;
  List<AiInsight> _savedInsights = [];
  AiInsightStatus _status = AiInsightStatus.initial;
  String? _errorMessage;

  AiInsight? get currentInsight => _currentInsight;
  List<AiInsight> get savedInsights => _savedInsights;
  AiInsightStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> generateInsight(List<SymptomLog> selectedLogs) async {
    _status = AiInsightStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      Logger.info('AiInsightProvider → calling Gemini for insight');

      // Try real Gemini first
      final response = await GeminiService.generateInsight(
        selectedLogs: selectedLogs,
      );

      if (response != null) {
        Logger.success('AiInsightProvider → Gemini insight received');

        _currentInsight = AiInsight(
          id: const Uuid().v4(),
          userId: userId,
          summary: response['summary'] ?? '',
          possiblePattern: response['possiblePattern'] ?? '',
          careGuidance: response['careGuidance'] ?? '',
          doctorQuestions: List<String>.from(response['doctorQuestions'] ?? []),
          disclaimer:
              response['disclaimer'] ??
              'This is not a diagnosis and does not replace medical advice.',
          createdAt: DateTime.now(),
        );

        _status = AiInsightStatus.generated;
      } else {
        Logger.warning(
          'AiInsightProvider → Gemini failed, falling back to mock',
        );

        _currentInsight = MockAiEngine.generateInsight(
          userId: userId,
          selectedLogs: selectedLogs,
        );
        _status = AiInsightStatus.generated;
      }
    } catch (e) {
      Logger.error('AiInsightProvider → exception: $e');
      _status = AiInsightStatus.error;
      _errorMessage = 'Failed to generate insight. Please try again.';
    }
    notifyListeners();
  }

  Future<bool> saveInsightToTimeline() async {
    if (_currentInsight == null) return false;

    try {
      await _repository.saveInsight(_currentInsight!);
      Logger.info('Saved AI Insight: ${_currentInsight?.toMap()}');
      _status = AiInsightStatus.saved;
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error saving AI Insight: $e');
      _errorMessage = 'Failed to save insight.';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadInsights(String userId) async {
    try {
      _savedInsights = await _repository.getInsights(userId);
      Logger.info('Loaded insights for user $userId');
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading insights: $e');
    }
  }

  void reset() {
    _currentInsight = null;
    _status = AiInsightStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
