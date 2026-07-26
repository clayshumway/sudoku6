import 'dart:math';

import '../models/grid.dart';

class FullGridGenerator {
  Grid generate(Random rng) {
    final values = List<int>.filled(cellCount, 0);

    bool fill(int index) {
      if (index == cellCount) return true;
      final row = rowOf(index);
      final col = colOf(index);
      final box = boxOfIndex(index);
      final digits = [1, 2, 3, 4, 5, 6]..shuffle(rng);
      for (final d in digits) {
        if (_isValid(values, row, col, box, d)) {
          values[index] = d;
          if (fill(index + 1)) return true;
          values[index] = 0;
        }
      }
      return false;
    }

    fill(0);
    return Grid(values);
  }

  bool _isValid(List<int> values, int row, int col, int box, int digit) {
    for (var c = 0; c < gridSize; c++) {
      if (values[cellIndex(row, c)] == digit) return false;
    }
    for (var r = 0; r < gridSize; r++) {
      if (values[cellIndex(r, col)] == digit) return false;
    }
    for (var i = 0; i < cellCount; i++) {
      if (boxOfIndex(i) == box && values[i] == digit) return false;
    }
    return true;
  }
}
