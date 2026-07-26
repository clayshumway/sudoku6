import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/stats_repository.dart';
import '../engine/models/difficulty.dart';
import 'repository_providers.dart';

final statsHistoryProvider =
    FutureProvider.autoDispose<List<StatsRecord>>((ref) {
  return ref.watch(statsRepositoryProvider).history();
});

final bestTimeProvider =
    FutureProvider.autoDispose.family<StatsRecord?, Difficulty>((ref, difficulty) {
  return ref.watch(statsRepositoryProvider).bestTime(difficulty);
});

final currentStreakProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(statsRepositoryProvider).currentStreak();
});
