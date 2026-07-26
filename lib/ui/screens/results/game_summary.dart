import '../../../engine/models/difficulty.dart';

class GameSummary {
  final Difficulty difficulty;
  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;

  const GameSummary({
    required this.difficulty,
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
  });
}
