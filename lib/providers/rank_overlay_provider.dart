import 'package:flutter_riverpod/flutter_riverpod.dart';

class RankOverlayState {
  final bool isDisplayingRankUp;
  final String newRankTitle;

  const RankOverlayState({
    this.isDisplayingRankUp = false,
    this.newRankTitle = '',
  });

  RankOverlayState copyWith({
    bool? isDisplayingRankUp,
    String? newRankTitle,
  }) {
    return RankOverlayState(
      isDisplayingRankUp: isDisplayingRankUp ?? this.isDisplayingRankUp,
      newRankTitle: newRankTitle ?? this.newRankTitle,
    );
  }
}

class RankOverlayNotifier extends StateNotifier<RankOverlayState> {
  RankOverlayNotifier() : super(const RankOverlayState());

  void showOverlay(String rankTitle) {
    state = state.copyWith(isDisplayingRankUp: true, newRankTitle: rankTitle);
  }

  void hideOverlay() {
    state = state.copyWith(isDisplayingRankUp: false);
  }
}

final rankOverlayProvider = StateNotifierProvider<RankOverlayNotifier, RankOverlayState>((ref) {
  return RankOverlayNotifier();
});
