import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_profile_provider.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

class SubscriptionView extends ConsumerStatefulWidget {
  const SubscriptionView({super.key});

  @override
  ConsumerState<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends ConsumerState<SubscriptionView> {
  bool _isLoading = false;

  Future<void> _handleCheckout() async {
    setState(() => _isLoading = true);
    
    final success = await ref.read(paymentServiceProvider).processCheckout();
    
    setState(() => _isLoading = false);

    if (success && mounted) {
      ref.read(playerProfileProvider.notifier).unlockPremium();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to Ascend Pro!')),
      );
      Navigator.of(context).pop(); // Go back to whatever they were trying to access
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Premium'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.workspace_premium, size: 80, color: AppTheme.goldColor),
              const SizedBox(height: 24),
              const Text(
                'ASCEND PRO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppTheme.goldColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unlock the ultimate toolset to maximize your focus and track your legacy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              _buildFeatureItem(Icons.psychology, 'Advanced AI Coaching'),
              _buildFeatureItem(Icons.groups, 'Guilds & Leaderboards'),
              _buildFeatureItem(Icons.self_improvement, 'Monk Mode Focus Lock'),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: _isLoading ? null : _handleCheckout,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('UPGRADE NOW - \$9.99/mo', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 32),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
