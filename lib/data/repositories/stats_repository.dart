import '../../engine/models/difficulty.dart';

class StatsRecord {
  final Difficulty difficulty;
  final int seed;
  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;
  final DateTime completedAt;

  const StatsRecord({
    required this.difficulty,
    required this.seed,
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.completedAt,
  });
}

abstract class StatsRepository {
  Future<void> recordCompletion(StatsRecord record);
  Future<List<StatsRecord>> history({Difficulty? difficulty});
  Future<StatsRecord?> bestTime(Difficulty difficulty);
  Future<int> currentStreak();
}
