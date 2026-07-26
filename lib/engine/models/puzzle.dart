import 'difficulty.dart';
import 'grid.dart';

class Puzzle {
  final Grid givens;
  final Grid solution;
  final int seed;
  final Difficulty difficulty;
  final int clueCount;

  const Puzzle({
    required this.givens,
    required this.solution,
    required this.seed,
    required this.difficulty,
    required this.clueCount,
  });
}
