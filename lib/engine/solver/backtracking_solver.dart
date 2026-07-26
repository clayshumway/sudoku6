import '../models/grid.dart';

/// Pure uniqueness oracle: counts solutions up to [limit] using
/// bitmask row/col/box tracking and minimum-remaining-values branching.
/// Never used to derive hints -- see HumanSolver for that.
class BacktrackingSolver {
  int countSolutions(Grid puzzle, {int limit = 2}) {
    final values = List<int>.from(puzzle.cells);
    final rowMask = List<int>.filled(gridSize, 0);
    final colMask = List<int>.filled(gridSize, 0);
    final boxMask = List<int>.filled(6, 0);

    for (var i = 0; i < cellCount; i++) {
      final v = values[i];
      if (v == 0) continue;
      final bit = digitBit(v);
      rowMask[rowOf(i)] |= bit;
      colMask[colOf(i)] |= bit;
      boxMask[boxOfIndex(i)] |= bit;
    }

    var solutions = 0;

    bool solve() {
      var bestIndex = -1;
      var bestMask = 0;
      var bestCount = 7;
      for (var i = 0; i < cellCount; i++) {
        if (values[i] != 0) continue;
        final mask = allDigitsMask &
            ~(rowMask[rowOf(i)] | colMask[colOf(i)] | boxMask[boxOfIndex(i)]);
        final count = popCount(mask);
        if (count == 0) return false;
        if (count < bestCount) {
          bestCount = count;
          bestIndex = i;
          bestMask = mask;
          if (count == 1) break;
        }
      }

      if (bestIndex == -1) {
        solutions++;
        return solutions >= limit;
      }

      final r = rowOf(bestIndex);
      final c = colOf(bestIndex);
      final b = boxOfIndex(bestIndex);
      for (final d in digitsInMask(bestMask)) {
        final bit = digitBit(d);
        values[bestIndex] = d;
        rowMask[r] |= bit;
        colMask[c] |= bit;
        boxMask[b] |= bit;

        final stop = solve();

        values[bestIndex] = 0;
        rowMask[r] &= ~bit;
        colMask[c] &= ~bit;
        boxMask[b] &= ~bit;

        if (stop) return true;
      }
      return false;
    }

    solve();
    return solutions;
  }

  bool hasUniqueSolution(Grid puzzle) => countSolutions(puzzle, limit: 2) == 1;
}
