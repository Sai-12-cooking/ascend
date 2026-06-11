import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerProfile {
  final String uid;
  final String username;
  final String currentRank;
  final int totalXp;
  final int streakCount;
  final Map<String, int> coreStats;
  final bool isPremium;
  final DateTime? updatedAt;
  final String globalFitnessTier;
  final Map<String, int> physicalBaselines;
  final String primaryFitnessGoal;

  PlayerProfile({
    required this.uid,
    required this.username,
    this.currentRank = 'E',
    this.totalXp = 0,
    this.streakCount = 0,
    this.isPremium = false,
    this.updatedAt,
    this.globalFitnessTier = 'Unset',
    this.primaryFitnessGoal = 'Unset',
    Map<String, int>? physicalBaselines,
    Map<String, int>? coreStats,
  }) : coreStats = coreStats ??
            {
              'Strength': 10,
              'Intelligence': 10,
              'Discipline': 10,
              'Wealth': 10,
              'Charisma': 10,
            },
       physicalBaselines = physicalBaselines ??
            {
              'pushups': 0,
              'pullups': 0,
              'mileTimeSeconds': 0,
              'plankSeconds': 0,
            };

  /// Creates a copy of this [PlayerProfile] but with the given fields replaced
  /// with the new values.
  PlayerProfile copyWith({
    String? uid,
    String? username,
    String? currentRank,
    int? totalXp,
    int? streakCount,
    Map<String, int>? coreStats,
    bool? isPremium,
    DateTime? updatedAt,
    String? globalFitnessTier,
    Map<String, int>? physicalBaselines,
    String? primaryFitnessGoal,
  }) {
    return PlayerProfile(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      currentRank: currentRank ?? this.currentRank,
      totalXp: totalXp ?? this.totalXp,
      streakCount: streakCount ?? this.streakCount,
      coreStats: coreStats ?? Map<String, int>.from(this.coreStats),
      isPremium: isPremium ?? this.isPremium,
      updatedAt: updatedAt ?? this.updatedAt,
      globalFitnessTier: globalFitnessTier ?? this.globalFitnessTier,
      physicalBaselines: physicalBaselines ?? Map<String, int>.from(this.physicalBaselines),
      primaryFitnessGoal: primaryFitnessGoal ?? this.primaryFitnessGoal,
    );
  }

  /// Converts this [PlayerProfile] to a Map suitable for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'current_rank': currentRank,
      'total_xp': totalXp,
      'streak_count': streakCount,
      'core_stats': Map<String, dynamic>.from(coreStats),
      'is_premium': isPremium,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'global_fitness_tier': globalFitnessTier,
      'physical_baselines': Map<String, dynamic>.from(physicalBaselines),
      'primary_fitness_goal': primaryFitnessGoal,
    };
  }

  /// Creates a [PlayerProfile] from a Map retrieved from Firestore.
  factory PlayerProfile.fromMap(Map<String, dynamic> map) {
    final Map<String, int> statsMap = {};
    if (map['core_stats'] != null) {
      (map['core_stats'] as Map<dynamic, dynamic>).forEach((key, value) {
        statsMap[key.toString()] = (value as num).toInt();
      });
    }

    final Map<String, int> baselinesMap = {};
    if (map['physical_baselines'] != null) {
      (map['physical_baselines'] as Map<dynamic, dynamic>).forEach((key, value) {
        baselinesMap[key.toString()] = (value as num).toInt();
      });
    }

    DateTime? parsedUpdatedAt;
    final rawUpdatedAt = map['updated_at'];
    if (rawUpdatedAt is Timestamp) {
      parsedUpdatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is String) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt);
    } else if (rawUpdatedAt is DateTime) {
      parsedUpdatedAt = rawUpdatedAt;
    }

    return PlayerProfile(
      uid: map['uid'] as String,
      username: map['username'] as String,
      currentRank: map['current_rank'] as String? ?? 'E',
      totalXp: (map['total_xp'] as num? ?? 0).toInt(),
      streakCount: (map['streak_count'] as num? ?? 0).toInt(),
      coreStats: statsMap.isNotEmpty ? statsMap : null,
      isPremium: map['is_premium'] as bool? ?? false,
      updatedAt: parsedUpdatedAt ?? DateTime.now(),
      globalFitnessTier: map['global_fitness_tier'] as String? ?? 'Unset',
      physicalBaselines: baselinesMap.isNotEmpty ? baselinesMap : null,
      primaryFitnessGoal: map['primary_fitness_goal'] as String? ?? 'Unset',
    );
  }

  @override
  String toString() {
    return 'PlayerProfile(uid: $uid, username: $username, currentRank: $currentRank, totalXp: $totalXp, streakCount: $streakCount, coreStats: $coreStats, updatedAt: $updatedAt, globalFitnessTier: $globalFitnessTier, physicalBaselines: $physicalBaselines, primaryFitnessGoal: $primaryFitnessGoal)';
  }
}
