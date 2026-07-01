import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/symptom_log.dart';
import '../../data/repositories/symptom_repository.dart';

enum SymptomStatus { initial, loading, loaded, error }

class SymptomProvider extends ChangeNotifier {
  final SymptomRepository _repository = SymptomRepository();
  final _uuid = const Uuid();

  List<SymptomLog> _logs = [];
  SymptomStatus _status = SymptomStatus.initial;
  String? _errorMessage;

  List<SymptomLog> get logs => _logs;
  SymptomStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get hasLogs => _logs.isNotEmpty;

  Future<void> loadLogs(String userId) async {
    _status = SymptomStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await _repository.getLogs(userId);
      _status = SymptomStatus.loaded;
    } catch (e) {
      _status = SymptomStatus.error;
      _errorMessage = 'Failed to load symptom logs. Please try again.';
    }
    notifyListeners();
  }

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
    try {
      final log = SymptomLog(
        id: _uuid.v4(),
        userId: userId,
        date: date,
        periodStatus: periodStatus,
        flowLevel: flowLevel,
        painLevel: painLevel,
        mood: mood,
        symptoms: symptoms,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.addLog(log);
      _logs.insert(0, log);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save log. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLog(SymptomLog updatedLog) async {
    try {
      final log = SymptomLog(
        id: updatedLog.id,
        userId: updatedLog.userId,
        date: updatedLog.date,
        periodStatus: updatedLog.periodStatus,
        flowLevel: updatedLog.flowLevel,
        painLevel: updatedLog.painLevel,
        mood: updatedLog.mood,
        symptoms: updatedLog.symptoms,
        notes: updatedLog.notes,
        createdAt: updatedLog.createdAt,
        updatedAt: DateTime.now(),
      );

      await _repository.updateLog(log);

      final index = _logs.indexWhere((l) => l.id == log.id);
      if (index != -1) {
        _logs[index] = log;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update log. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLog(String userId, String logId) async {
    try {
      await _repository.deleteLog(userId, logId);
      _logs.removeWhere((l) => l.id == logId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete log. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
