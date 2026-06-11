import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_profile.dart';
import 'ai_scheduler_service.dart';

class PenaltyEngine {
  final AiSchedulerService _aiSchedulerService;
  final FirebaseFirestore _firestore;

  PenaltyEngine({
    required AiSchedulerService aiSchedulerService,
    FirebaseFirestore? firestore,
  })  : _aiSchedulerService = aiSchedulerService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<PlayerProfile> verifyLastLoginCheckIn(PlayerProfile profile, {DateTime? simulatedNow}) async {
    final now = simulatedNow ?? DateTime.now();
    final updatedAt = profile.updatedAt ?? now;

    final todayMidnight = DateTime(now.year, now.month, now.day);
    final lastLoginMidnight = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);

    final daysDifference = todayMidnight.difference(lastLoginMidnight).inDays;
    final daysMissed = daysDifference - 1;

    PlayerProfile updatedProfile = profile.copyWith(updatedAt: now);

    if (daysMissed >= 1) {
      final xpPenalty = 15 * daysMissed;
      final newTotalXp = max(0, profile.totalXp - xpPenalty);

      updatedProfile = updatedProfile.copyWith(
        streakCount: 0,
        totalXp: newTotalXp,
      );

      final recoveryQuest = _aiSchedulerService.generateRecoveryQuest(userId: profile.uid);

      final batch = _firestore.batch();
      
      final profileRef = _firestore.collection('users').doc(profile.uid);
      batch.update(profileRef, updatedProfile.toMap());

      final taskRef = _firestore.collection('tasks').doc(recoveryQuest.id);
      batch.set(taskRef, recoveryQuest.toMap());

      await batch.commit();
    } else {
      // Always update 'updatedAt' to the current time at completion.
      final profileRef = _firestore.collection('users').doc(profile.uid);
      await profileRef.update({'updated_at': Timestamp.fromDate(now)});
    }

    return updatedProfile;
  }

  Future<PlayerProfile> evaluatePassedDeadlines(String userId, PlayerProfile profile) async {
    final now = DateTime.now().toUtc();
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .get();

    final expiredTasks = <QueryDocumentSnapshot>[];

    for (var doc in tasksSnapshot.docs) {
      final data = doc.data();
      final deadlineField = data['deadline'];
      if (deadlineField != null) {
        DateTime deadline;
        if (deadlineField is Timestamp) {
          deadline = deadlineField.toDate().toUtc();
        } else if (deadlineField is String) {
          final parsed = DateTime.tryParse(deadlineField);
          if (parsed != null) {
            deadline = parsed.toUtc();
          } else {
            continue;
          }
        } else {
          continue;
        }

        if (now.isAfter(deadline)) {
          expiredTasks.add(doc);
        }
      }
    }

    if (expiredTasks.isEmpty) {
      return profile;
    }

    final batch = _firestore.batch();

    // Remove expired tasks
    for (var doc in expiredTasks) {
      batch.delete(doc.reference);
    }

    // Apply structured penalties: Break streak, deduct 15 XP
    const xpPenalty = 15;
    final newTotalXp = max(0, profile.totalXp - xpPenalty);
    
    final updatedProfile = profile.copyWith(
      streakCount: 0,
      totalXp: newTotalXp,
      updatedAt: now,
    );

    final profileRef = _firestore.collection('users').doc(userId);
    batch.update(profileRef, updatedProfile.toMap());

    // Inject automated Penalty Quest: Double Down Challenge
    final penaltyQuest = _aiSchedulerService.generatePenaltyQuest(userId: userId);
    final taskRef = _firestore.collection('tasks').doc(penaltyQuest.id);
    batch.set(taskRef, penaltyQuest.toMap());

    await batch.commit();

    return updatedProfile;
  }
}
