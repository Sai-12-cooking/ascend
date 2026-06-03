import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend_app/main.dart';
import 'package:ascend_app/providers/task_provider.dart';
import 'package:ascend_app/providers/auth_provider.dart';
import 'package:ascend_app/repositories/task_repository.dart';
import 'package:ascend_app/repositories/auth_repository.dart';
import 'package:ascend_app/models/task_model.dart';

class FakeTaskRepository extends TaskRepository {
  FakeTaskRepository() : super(firestore: null);

  @override
  Future<List<TaskModel>> fetchTasksForDate(String userId, DateTime date) async {
    return [
      TaskModel(
        id: 'mock_task_1',
        userId: userId,
        title: 'Mock Quest 1',
        category: 'Workout',
        xpReward: 20,
      ),
    ];
  }

  @override
  Future<void> createTask(TaskModel task) async {}

  @override
  Future<void> updateTask(TaskModel task) async {}
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(firebaseAuth: null, firestore: null);
}

void main() {
  testWidgets('DashboardView loads and renders ASCEND title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the title ASCEND is present on the Dashboard
    expect(find.text('ASCEND'), findsOneWidget);
    
    // Verify that the attributes section is present
    expect(find.text('CORE ATTRIBUTES'), findsOneWidget);
  });
}
