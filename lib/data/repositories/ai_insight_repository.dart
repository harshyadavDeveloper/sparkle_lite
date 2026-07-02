import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_insight.dart';

class AiInsightRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _insightsCollection(String userId) =>
      _firestore.collection('aiInsights').doc(userId).collection('insights');

  Future<void> saveInsight(AiInsight insight) async {
    await _insightsCollection(
      insight.userId,
    ).doc(insight.id).set(insight.toMap());
  }

  Future<List<AiInsight>> getInsights(String userId) async {
    final snapshot = await _insightsCollection(
      userId,
    ).orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => AiInsight.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
