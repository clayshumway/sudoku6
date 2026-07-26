import '../../models/grid.dart';
import '../candidate_grid.dart';
import 'technique.dart';

class HiddenSingleTechnique implements Technique {
  @override
  String get name => 'Hidden Single';
  @override
  int get weight => 1;

  @override
  bool tryApply(CandidateGrid grid, List<SolveStep> log) {
    for (final unit in allUnits) {
      for (var digit = 1; digit <= 6; digit++) {
        final bit = digitBit(digit);
        int? foundCell;
        var count = 0;
        for (final cell in unit) {
          if (grid.values[cell] == 0 && grid.candidates[cell] & bit != 0) {
            count++;
            foundCell = cell;
            if (count > 1) break;
          }
        }
        if (count == 1 && foundCell != null) {
          grid.place(foundCell, digit);
          log.add(SolveStep(
            technique: name,
            cellIndex: foundCell,
            digit: digit,
            explanation:
                'This is the only cell in its row, column, or box that can hold this digit.',
          ));
          return true;
        }
      }
    }
    return false;
  }
}
