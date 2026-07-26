import '../../../engine/models/difficulty.dart';

class GameSummary {
  final Difficulty difficulty;
  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;

  /// Identifies the exact puzzle. Combined with [difficulty] it regenerates
  /// the board byte-for-byte, which is what makes leaderboards and shareable
  /// challenge links possible without storing any grid.
  final int seed;

  /// The starting clues, 0 for empty. Used to render the share grid as
  /// "given vs. filled by you" without revealing any digits.
  final List<int> givens;

  const GameSummary({
    required this.difficulty,
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.seed,
    required this.givens,
  });
}
