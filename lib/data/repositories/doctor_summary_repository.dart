import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_summary.dart';

class DoctorSummaryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _summariesCollection(String userId) => _firestore
      .collection('doctorSummaries')
      .doc(userId)
      .collection('summaries');

  Future<List<DoctorSummary>> getSummaries(String userId) async {
    final snapshot = await _summariesCollection(
      userId,
    ).orderBy('generatedAt', descending: true).get();
    return snapshot.docs
        .map((doc) => DoctorSummary.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
