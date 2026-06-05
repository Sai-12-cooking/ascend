class PlayerProfile {
  final String uid;
  final String username;
  final String currentRank;
  final int totalXp;
  final int streakCount;
  final Map<String, int> coreStats;
  final bool isPremium;

  PlayerProfile({
    required this.uid,
    required this.username,
    this.currentRank = 'E',
    this.totalXp = 0,
    this.streakCount = 0,
    this.isPremium = false,
    Map<String, int>? coreStats,
  }) : coreStats = coreStats ??
            {
              'Strength': 10,
              'Intelligence': 10,
              'Discipline': 10,
              'Wealth': 10,
              'Charisma': 10,
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
  }) {
    return PlayerProfile(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      currentRank: currentRank ?? this.currentRank,
      totalXp: totalXp ?? this.totalXp,
      streakCount: streakCount ?? this.streakCount,
      coreStats: coreStats ?? Map<String, int>.from(this.coreStats),
      isPremium: isPremium ?? this.isPremium,
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

    return PlayerProfile(
      uid: map['uid'] as String,
      username: map['username'] as String,
      currentRank: map['current_rank'] as String? ?? 'E',
      totalXp: (map['total_xp'] as num? ?? 0).toInt(),
      streakCount: (map['streak_count'] as num? ?? 0).toInt(),
      coreStats: statsMap.isNotEmpty ? statsMap : null,
      isPremium: map['is_premium'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'PlayerProfile(uid: $uid, username: $username, currentRank: $currentRank, totalXp: $totalXp, streakCount: $streakCount, coreStats: $coreStats)';
  }
}
