import '../../models/grid.dart';
import '../candidate_grid.dart';
import 'technique.dart';

class NakedSingleTechnique implements Technique {
  @override
  String get name => 'Naked Single';
  @override
  int get weight => 0;

  @override
  bool tryApply(CandidateGrid grid, List<SolveStep> log) {
    for (var i = 0; i < cellCount; i++) {
      if (grid.values[i] != 0) continue;
      final mask = grid.candidates[i];
      if (popCount(mask) == 1) {
        final digit = digitsInMask(mask).first;
        grid.place(i, digit);
        log.add(SolveStep(
          technique: name,
          cellIndex: i,
          digit: digit,
          explanation: 'This cell has only one possible digit remaining.',
        ));
        return true;
      }
    }
    return false;
  }
}
