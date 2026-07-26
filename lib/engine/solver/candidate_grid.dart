import '../models/grid.dart';

/// Mutable solving scratchpad: tracks placed values plus, for each unsolved
/// cell, the bitmask of digits still possible there. Techniques mutate this
/// directly via [place] and [eliminate].
class CandidateGrid {
  final List<int> values;
  final List<int> candidates;

  CandidateGrid._(this.values, this.candidates);

  factory CandidateGrid.fromGivens(Grid givens) {
    final values = List<int>.from(givens.cells);
    final candidates = List<int>.filled(cellCount, 0);
    final grid = CandidateGrid._(values, candidates);
    for (var i = 0; i < cellCount; i++) {
      if (values[i] == 0) {
        candidates[i] = grid._computeCandidates(i);
      }
    }
    return grid;
  }

  int _computeCandidates(int index) {
    var mask = allDigitsMask;
    for (final peer in peersOf(index)) {
      if (values[peer] != 0) {
        mask &= ~digitBit(values[peer]);
      }
    }
    return mask;
  }

  bool get isSolved => values.every((v) => v != 0);

  void place(int index, int digit) {
    values[index] = digit;
    candidates[index] = 0;
    final bit = digitBit(digit);
    for (final peer in peersOf(index)) {
      if (values[peer] == 0) {
        candidates[peer] &= ~bit;
      }
    }
  }

  void eliminate(int index, int mask) {
    candidates[index] &= ~mask;
  }

  Grid toGrid() => Grid(List<int>.from(values));
}
