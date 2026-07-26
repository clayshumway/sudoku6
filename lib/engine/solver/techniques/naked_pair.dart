import '../../models/grid.dart';
import '../candidate_grid.dart';
import 'technique.dart';

class NakedPairTechnique implements Technique {
  @override
  String get name => 'Naked Pair';
  @override
  int get weight => 3;

  @override
  bool tryApply(CandidateGrid grid, List<SolveStep> log) {
    for (final unit in allUnits) {
      final unsolved = unit.where((c) => grid.values[c] == 0).toList();
      for (var a = 0; a < unsolved.length; a++) {
        final cellA = unsolved[a];
        final maskA = grid.candidates[cellA];
        if (popCount(maskA) != 2) continue;
        for (var b = a + 1; b < unsolved.length; b++) {
          final cellB = unsolved[b];
          if (grid.candidates[cellB] != maskA) continue;

          var changed = false;
          for (final other in unsolved) {
            if (other == cellA || other == cellB) continue;
            if (grid.candidates[other] & maskA != 0) {
              grid.eliminate(other, maskA);
              changed = true;
            }
          }
          if (changed) {
            log.add(SolveStep(
              technique: name,
              cellIndex: cellA,
              digit: -1,
              explanation:
                  'Two cells in this unit share the same two candidates, so those digits can be removed from the rest of the unit.',
            ));
            return true;
          }
        }
      }
    }
    return false;
  }
}
