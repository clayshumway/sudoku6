import '../../models/grid.dart';
import '../candidate_grid.dart';
import 'technique.dart';

class HiddenPairTechnique implements Technique {
  @override
  String get name => 'Hidden Pair';
  @override
  int get weight => 5;

  @override
  bool tryApply(CandidateGrid grid, List<SolveStep> log) {
    for (final unit in allUnits) {
      final unsolved = unit.where((c) => grid.values[c] == 0).toList();

      for (var d1 = 1; d1 <= 6; d1++) {
        final bit1 = digitBit(d1);
        final cellsWithD1 =
            unsolved.where((c) => grid.candidates[c] & bit1 != 0).toList();
        if (cellsWithD1.length != 2) continue;

        for (var d2 = d1 + 1; d2 <= 6; d2++) {
          final bit2 = digitBit(d2);
          final cellsWithD2 =
              unsolved.where((c) => grid.candidates[c] & bit2 != 0).toList();
          if (cellsWithD2.length != 2) continue;
          if (cellsWithD1[0] != cellsWithD2[0] ||
              cellsWithD1[1] != cellsWithD2[1]) {
            continue;
          }

          final pairMask = bit1 | bit2;
          var changed = false;
          for (final cell in cellsWithD1) {
            final extra = grid.candidates[cell] & ~pairMask;
            if (extra != 0) {
              grid.eliminate(cell, extra);
              changed = true;
            }
          }
          if (changed) {
            log.add(SolveStep(
              technique: name,
              cellIndex: cellsWithD1[0],
              digit: -1,
              explanation:
                  'Two digits only fit in the same two cells of this unit, so other candidates can be removed from those cells.',
            ));
            return true;
          }
        }
      }
    }
    return false;
  }
}
