import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/health_record.dart';
import '../../data/repositories/health_record_repository.dart';

enum RecordStatus { initial, loading, uploading, loaded, error }

class HealthRecordProvider extends ChangeNotifier {
  final HealthRecordRepository _repository = HealthRecordRepository();
  final _uuid = const Uuid();

  List<HealthRecord> _records = [];
  RecordStatus _status = RecordStatus.initial;
  String? _errorMessage;
  String? _activeFilter;

  List<HealthRecord> get records => _activeFilter == null
      ? _records
      : _records.where((r) => r.recordType == _activeFilter).toList();

  List<HealthRecord> get allRecords => _records;
  RecordStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get activeFilter => _activeFilter;
  bool get hasRecords => _records.isNotEmpty;

  Future<void> loadRecords(String userId) async {
    _status = RecordStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await _repository.getRecords(userId);
      _status = RecordStatus.loaded;
    } catch (e) {
      _status = RecordStatus.error;
      _errorMessage = 'Failed to load records. Please try again.';
    }
    notifyListeners();
  }

  Future<bool> addRecord({
    required String userId,
    required String title,
    required String recordType,
    required DateTime recordDate,
    String? doctorName,
    String? notes,
    File? file,
  }) async {
    _status = RecordStatus.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      String? fileUrl;
      if (file != null) {
        final fileName = '${_uuid.v4()}_${file.path.split('/').last}';
        fileUrl = await _repository.uploadFile(userId, file, fileName);
      }

      final record = HealthRecord(
        id: _uuid.v4(),
        userId: userId,
        title: title,
        recordType: recordType,
        recordDate: recordDate,
        doctorName: doctorName,
        fileUrl: fileUrl,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _repository.addRecord(record);
      _records.insert(0, record);
      _status = RecordStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = RecordStatus.error;
      _errorMessage = 'Failed to save record. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecord(String userId, String recordId) async {
    try {
      await _repository.deleteRecord(userId, recordId);
      _records.removeWhere((r) => r.id == recordId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete record.';
      notifyListeners();
      return false;
    }
  }

  void setFilter(String? type) {
    _activeFilter = type;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
