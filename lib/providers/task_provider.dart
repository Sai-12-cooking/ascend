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
      if (tasks.isEmpty) {
        // Fallback: Populate some default daily quests for visual demo if empty
        state = [
          TaskModel(
            id: 'quest_1',
            userId: userId,
            title: 'Morning Cardio Run',
            category: 'Workout',
            xpReward: 20,
          ),
          TaskModel(
            id: 'quest_2',
            userId: userId,
            title: 'Solve LeetCode Medium',
            category: 'Focus Work',
            xpReward: 15,
          ),
          TaskModel(
            id: 'quest_3',
            userId: userId,
            title: 'Read 15 Pages of Book',
            category: 'Learning',
            isMandatory: false,
            xpReward: 10,
          ),
        ];
      } else {
        state = tasks;
      }
    } catch (e) {
      state = [];
    }
  }

  /// Adds a new task to the local state and remote Firestore.
  Future<void> addTask(TaskModel task) async {
    state = [...state, task];
    try {
      await _taskRepository.createTask(task);
    } catch (e) {
      // Revert if remote fails
      state = state.where((t) => t.id != task.id).toList();
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
