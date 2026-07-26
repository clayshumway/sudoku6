import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku6/engine/engine.dart';

void main() {
  final solver = BacktrackingSolver();

  test('an empty grid has more than one solution', () {
    expect(solver.countSolutions(Grid.empty(), limit: 2), 2);
  });

  test('a fully solved grid has exactly one solution', () {
    final fullGrid = FullGridGenerator().generate(_seededRandom());
    expect(solver.countSolutions(fullGrid, limit: 2), 1);
    expect(solver.hasUniqueSolution(fullGrid), isTrue);
  });

  test('a grid missing one cell (with a unique fill) has one solution', () {
    final fullGrid = FullGridGenerator().generate(_seededRandom());
    final cells = List<int>.from(fullGrid.cells);
    cells[0] = 0;
    expect(solver.countSolutions(Grid(cells), limit: 2), 1);
  });

  test('a hand-built non-unique puzzle reports 2+ solutions', () {
    // Two rows fully given, the rest empty: many valid completions exist.
    final cells = List<int>.filled(cellCount, 0);
    const row0 = [1, 2, 3, 4, 5, 6];
    const row1 = [4, 5, 6, 1, 2, 3];
    for (var c = 0; c < 6; c++) {
      cells[cellIndex(0, c)] = row0[c];
      cells[cellIndex(1, c)] = row1[c];
    }
    expect(solver.countSolutions(Grid(cells), limit: 2), 2);
  });
}

Random _seededRandom() => Random(42);
