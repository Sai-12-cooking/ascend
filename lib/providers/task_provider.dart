import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/player_profile.dart';
import '../repositories/task_repository.dart';
import '../services/ai_scheduler_service.dart';

/// Provider for the [TaskRepository].
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

/// Provider for the [AiSchedulerService].
final aiSchedulerServiceProvider = Provider<AiSchedulerService>((ref) {
  return AiSchedulerService();
});

/// Notifier that manages the daily task list state.
class TasksNotifier extends StateNotifier<List<TaskModel>> {
  final TaskRepository _taskRepository;
  final AiSchedulerService _aiSchedulerService;

  TasksNotifier(this._taskRepository, this._aiSchedulerService) : super([]);

  /// Fetches today's tasks for [userId] from Firestore.
  Future<void> fetchTodayTasks(String userId) async {
    try {
      final tasks = await _taskRepository.fetchTasksForDate(userId, DateTime.now());
      state = tasks;
    } catch (e) {
      state = [];
    }
  }

  /// Generates new daily quests via AI and saves them.
  Future<void> generateAndSaveDailyQuests(String userId, PlayerProfile profile) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayTasks = await _taskRepository.fetchTasksForDate(userId, yesterday);
      
      final newTasks = await _aiSchedulerService.generateDailyQuests(
        userId: userId,
        profile: profile,
        yesterdayTasks: yesterdayTasks,
      );
      
      for (var task in newTasks) {
        await _taskRepository.createTask(task);
      }
      
      state = newTasks;
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
  final aiSchedulerService = ref.watch(aiSchedulerServiceProvider);
  return TasksNotifier(taskRepository, aiSchedulerService);
});
