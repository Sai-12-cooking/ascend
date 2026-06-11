import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'views/dashboard_view.dart';
import 'views/onboarding_survey_view.dart';
import 'services/payment_service.dart';
import 'providers/player_profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await PaymentService.initialize();
  } catch (e) {
    debugPrint('Stripe init error: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASCEND',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const InitializationGate(),
    );
  }
}

class InitializationGate extends ConsumerWidget {
  const InitializationGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);

    if (profile.primaryFitnessGoal == 'Unset') {
      return const OnboardingSurveyView();
    }

    return const DashboardView();
  }
}
