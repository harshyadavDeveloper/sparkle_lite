import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

    await Future.delayed(
      const Duration(seconds: 2),
    ); // realistic delay(mock for the serious effects of AI processing)

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      _currentInsight = MockAiEngine.generateInsight(
        userId: userId,
        selectedLogs: selectedLogs,
      );
      _status = AiInsightStatus.generated;
    } catch (e) {
      _status = AiInsightStatus.error;
      _errorMessage = 'Failed to generate insight. Please try again.';
    }
    notifyListeners();
  }

  Future<bool> saveInsightToTimeline() async {
    if (_currentInsight == null) return false;

    try {
      await _repository.saveInsight(_currentInsight!);
      _status = AiInsightStatus.saved;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save insight.';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadInsights(String userId) async {
    try {
      _savedInsights = await _repository.getInsights(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load insights: $e');
    }
  }

  void reset() {
    _currentInsight = null;
    _status = AiInsightStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
