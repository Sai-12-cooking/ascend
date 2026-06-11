import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/player_profile.dart';
import '../models/task_model.dart';

class AiSchedulerService {
  final Dio _dio;
  final String _apiKey;

  AiSchedulerService({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '') {
    if (kDebugMode && _apiKey.isEmpty) {
      debugPrint('WARNING: OPENAI_API_KEY is missing. AI Scheduler will not function correctly.');
    }
  }

  Future<List<TaskModel>> generateDailyQuests({
    required String userId,
    required PlayerProfile profile,
    required List<TaskModel> yesterdayTasks,
  }) async {
    final failedTasks = yesterdayTasks.where((t) => !t.isCompleted).toList();
    final failedTaskTitles = failedTasks.map((t) => t.title).join(', ');

    final prompt = '''
You are the System Game Master for ASCEND. You must generate 3 personalized daily tasks inside a strictly typed JSON array. 
The player's Global Tier is: ${profile.globalFitnessTier}. 
Granular Physical Baselines:
- Max Pushups: ${profile.physicalBaselines['pushups'] ?? 0} reps
- Max Pullups: ${profile.physicalBaselines['pullups'] ?? 0} reps
- 1-Mile Run Time: ${profile.physicalBaselines['mileTimeSeconds'] ?? 0} seconds
- Max Plank Hold: ${profile.physicalBaselines['plankSeconds'] ?? 0} seconds

CRITICAL INPUT COMPONENT-LEVEL SCALING RULE: Do not apply the global tier blindly across all generated tasks. Evaluate each task category individually against the specific physical baseline metric. If a player has high pushup counts but a slow mile run time, generate advanced upper body challenges but keep running tasks strictly matched to their lower endurance threshold.

Their primary objective is: ${profile.primaryFitnessGoal}.

Yesterday, the user failed to complete the following tasks: ${failedTaskTitles.isEmpty ? 'None' : failedTaskTitles}.

Tailor task flavors to match their primary objective of ${profile.primaryFitnessGoal} explicitly!

Respond with a JSON object containing a single key "quests" that holds an array of task objects.
Each task object must exactly match:
{
  "title": "string",
  "category": "string (Workout, Focus Work, Learning, Daily Discipline)",
  "isMandatory": true,
  "xpReward": integer (10 to 30)
}
''';

    try {
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'google/gemma-3-12b-instruct:free',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant that outputs strictly JSON.'},
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.7,
        },
      );

      final data = response.data;
      final content = data['choices'][0]['message']['content'];
      
      final parsedMap = jsonDecode(content);
      final jsonList = parsedMap['quests'] as List<dynamic>? ?? [];

      const uuid = Uuid();
      final List<TaskModel> generatedTasks = [];
      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      for (var item in jsonList) {
        generatedTasks.add(
          TaskModel(
            id: uuid.v4(),
            userId: userId,
            title: item['title'].toString(),
            category: item['category'].toString(),
            isMandatory: item['isMandatory'] == true,
            isCompleted: false,
            xpReward: (item['xpReward'] as num?)?.toInt() ?? 15,
            createdAt: now,
            deadline: endOfDay,
          ),
        );
      }

      return generatedTasks;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to generate daily quests: $e');
      }
      return [];
    }
  }

  TaskModel generateRecoveryQuest({required String userId}) {
    final now = DateTime.now();
    return TaskModel(
      id: const Uuid().v4(),
      userId: userId,
      title: 'System Recovery: Re-ignition Quest',
      description: 'The System has detected a prolonged state of inactivity. Complete this emergency trial to stabilize your player status.',
      category: 'System',
      isMandatory: true,
      isCompleted: false,
      xpReward: 5,
      createdAt: DateTime(now.year, now.month, now.day),
    );
  }

  TaskModel generatePenaltyQuest({required String userId}) {
    final now = DateTime.now();
    return TaskModel(
      id: const Uuid().v4(),
      userId: userId,
      title: 'Penalty Quest: Double Down Challenge',
      description: 'You missed your deadlines. Complete this urgent challenge to reclaim your standing.',
      category: 'System',
      isMandatory: true,
      isCompleted: false,
      xpReward: 30,
      createdAt: DateTime(now.year, now.month, now.day),
      deadline: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }
}
