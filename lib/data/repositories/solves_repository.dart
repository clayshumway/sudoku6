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

/// How a global leaderboard is ranked.
///
/// [bestTime] and [averageTime] are per-difficulty only: a best time across
/// all difficulties is just someone's fastest Easy puzzle, so the overall
/// board ranks on volume and cleanliness instead.
enum LeaderboardSort {
  bestTime,
  averageTime,
  mostSolves,
  cleanSolves;

  bool get needsDifficulty =>
      this == LeaderboardSort.bestTime || this == LeaderboardSort.averageTime;

  String get label => switch (this) {
        LeaderboardSort.bestTime => 'Best time',
        LeaderboardSort.averageTime => 'Average time',
        LeaderboardSort.mostSolves => 'Most solved',
        LeaderboardSort.cleanSolves => 'Clean solves',
      };
}

/// One player's aggregate record, across one difficulty or across all of them.
class GlobalLeaderboardEntry {
  final String userId;
  final String username;

  /// Null on an all-difficulties row.
  final Difficulty? difficulty;

  final int solves;

  /// Solves with no mistakes and no hints.
  final int cleanSolves;

  /// Null on an all-difficulties row -- see [LeaderboardSort].
  final int? bestMs;
  final int? averageMs;

  final int totalMistakes;
  final int totalHints;
  final DateTime? lastSolveAt;

  const GlobalLeaderboardEntry({
    required this.userId,
    required this.username,
    required this.difficulty,
    required this.solves,
    required this.cleanSolves,
    required this.bestMs,
    required this.averageMs,
    required this.totalMistakes,
    required this.totalHints,
    required this.lastSolveAt,
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

  /// Aggregate standings across every puzzle played.
  ///
  /// [difficulty] null means all difficulties, which excludes the time-based
  /// sorts. [minSolves] guards the average-time ranking, where one lucky fast
  /// solve would otherwise top the board.
  Future<List<GlobalLeaderboardEntry>> globalLeaderboard({
    Difficulty? difficulty,
    LeaderboardSort sort = LeaderboardSort.bestTime,
    int minSolves = 1,
    int limit = 50,
  });
}
