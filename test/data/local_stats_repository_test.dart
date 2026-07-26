import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sudoku6/data/hive_boxes.dart';
import 'package:sudoku6/data/models/puzzle_state_hive.dart';
import 'package:sudoku6/data/models/settings_hive.dart';
import 'package:sudoku6/data/models/stats_entry_hive.dart';
import 'package:sudoku6/data/repositories/local_stats_repository.dart';
import 'package:sudoku6/data/repositories/stats_repository.dart';
import 'package:sudoku6/engine/models/difficulty.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sudoku6_stats_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PuzzleStateHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StatsEntryHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SettingsHiveAdapter());
    }
    await Hive.openBox<StatsEntryHive>(HiveBoxes.stats);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('recordCompletion + history round-trips and sorts newest first',
      () async {
    final repo = LocalStatsRepository();
    await repo.recordCompletion(StatsRecord(
      difficulty: Difficulty.easy,
      seed: 1,
      elapsedSeconds: 100,
      mistakes: 0,
      hintsUsed: 0,
      completedAt: DateTime(2026, 1, 1),
    ));
    await repo.recordCompletion(StatsRecord(
      difficulty: Difficulty.easy,
      seed: 2,
      elapsedSeconds: 80,
      mistakes: 1,
      hintsUsed: 0,
      completedAt: DateTime(2026, 1, 2),
    ));

    final history = await repo.history();
    expect(history.length, 2);
    expect(history.first.seed, 2);
  });

  test('bestTime returns the fastest completion for a tier', () async {
    final repo = LocalStatsRepository();
    await repo.recordCompletion(StatsRecord(
      difficulty: Difficulty.medium,
      seed: 1,
      elapsedSeconds: 200,
      mistakes: 0,
      hintsUsed: 0,
      completedAt: DateTime(2026, 1, 1),
    ));
    await repo.recordCompletion(StatsRecord(
      difficulty: Difficulty.medium,
      seed: 2,
      elapsedSeconds: 90,
      mistakes: 0,
      hintsUsed: 0,
      completedAt: DateTime(2026, 1, 2),
    ));

    final best = await repo.bestTime(Difficulty.medium);
    expect(best!.elapsedSeconds, 90);
  });

  test('bestTime returns null when no completions exist for a tier',
      () async {
    final repo = LocalStatsRepository();
    expect(await repo.bestTime(Difficulty.expert), isNull);
  });

  test('currentStreak counts consecutive days ending today', () async {
    final repo = LocalStatsRepository();
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    for (final day in [today, yesterday, twoDaysAgo]) {
      await repo.recordCompletion(StatsRecord(
        difficulty: Difficulty.easy,
        seed: day.millisecondsSinceEpoch,
        elapsedSeconds: 60,
        mistakes: 0,
        hintsUsed: 0,
        completedAt: day,
      ));
    }

    expect(await repo.currentStreak(), 3);
  });

  test('currentStreak is 0 if the most recent completion was not today or yesterday',
      () async {
    final repo = LocalStatsRepository();
    await repo.recordCompletion(StatsRecord(
      difficulty: Difficulty.easy,
      seed: 1,
      elapsedSeconds: 60,
      mistakes: 0,
      hintsUsed: 0,
      completedAt: DateTime.now().subtract(const Duration(days: 5)),
    ));
    expect(await repo.currentStreak(), 0);
  });
}
