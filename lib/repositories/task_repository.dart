import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore? _firestore;

  TaskRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Fetches tasks for a specific user ID and date (truncated to midnight).
  Future<List<TaskModel>> fetchTasksForDate(String userId, DateTime date) async {
    try {
      final midnightDate = DateTime(date.year, date.month, date.day);
      final timestamp = Timestamp.fromDate(midnightDate);

      final snapshot = await _db
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isEqualTo: timestamp)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Firebase not initialized. Returning empty tasks for UI testing: $e');
      return [];
    }
  }

  /// Saves a new task to the Firestore collection.
  Future<void> createTask(TaskModel task) async {
    await _db
        .collection('tasks')
        .doc(task.id)
        .set(task.toMap());
  }

  /// Updates an existing task in the Firestore collection.
  Future<void> updateTask(TaskModel task) async {
    await _db
        .collection('tasks')
        .doc(task.id)
        .update(task.toMap());
  }
}
