import 'package:flutter_test/flutter_test.dart';
import 'package:ascend_app/models/player_profile.dart';
import 'package:ascend_app/providers/player_profile_provider.dart';

void main() {
  group('PlayerProfile Model Tests', () {
    test('initializes with correct defaults', () {
      final profile = PlayerProfile(uid: 'user_123', username: 'Ascender');

      expect(profile.uid, 'user_123');
      expect(profile.username, 'Ascender');
      expect(profile.currentRank, 'E');
      expect(profile.totalXp, 0);
      expect(profile.streakCount, 0);
      expect(profile.coreStats, {
        'Strength': 10,
        'Intelligence': 10,
        'Discipline': 10,
        'Wealth': 10,
        'Charisma': 10,
      });
    });

    test('copyWith creates a new instance with updated values', () {
      final profile = PlayerProfile(uid: 'user_123', username: 'Ascender');
      final updated = profile.copyWith(
        username: 'NewName',
        totalXp: 100,
        currentRank: 'D',
        streakCount: 5,
        coreStats: {'Strength': 12, 'Intelligence': 10, 'Discipline': 10, 'Wealth': 10, 'Charisma': 10},
      );

      expect(updated.uid, 'user_123');
      expect(updated.username, 'NewName');
      expect(updated.currentRank, 'D');
      expect(updated.totalXp, 100);
      expect(updated.streakCount, 5);
      expect(updated.coreStats['Strength'], 12);
      expect(updated.coreStats['Intelligence'], 10);
    });

    test('serialization toMap and fromMap works correctly', () {
      final profile = PlayerProfile(
        uid: 'user_123',
        username: 'Ascender',
        totalXp: 200,
        currentRank: 'D',
        streakCount: 2,
      );

      final map = profile.toMap();
      expect(map['uid'], 'user_123');
      expect(map['username'], 'Ascender');
      expect(map['total_xp'], 200);
      expect(map['current_rank'], 'D');
      expect(map['streak_count'], 2);

      final deserialized = PlayerProfile.fromMap(map);
      expect(deserialized.uid, 'user_123');
      expect(deserialized.username, 'Ascender');
      expect(deserialized.totalXp, 200);
      expect(deserialized.currentRank, 'D');
      expect(deserialized.streakCount, 2);
      expect(deserialized.coreStats['Strength'], 10);
    });
  });

  group('PlayerProfileNotifier Tests', () {
    late PlayerProfile initialProfile;
    late PlayerProfileNotifier notifier;

    setUp(() {
      initialProfile = PlayerProfile(uid: 'user_123', username: 'Ascender');
      notifier = PlayerProfileNotifier(initialProfile);
    });

    test('initial state matches the initial profile', () {
      expect(notifier.state.totalXp, 0);
      expect(notifier.state.currentRank, 'E');
    });

    test('addXP adds experience points', () {
      notifier.addXP(50);
      expect(notifier.state.totalXp, 50);
      notifier.addXP(40);
      expect(notifier.state.totalXp, 90);
    });

    test('addXP ignores negative or zero experience points', () {
      notifier.addXP(0);
      expect(notifier.state.totalXp, 0);
      notifier.addXP(-10);
      expect(notifier.state.totalXp, 0);
    });

    test('evaluates Rank E threshold (< 150 XP)', () {
      notifier.addXP(149);
      expect(notifier.state.currentRank, 'E');
    });

    test('evaluates Rank D threshold (150 - 499 XP)', () {
      notifier.addXP(150);
      expect(notifier.state.currentRank, 'D');

      notifier.addXP(349); // Total 499 XP
      expect(notifier.state.totalXp, 499);
      expect(notifier.state.currentRank, 'D');
    });

    test('evaluates Rank C threshold (500 - 1199 XP)', () {
      notifier.addXP(500);
      expect(notifier.state.currentRank, 'C');

      notifier.addXP(699); // Total 1199 XP
      expect(notifier.state.totalXp, 1199);
      expect(notifier.state.currentRank, 'C');
    });

    test('evaluates Rank B threshold (1200 - 2499 XP)', () {
      notifier.addXP(1200);
      expect(notifier.state.currentRank, 'B');

      notifier.addXP(1299); // Total 2499 XP
      expect(notifier.state.totalXp, 2499);
      expect(notifier.state.currentRank, 'B');
    });

    test('evaluates Rank A threshold (2500 - 4999 XP)', () {
      notifier.addXP(2500);
      expect(notifier.state.currentRank, 'A');

      notifier.addXP(2499); // Total 4999 XP
      expect(notifier.state.totalXp, 4999);
      expect(notifier.state.currentRank, 'A');
    });

    test('evaluates Rank S threshold (5000 - 9999 XP)', () {
      notifier.addXP(5000);
      expect(notifier.state.currentRank, 'S');

      notifier.addXP(4999); // Total 9999 XP
      expect(notifier.state.totalXp, 9999);
      expect(notifier.state.currentRank, 'S');
    });

    test('evaluates Rank Monarch threshold (>= 10000 XP)', () {
      notifier.addXP(10000);
      expect(notifier.state.currentRank, 'Monarch');

      notifier.addXP(5000); // Total 15000 XP
      expect(notifier.state.totalXp, 15000);
      expect(notifier.state.currentRank, 'Monarch');
    });
  });
}
