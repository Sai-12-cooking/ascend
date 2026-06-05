import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

class PaymentService {
  static Future<void> initialize() async {
    const stripeKey = String.fromEnvironment('STRIPE_PUB_KEY', defaultValue: '');
    if (kDebugMode && stripeKey.isEmpty) {
      debugPrint('WARNING: STRIPE_PUB_KEY is missing. Stripe will not initialize.');
    }
    Stripe.publishableKey = stripeKey;
    if (stripeKey.isNotEmpty) {
      await Stripe.instance.applySettings();
    }
  }

  /// Simulates a checkout process that would normally use PaymentIntents.
  Future<bool> processCheckout() async {
    if (kDebugMode) {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }
    
    // In production, require actual backend intent.
    // Ensure it fails safely instead of returning simulated success.
    throw UnimplementedError('Real payment backend not connected.');
  }
}
