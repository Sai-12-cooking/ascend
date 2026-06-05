import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:ascend_app/services/ai_scheduler_service.dart';
import 'package:ascend_app/models/player_profile.dart';
import 'package:ascend_app/models/task_model.dart';

class MockDio extends Mock implements Dio {}
class FakeOptions extends Fake implements Options {}

void main() {
  late MockDio mockDio;
  late AiSchedulerService aiService;

  setUpAll(() {
    registerFallbackValue(FakeOptions());
  });

  setUp(() {
    mockDio = MockDio();
    aiService = AiSchedulerService(dio: mockDio, apiKey: 'test_key');
  });

  test('generateDailyQuests parses valid OpenAI JSON array correctly', () async {
    // Arrange
    final fakeResponse = {
      'choices': [
        {
          'message': {
            'content': '''
            {
              "quests": [
                {
                  "title": "Do 50 Pushups",
                  "category": "Workout",
                  "isMandatory": true,
                  "xpReward": 20
                },
                {
                  "title": "Read 20 pages",
                  "category": "Learning",
                  "isMandatory": true,
                  "xpReward": 15
                }
              ]
            }
            '''
          }
        }
      ]
    };

    when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: fakeResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

    final profile = PlayerProfile(uid: 'user123', username: 'TestUser', currentRank: 'E');
    
    // Act
    final tasks = await aiService.generateDailyQuests(
      userId: 'user123',
      profile: profile,
      yesterdayTasks: [],
    );

    // Assert
    expect(tasks.length, 2);
    
    expect(tasks[0].title, "Do 50 Pushups");
    expect(tasks[0].category, "Workout");
    expect(tasks[0].isMandatory, isTrue);
    expect(tasks[0].xpReward, 20);
    expect(tasks[0].userId, 'user123');

    expect(tasks[1].title, "Read 20 pages");
    expect(tasks[1].category, "Learning");
    expect(tasks[1].isMandatory, isTrue);
    expect(tasks[1].xpReward, 15);
  });

  test('generateDailyQuests handles missing fields gracefully', () async {
    // Arrange
    final fakeResponse = {
      'choices': [
        {
          'message': {
            'content': '''
            {
              "quests": [
                {
                  "title": "Incomplete task",
                  "category": "Focus Work"
                }
              ]
            }
            '''
          }
        }
      ]
    };

    when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: fakeResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

    final profile = PlayerProfile(uid: 'user123', username: 'TestUser', currentRank: 'E');
    
    // Act
    final tasks = await aiService.generateDailyQuests(
      userId: 'user123',
      profile: profile,
      yesterdayTasks: [],
    );

    // Assert
    expect(tasks.length, 1);
    expect(tasks[0].title, "Incomplete task");
    expect(tasks[0].category, "Focus Work");
    expect(tasks[0].isMandatory, isFalse); 
    expect(tasks[0].xpReward, 15); 
  });
}
