import '../../models/grid.dart';
import '../candidate_grid.dart';
import 'technique.dart';

/// Covers both directions of box/line interaction: a digit confined to one
/// row or column within a box (pointing pair), and a digit confined to one
/// box within a row or column (box-line reduction).
class PointingPairTechnique implements Technique {
  @override
  String get name => 'Pointing Pair';
  @override
  int get weight => 4;

  @override
  bool tryApply(CandidateGrid grid, List<SolveStep> log) {
    for (final box in boxUnits) {
      for (var digit = 1; digit <= 6; digit++) {
        final bit = digitBit(digit);
        final cells = box
            .where((c) => grid.values[c] == 0 && grid.candidates[c] & bit != 0)
            .toList();
        if (cells.length < 2) continue;

        final rows = cells.map(rowOf).toSet();
        if (rows.length == 1) {
          if (_eliminateFromUnit(grid, rowUnits[rows.first], bit, box.toSet())) {
            log.add(SolveStep(
              technique: name,
              cellIndex: cells.first,
              digit: -1,
              explanation:
                  'This digit is confined to one row within the box, so it can be removed from the rest of that row.',
            ));
            return true;
          }
        }

        final cols = cells.map(colOf).toSet();
        if (cols.length == 1) {
          if (_eliminateFromUnit(grid, colUnits[cols.first], bit, box.toSet())) {
            log.add(SolveStep(
              technique: name,
              cellIndex: cells.first,
              digit: -1,
              explanation:
                  'This digit is confined to one column within the box, so it can be removed from the rest of that column.',
            ));
            return true;
          }
        }
      }
    }

    for (final line in [...rowUnits, ...colUnits]) {
      for (var digit = 1; digit <= 6; digit++) {
        final bit = digitBit(digit);
        final cells = line
            .where((c) => grid.values[c] == 0 && grid.candidates[c] & bit != 0)
            .toList();
        if (cells.length < 2) continue;

        final boxes = cells.map(boxOfIndex).toSet();
        if (boxes.length == 1) {
          if (_eliminateFromUnit(
              grid, boxUnits[boxes.first], bit, line.toSet())) {
            log.add(SolveStep(
              technique: name,
              cellIndex: cells.first,
              digit: -1,
              explanation:
                  'This digit is confined to one box within the row or column, so it can be removed from the rest of that box.',
            ));
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _eliminateFromUnit(
      CandidateGrid grid, List<int> unit, int bit, Set<int> exclude) {
    var changed = false;
    for (final cell in unit) {
      if (exclude.contains(cell)) continue;
      if (grid.values[cell] == 0 && grid.candidates[cell] & bit != 0) {
        grid.eliminate(cell, bit);
        changed = true;
      }
    }
    return changed;
  }
}
