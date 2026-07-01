import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symptom_log.dart';

class SymptomRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _logsCollection(String userId) =>
      _firestore.collection('symptomLogs').doc(userId).collection('logs');

  Future<void> addLog(SymptomLog log) async {
    await _logsCollection(log.userId).doc(log.id).set(log.toMap());
  }

  Future<void> updateLog(SymptomLog log) async {
    await _logsCollection(log.userId).doc(log.id).update(log.toMap());
  }

  Future<void> deleteLog(String userId, String logId) async {
    await _logsCollection(userId).doc(logId).delete();
  }

  Future<List<SymptomLog>> getLogs(String userId) async {
    final snapshot = await _logsCollection(
      userId,
    ).orderBy('date', descending: true).get();

    return snapshot.docs
        .map((doc) => SymptomLog.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<SymptomLog>> watchLogs(String userId) {
    return _logsCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SymptomLog.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }
}
