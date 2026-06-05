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
You are an AI specialized in generating personalized, RPG-style daily quests.
The user's current Rank is ${profile.currentRank}.
Core Stats:
- Strength: ${profile.coreStats['Strength'] ?? 10}
- Intelligence: ${profile.coreStats['Intelligence'] ?? 10}
- Discipline: ${profile.coreStats['Discipline'] ?? 10}
- Wealth: ${profile.coreStats['Wealth'] ?? 10}
- Charisma: ${profile.coreStats['Charisma'] ?? 10}

Yesterday, the user failed to complete the following tasks: ${failedTaskTitles.isEmpty ? 'None' : failedTaskTitles}.

Generate exactly 3 to 4 daily quests for this user.
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
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4o',
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

      final uuid = const Uuid();
      final List<TaskModel> generatedTasks = [];

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
            createdAt: DateTime.now(),
          ),
        );
      }

      return generatedTasks;
    } catch (e) {
      throw Exception('Failed to generate daily quests: $e');
    }
  }
}
