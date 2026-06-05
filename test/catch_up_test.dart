import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ascend_app/models/player_profile.dart';
import 'package:ascend_app/models/task_model.dart';
import 'package:ascend_app/services/ai_scheduler_service.dart';
import 'package:ascend_app/services/penalty_engine.dart';

class MockAiSchedulerService extends Mock implements AiSchedulerService {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockWriteBatch extends Mock implements WriteBatch {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late PenaltyEngine engine;
  late MockAiSchedulerService mockAiService;
  late MockFirebaseFirestore mockFirestore;
  late MockWriteBatch mockBatch;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(MockDocumentReference());
  });

  setUp(() {
    mockAiService = MockAiSchedulerService();
    mockFirestore = MockFirebaseFirestore();
    mockBatch = MockWriteBatch();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();

    when(() => mockFirestore.batch()).thenReturn(mockBatch);
    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDoc);
    
    when(() => mockBatch.update(any<DocumentReference<Object?>>(), any<Map<String, dynamic>>())).thenReturn(null);
    when(() => mockBatch.set(any<DocumentReference<Object?>>(), any<Map<String, dynamic>>())).thenReturn(null);
    when(() => mockBatch.commit()).thenAnswer((_) async => []);
    when(() => mockDoc.update(any())).thenAnswer((_) async => null);

    engine = PenaltyEngine(
      aiSchedulerService: mockAiService,
      firestore: mockFirestore,
    );
  });

  test('0-day miss (yesterday to today) - no penalty, just updates timestamp', () async {
    final yesterday = DateTime(2023, 10, 10, 15, 0); // Oct 10
    final today = DateTime(2023, 10, 11, 10, 0); // Oct 11

    final profile = PlayerProfile(
      uid: 'user1',
      username: 'test',
      streakCount: 5,
      totalXp: 100,
      updatedAt: yesterday,
    );

    final result = await engine.verifyLastLoginCheckIn(profile, simulatedNow: today);

    expect(result.streakCount, 5);
    expect(result.totalXp, 100);
    expect(result.updatedAt, today);
    
    verify(() => mockDoc.update(any())).called(1);
    verifyNever(() => mockFirestore.batch());
    verifyNever(() => mockAiService.generateRecoveryQuest(userId: any(named: 'userId')));
  });

  test('1-day miss (Monday to Wednesday) - penalty applied, streak broken', () async {
    final monday = DateTime(2023, 10, 9, 15, 0); // Monday
    final wednesday = DateTime(2023, 10, 11, 10, 0); // Wednesday

    final profile = PlayerProfile(
      uid: 'user1',
      username: 'test',
      streakCount: 5,
      totalXp: 100,
      updatedAt: monday,
    );

    final mockTask = TaskModel(
      id: 'task1', 
      userId: 'user1', 
      title: 'System Recovery: Re-ignition Quest', 
      category: 'System', 
      createdAt: wednesday,
    );
    when(() => mockAiService.generateRecoveryQuest(userId: any(named: 'userId'))).thenReturn(mockTask);

    final result = await engine.verifyLastLoginCheckIn(profile, simulatedNow: wednesday);

    expect(result.streakCount, 0);
    expect(result.totalXp, 85); // 100 - 15 * 1
    expect(result.updatedAt, wednesday);

    verify(() => mockAiService.generateRecoveryQuest(userId: 'user1')).called(1);
    verify(() => mockFirestore.batch()).called(1);
    verify(() => mockBatch.commit()).called(1);
  });

  test('Compounding multi-day misses clamping total XP safely at 0', () async {
    final lastMonth = DateTime(2023, 9, 1); 
    final today = DateTime(2023, 10, 11); // 40 days later -> 39 days missed
    // 39 * 15 = 585 XP penalty

    final profile = PlayerProfile(
      uid: 'user1',
      username: 'test',
      streakCount: 5,
      totalXp: 100, // Should clamp to 0
      updatedAt: lastMonth,
    );

    final mockTask = TaskModel(
      id: 'task1', 
      userId: 'user1', 
      title: 'System Recovery: Re-ignition Quest', 
      category: 'System', 
      createdAt: today,
    );
    when(() => mockAiService.generateRecoveryQuest(userId: any(named: 'userId'))).thenReturn(mockTask);

    final result = await engine.verifyLastLoginCheckIn(profile, simulatedNow: today);

    expect(result.streakCount, 0);
    expect(result.totalXp, 0); // clamped
    expect(result.updatedAt, today);
  });
}
