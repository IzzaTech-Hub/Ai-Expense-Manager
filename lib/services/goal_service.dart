// lib/services/goal_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal_model.dart';

class GoalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // CREATE: Add a new goal to Firestore
  Future<String> addGoal(Goal goal) async {
    try {
      final docRef = await _db.collection('goals').add(goal.toJson());
      return docRef.id;
    } catch (e) {
      print('Error adding goal: $e');
      rethrow;
    }
  }

  // READ: Get a real-time stream of goals for the current user
  Stream<List<Goal>> getGoalsStream(String userId) {
    return _db
        .collection('goals')
        .where(
          'userId',
          isEqualTo: userId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add the document ID
            return Goal.fromJson(data);
          }).toList(),
        );
  }

  // UPDATE: Update a goal's current amount
  Future<void> updateGoalAmount(String goalId, double newCurrentAmount) async {
    try {
      await _db.collection('goals').doc(goalId).update({
        'currentAmount': newCurrentAmount,
      });
    } catch (e) {
      print('Error updating goal amount: $e');
      rethrow;
    }
  }

  // UPDATE: Update a goal's details
  Future<void> updateGoal(String goalId, Map<String, dynamic> updatedData) async {
    try {
      await _db.collection('goals').doc(goalId).update(updatedData);
    } catch (e) {
      print('Error updating goal: $e');
      rethrow;
    }
  }

  // DELETE: Delete a goal by its document ID
  Future<void> deleteGoal(String goalId) async {
    try {
      await _db.collection('goals').doc(goalId).delete();
    } catch (e) {
      print('Error deleting goal: $e');
      rethrow;
    }
  }
}
