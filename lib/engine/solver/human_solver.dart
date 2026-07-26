import '../models/grid.dart';
import 'candidate_grid.dart';
import 'techniques/hidden_pair.dart';
import 'techniques/hidden_single.dart';
import 'techniques/naked_pair.dart';
import 'techniques/naked_single.dart';
import 'techniques/pointing_pair.dart';
import 'techniques/technique.dart';

class DifficultyReport {
  final int maxWeight;
  final Set<String> techniquesUsed;
  final List<SolveStep> steps;
  final bool requiresGuessing;
  final Grid? solvedGrid;

  const DifficultyReport({
    required this.maxWeight,
    required this.techniquesUsed,
    required this.steps,
    required this.requiresGuessing,
    required this.solvedGrid,
  });
}

/// Ranked-technique solver: doubles as the difficulty rater used by
/// PuzzleGenerator and as the source of truth for in-app hints, so a hint
/// is always a real logical step rather than a raw answer reveal.
class HumanSolver {
  final List<Technique> techniques = [
    NakedSingleTechnique(),
    HiddenSingleTechnique(),
    NakedPairTechnique(),
    PointingPairTechnique(),
    HiddenPairTechnique(),
  ];

  DifficultyReport rate(Grid givens) {
    final grid = CandidateGrid.fromGivens(givens);
    final steps = <SolveStep>[];
    final used = <String>{};
    var maxWeight = 0;

    while (!grid.isSolved) {
      var applied = false;
      for (final technique in techniques) {
        if (technique.tryApply(grid, steps)) {
          applied = true;
          used.add(technique.name);
          if (technique.weight > maxWeight) maxWeight = technique.weight;
          break;
        }
      }
      if (!applied) {
        return DifficultyReport(
          maxWeight: maxWeight,
          techniquesUsed: used,
          steps: steps,
          requiresGuessing: true,
          solvedGrid: null,
        );
      }
    }

    return DifficultyReport(
      maxWeight: maxWeight,
      techniquesUsed: used,
      steps: steps,
      requiresGuessing: false,
      solvedGrid: grid.toGrid(),
    );
  }

  /// Applies elimination-only techniques silently until a placement
  /// technique fires, then returns that placement as the hint. Returns
  /// null if the board is already solved or if no technique applies
  /// (i.e. the next step would require guessing).
  SolveStep? nextHint(Grid currentBoard) {
    final grid = CandidateGrid.fromGivens(currentBoard);
    if (grid.isSolved) return null;
    final steps = <SolveStep>[];

    while (!grid.isSolved) {
      var applied = false;
      for (final technique in techniques) {
        if (technique.tryApply(grid, steps)) {
          applied = true;
          final lastStep = steps.last;
          if (lastStep.digit != -1) return lastStep;
          break;
        }
      }
      if (!applied) return null;
    }
    return null;
  }
}
