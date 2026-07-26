import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku6/engine/engine.dart';

void main() {
  group('box math', () {
    test('every row/col maps to the expected box (3 box-rows x 2 box-cols)',
        () {
      final expected = <String, int>{
        '0,0': 0, '0,2': 0, '1,0': 0, '1,2': 0,
        '0,3': 1, '0,5': 1, '1,3': 1, '1,5': 1,
        '2,0': 2, '2,2': 2, '3,0': 2, '3,2': 2,
        '2,3': 3, '2,5': 3, '3,3': 3, '3,5': 3,
        '4,0': 4, '4,2': 4, '5,0': 4, '5,2': 4,
        '4,3': 5, '4,5': 5, '5,3': 5, '5,5': 5,
      };
      for (final entry in expected.entries) {
        final parts = entry.key.split(',');
        final row = int.parse(parts[0]);
        final col = int.parse(parts[1]);
        expect(boxIndexOf(row, col), entry.value,
            reason: 'row=$row col=$col');
      }
    });

    test('all 36 cells partition into 6 boxes of 6 cells each', () {
      final counts = List<int>.filled(6, 0);
      for (var i = 0; i < cellCount; i++) {
        counts[boxOfIndex(i)]++;
      }
      expect(counts, everyElement(6));
    });
  });

  group('units', () {
    test('rowUnits, colUnits, boxUnits each have 6 units of 6 cells', () {
      expect(rowUnits.length, 6);
      expect(colUnits.length, 6);
      expect(boxUnits.length, 6);
      for (final unit in allUnits) {
        expect(unit.length, 6);
        expect(unit.toSet().length, 6);
      }
    });
  });

  group('peersOf', () {
    test(
        'a cell has 12 distinct peers (5 row + 5 col + 2 remaining box cells, '
        'since a 2x3 box only contributes 2 cells not already in the row/col)',
        () {
      for (var i = 0; i < cellCount; i++) {
        final peers = peersOf(i);
        expect(peers.toSet().length, 12, reason: 'index=$i');
        expect(peers.contains(i), isFalse);
      }
    });
  });
}
