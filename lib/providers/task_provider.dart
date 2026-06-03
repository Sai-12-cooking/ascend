import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';

/// Provider for the [TaskRepository].
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

/// Notifier that manages the daily task list state.
class TasksNotifier extends StateNotifier<List<TaskModel>> {
  final TaskRepository _taskRepository;

  TasksNotifier(this._taskRepository) : super([]);

  /// Fetches today's tasks for [userId] from Firestore.
  Future<void> fetchTodayTasks(String userId) async {
    try {
      final tasks = await _taskRepository.fetchTasksForDate(userId, DateTime.now());
      state = tasks;
    } catch (e) {
      state = [];
    }
  }

  /// Toggles a task's completion status.
  /// 
  /// Updates both the local state list and the remote Firestore document.
  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = state.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final oldTask = state[taskIndex];
    final updatedTask = oldTask.copyWith(isCompleted: !oldTask.isCompleted);

    // Optimistically update local state
    final updatedList = List<TaskModel>.from(state);
    updatedList[taskIndex] = updatedTask;
    state = updatedList;

    try {
      // Update remote Firestore database
      await _taskRepository.updateTask(updatedTask);
    } catch (e) {
      // Revert local state on error
      final revertedList = List<TaskModel>.from(state);
      revertedList[taskIndex] = oldTask;
      state = revertedList;
    }
  }
}

/// Provider for the [TasksNotifier] and its [List<TaskModel>] state.
final tasksNotifierProvider =
    StateNotifierProvider<TasksNotifier, List<TaskModel>>((ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return TasksNotifier(taskRepository);
});
