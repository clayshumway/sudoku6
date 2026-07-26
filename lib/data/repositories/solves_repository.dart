import '../../engine/models/difficulty.dart';

/// One player's ranked result on one puzzle.
class LeaderboardEntry {
  final String userId;
  final String username;
  final int elapsedMs;
  final int mistakes;
  final int hintsUsed;
  final DateTime completedAt;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.elapsedMs,
    required this.mistakes,
    required this.hintsUsed,
    required this.completedAt,
  });
}

abstract class SolvesRepository {
  /// Records a finished puzzle. Replaying the same puzzle replaces the
  /// previous row rather than adding a second entry for the same player.
  Future<void> recordSolve({
    required Difficulty difficulty,
    required int seed,
    required int elapsedMs,
    required int mistakes,
    required int hintsUsed,
  });

  /// Everyone's times on one specific puzzle, fastest first.
  Future<List<LeaderboardEntry>> leaderboard({
    required Difficulty difficulty,
    required int seed,
    int limit = 50,
  });
}
