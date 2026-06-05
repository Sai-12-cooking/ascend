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
}
