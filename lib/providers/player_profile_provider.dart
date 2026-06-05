import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_profile.dart';
import 'rank_overlay_provider.dart';

/// A [StateNotifier] that manages the [PlayerProfile] state.
class PlayerProfileNotifier extends StateNotifier<PlayerProfile> {
  final Ref ref;

  PlayerProfileNotifier(super.initialProfile, this.ref);

  /// Adds [amount] to the total XP and automatically updates the player's rank.
  void addXP(int amount) {
    if (amount <= 0) return;
    
    final newXp = state.totalXp + amount;
    final newRank = _evaluateRank(newXp);
    
    if (_rankLevel(newRank) > _rankLevel(state.currentRank)) {
      ref.read(rankOverlayProvider.notifier).showOverlay(newRank);
    }
    
    state = state.copyWith(
      totalXp: newXp,
      currentRank: newRank,
    );
  }

  /// Removes [amount] from the total XP and automatically updates the player's rank.
  void removeXP(int amount) {
    if (amount <= 0) return;
    
    final newXp = (state.totalXp - amount).clamp(0, 999999);
    final newRank = _evaluateRank(newXp);
    
    state = state.copyWith(
      totalXp: newXp,
      currentRank: newRank,
    );
  }

  /// Upgrades the user to premium.
  void unlockPremium() {
    state = state.copyWith(isPremium: true);
  }

  /// Evaluates and returns the player's rank based on experience points:
  /// - Rank E: < 150 XP
  /// - Rank D: 150 - 499 XP
  /// - Rank C: 500 - 1199 XP
  /// - Rank B: 1200 - 2499 XP
  /// - Rank A: 2500 - 4999 XP
  /// - Rank S: 5000 - 9999 XP
  /// - Rank Monarch: >= 10000 XP
  String _evaluateRank(int xp) {
    if (xp < 150) {
      return 'E';
    } else if (xp < 500) {
      return 'D';
    } else if (xp < 1200) {
      return 'C';
    } else if (xp < 2500) {
      return 'B';
    } else if (xp < 5000) {
      return 'A';
    } else if (xp < 10000) {
      return 'S';
    } else {
      return 'Monarch';
    }
  }

  int _rankLevel(String rank) {
    switch (rank) {
      case 'E': return 0;
      case 'D': return 1;
      case 'C': return 2;
      case 'B': return 3;
      case 'A': return 4;
      case 'S': return 5;
      case 'Monarch': return 6;
      default: return 0;
    }
  }
}

/// A provider for the [PlayerProfileNotifier] and its state.
final playerProfileProvider =
    StateNotifierProvider<PlayerProfileNotifier, PlayerProfile>((ref) {
  return PlayerProfileNotifier(
    PlayerProfile(
      uid: 'default_uid',
      username: 'Player 1',
    ),
    ref,
  );
});
