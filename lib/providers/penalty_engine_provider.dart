import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/penalty_engine.dart';
import 'task_provider.dart';

final penaltyEngineProvider = Provider<PenaltyEngine>((ref) {
  final aiSchedulerService = ref.watch(aiSchedulerServiceProvider);
  return PenaltyEngine(aiSchedulerService: aiSchedulerService);
});
