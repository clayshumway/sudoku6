import 'dart:math';

import '../models/difficulty.dart';
import '../models/grid.dart';
import '../models/puzzle.dart';
import '../solver/backtracking_solver.dart';
import '../solver/human_solver.dart';
import 'full_grid_generator.dart';

class PuzzleGenerator {
  final BacktrackingSolver _solver = BacktrackingSolver();
  final HumanSolver _humanSolver = HumanSolver();
  final FullGridGenerator _fullGridGenerator = FullGridGenerator();

  Puzzle generate({required Difficulty difficulty, int? seed}) {
    final usedSeed = seed ?? DateTime.now().microsecondsSinceEpoch;
    final config = kTierConfigs[difficulty]!;

    for (var fullGridAttempt = 0; fullGridAttempt < 200; fullGridAttempt++) {
      final rng = Random(usedSeed + fullGridAttempt);
      final fullGrid = _fullGridGenerator.generate(rng);

      for (var digAttempt = 0; digAttempt < 50; digAttempt++) {
        final result = _digSymmetric(fullGrid, rng, config);
        if (result != null) {
          return _toPuzzle(result, fullGrid, usedSeed, difficulty);
        }
      }

      final asymmetric = _digAsymmetric(fullGrid, rng, config);
      if (asymmetric != null) {
        return _toPuzzle(asymmetric, fullGrid, usedSeed, difficulty);
      }
    }

    throw StateError(
        'Failed to generate a $difficulty puzzle after exhausting attempts.');
  }

  Puzzle _toPuzzle(
      Grid givens, Grid solution, int seed, Difficulty difficulty) {
    return Puzzle(
      givens: givens,
      solution: solution,
      seed: seed,
      difficulty: difficulty,
      clueCount: givens.clueCount,
    );
  }

  Grid? _digSymmetric(Grid fullGrid, Random rng, TierConfig config) {
    final pairs = <List<int>>[];
    final seen = <int>{};
    for (var i = 0; i < cellCount; i++) {
      if (seen.contains(i)) continue;
      final partner = (cellCount - 1) - i;
      seen
        ..add(i)
        ..add(partner);
      pairs.add([i, partner]);
    }
    pairs.shuffle(rng);

    final values = List<int>.from(fullGrid.cells);
    var clueCount = cellCount;

    for (final pair in pairs) {
      if (clueCount - 2 < config.minClues) break;
      final a = pair[0], b = pair[1];
      final savedA = values[a], savedB = values[b];
      values[a] = 0;
      values[b] = 0;

      if (_solver.countSolutions(Grid(values), limit: 2) != 1) {
        values[a] = savedA;
        values[b] = savedB;
        continue;
      }

      clueCount -= 2;
      if (clueCount <= config.maxClues) {
        final result = _rateAndCheck(Grid(List<int>.from(values)), config);
        if (result != null) return result;
      }
    }

    return null;
  }

  Grid? _digAsymmetric(Grid fullGrid, Random rng, TierConfig config) {
    final order = List<int>.generate(cellCount, (i) => i)..shuffle(rng);
    final values = List<int>.from(fullGrid.cells);
    var clueCount = cellCount;

    for (final index in order) {
      if (clueCount - 1 < config.minClues) break;
      final saved = values[index];
      values[index] = 0;

      if (_solver.countSolutions(Grid(values), limit: 2) != 1) {
        values[index] = saved;
        continue;
      }

      clueCount -= 1;
      if (clueCount <= config.maxClues) {
        final result = _rateAndCheck(Grid(List<int>.from(values)), config);
        if (result != null) return result;
      }
    }

    return null;
  }

  Grid? _rateAndCheck(Grid puzzle, TierConfig config) {
    final report = _humanSolver.rate(puzzle);
    if (report.requiresGuessing) return null;
    if (report.maxWeight > config.ceilingWeight) return null;
    final clueCount = puzzle.clueCount;
    if (clueCount < config.minClues || clueCount > config.maxClues) {
      return null;
    }
    return puzzle;
  }
}
