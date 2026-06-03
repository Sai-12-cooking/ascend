import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ascend_app/models/task_model.dart';

void main() {
  group('TaskModel Snapshot Parsing and Date Truncation Tests', () {
    test('parses successfully from a complete database map', () {
      final now = DateTime(2026, 6, 3, 14, 30, 0); // 2:30 PM
      final timestamp = Timestamp.fromDate(now);

      final map = {
        'id': 'task_uuid_123',
        'userId': 'user_abc',
        'title': 'Morning Cardio Workout',
        'category': 'Workout',
        'isMandatory': false,
        'isCompleted': true,
        'xpReward': 25,
        'createdAt': timestamp,
      };

      final task = TaskModel.fromMap(map);

      expect(task.id, 'task_uuid_123');
      expect(task.userId, 'user_abc');
      expect(task.title, 'Morning Cardio Workout');
      expect(task.category, 'Workout');
      expect(task.isMandatory, false);
      expect(task.isCompleted, true);
      expect(task.xpReward, 25);
      // Verify date truncation to midnight
      expect(task.createdAt, DateTime(2026, 6, 3, 0, 0, 0));
    });

    test('parses successfully with defaults when optional fields are missing or null', () {
      final map = {
        'id': 'task_uuid_456',
        'userId': 'user_xyz',
        'title': 'Read 10 pages',
        'category': 'Learning',
        // 'isMandatory', 'isCompleted', 'xpReward', 'createdAt' are missing
      };

      final task = TaskModel.fromMap(map);

      expect(task.id, 'task_uuid_456');
      expect(task.userId, 'user_xyz');
      expect(task.title, 'Read 10 pages');
      expect(task.category, 'Learning');
      expect(task.isMandatory, true); // Default value
      expect(task.isCompleted, false); // Default value
      expect(task.xpReward, 10); // Default value
      // Verify date is truncated to today's midnight
      final todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      expect(task.createdAt, todayMidnight);
    });

    test('truncates the date to midnight when initialized or parsed', () {
      final task = TaskModel(
        id: 'task_uuid_789',
        userId: 'user_def',
        title: 'Focus Hour',
        category: 'Focus Work',
        createdAt: DateTime(2026, 6, 3, 23, 59, 59), // near midnight
      );

      expect(task.createdAt, DateTime(2026, 6, 3, 0, 0, 0));

      final serialized = task.toMap();
      expect(serialized['createdAt'], isA<Timestamp>());
      
      final timestamp = serialized['createdAt'] as Timestamp;
      expect(timestamp.toDate(), DateTime(2026, 6, 3, 0, 0, 0));
    });
  });
}
