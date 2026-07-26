import '../../engine/engine.dart';

class GameSaveData {
  final Puzzle puzzle;
  final List<int> userValues;
  final List<int> notes;
  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;

  const GameSaveData({
    required this.puzzle,
    required this.userValues,
    required this.notes,
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
  });
}

/// Seam a future cloud-backed implementation plugs into -- everything else
/// in the app only ever talks to this interface, never to Hive directly.
abstract class PuzzleRepository {
  Future<Puzzle> nextPuzzle(Difficulty difficulty);
  Future<Puzzle> dailyPuzzle(Difficulty difficulty, DateTime date);

  /// Regenerates one exact puzzle. Backs shared challenge links: the seed is
  /// the puzzle, so two people get identical boards with nothing transmitted.
  Future<Puzzle> puzzleForSeed(Difficulty difficulty, int seed);
  Future<void> saveInProgress(GameSaveData data);
  Future<GameSaveData?> loadInProgress(Difficulty difficulty);
  Future<void> clearInProgress(Difficulty difficulty);
}
