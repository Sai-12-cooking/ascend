import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_profile_provider.dart';
import '../views/subscription_view.dart';

class PremiumGate extends ConsumerWidget {
  final Widget child;

  const PremiumGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);

    if (profile.isPremium) {
      return child;
    }

    return const SubscriptionView();
  }
}
