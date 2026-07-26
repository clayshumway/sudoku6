import 'package:hive/hive.dart';

import '../../engine/models/difficulty.dart';
import '../hive_boxes.dart';
import '../models/stats_entry_hive.dart';
import 'stats_repository.dart';

class LocalStatsRepository implements StatsRepository {
  Box<StatsEntryHive> get _box => Hive.box<StatsEntryHive>(HiveBoxes.stats);

  @override
  Future<void> recordCompletion(StatsRecord record) async {
    await _box.add(StatsEntryHive(
      difficulty: record.difficulty.name,
      seed: record.seed,
      elapsedSeconds: record.elapsedSeconds,
      mistakes: record.mistakes,
      hintsUsed: record.hintsUsed,
      completedAtMillis: record.completedAt.millisecondsSinceEpoch,
    ));
  }

  @override
  Future<List<StatsRecord>> history({Difficulty? difficulty}) async {
    final records = _box.values
        .where((e) => difficulty == null || e.difficulty == difficulty.name)
        .map(_toRecord)
        .toList();
    records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return records;
  }

  @override
  Future<StatsRecord?> bestTime(Difficulty difficulty) async {
    final entries =
        _box.values.where((e) => e.difficulty == difficulty.name).toList();
    if (entries.isEmpty) return null;
    final best =
        entries.reduce((a, b) => a.elapsedSeconds <= b.elapsedSeconds ? a : b);
    return _toRecord(best);
  }

  @override
  Future<int> currentStreak() async {
    final days = _box.values
        .map((e) => DateTime.fromMillisecondsSinceEpoch(e.completedAtMillis))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList();
    days.sort((a, b) => b.compareTo(a));
    if (days.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    if (days.first != todayDate && days.first != yesterday) return 0;

    var streak = 1;
    var cursor = days.first;
    for (var i = 1; i < days.length; i++) {
      if (cursor.difference(days[i]).inDays == 1) {
        streak++;
        cursor = days[i];
      } else {
        break;
      }
    }
    return streak;
  }

  StatsRecord _toRecord(StatsEntryHive e) => StatsRecord(
        difficulty:
            Difficulty.values.firstWhere((d) => d.name == e.difficulty),
        seed: e.seed,
        elapsedSeconds: e.elapsedSeconds,
        mistakes: e.mistakes,
        hintsUsed: e.hintsUsed,
        completedAt: DateTime.fromMillisecondsSinceEpoch(e.completedAtMillis),
      );
}
