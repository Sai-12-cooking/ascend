import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier managing whether the daily "System Activated" popup should be shown.
/// Default starts as `true` (needs to be shown) and changes to `false` when dismissed.
class DailyPopupNotifier extends StateNotifier<bool> {
  DailyPopupNotifier() : super(true);

  /// Dismisses the popup so that it doesn't show again in the current session.
  void dismissPopup() {
    state = false;
  }
}

/// Provider exposing the daily popup state.
final dailyPopupProvider =
    StateNotifierProvider<DailyPopupNotifier, bool>((ref) {
  return DailyPopupNotifier();
});
