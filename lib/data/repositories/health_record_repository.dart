import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_record.dart';

class HealthRecordRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _recordsCollection(String userId) =>
      _firestore.collection('healthRecords').doc(userId).collection('records');

  Future<String?> uploadFile(String userId, File file, String fileName) async {
    // Mock upload — stores filename reference instead of real URL
    // Firebase Storage not used to avoid Blaze plan requirement
    await Future.delayed(const Duration(milliseconds: 800));
    return 'mock://health_records/$userId/$fileName';
  }

  Future<void> addRecord(HealthRecord record) async {
    await _recordsCollection(record.userId).doc(record.id).set(record.toMap());
  }

  Future<void> deleteRecord(String userId, String recordId) async {
    await _recordsCollection(userId).doc(recordId).delete();
  }

  Future<List<HealthRecord>> getRecords(String userId) async {
    final snapshot = await _recordsCollection(
      userId,
    ).orderBy('recordDate', descending: true).get();

    return snapshot.docs
        .map((doc) => HealthRecord.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
