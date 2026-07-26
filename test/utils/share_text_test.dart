import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku6/engine/engine.dart';
import 'package:sudoku6/utils/share_text.dart';

void main() {
  final puzzle = PuzzleGenerator().generate(difficulty: Difficulty.hard, seed: 4821093);

  String build() => buildShareText(
        difficulty: Difficulty.hard,
        seed: 4821093,
        elapsedSeconds: 154,
        mistakes: 1,
        hintsUsed: 2,
        givens: puzzle.givens.cells,
      );

  test('never leaks a digit from the solution', () {
    final text = build();
    // The grid must carry no digits at all. The only numerals allowed are in
    // the stats line and the seed in the link, so strip those first.
    final gridOnly = text
        .split('\n')
        .where((l) => l.contains('⬛') || l.contains('⬜'))
        .join();

    expect(gridOnly, isNotEmpty, reason: 'expected a rendered grid');
    expect(RegExp(r'[1-6]').hasMatch(gridOnly), isFalse,
        reason: 'share grid must not contain puzzle digits');
  });

  test('renders a full 6x6 grid of given/filled squares', () {
    final rows = build()
        .split('\n')
        .where((l) => l.contains('⬛') || l.contains('⬜'))
        .toList();

    expect(rows.length, gridSize);
    for (final row in rows) {
      final squares = row.replaceAll('⬛', '.').replaceAll('⬜', '.');
      expect(squares.length, gridSize);
    }
  });

  test('marks givens and filled cells to match the puzzle', () {
    final rows = build()
        .split('\n')
        .where((l) => l.contains('⬛') || l.contains('⬜'))
        .toList();

    for (var r = 0; r < gridSize; r++) {
      final cells = rows[r].runes.map(String.fromCharCode).toList();
      for (var c = 0; c < gridSize; c++) {
        final isGiven = puzzle.givens.cells[r * gridSize + c] != 0;
        expect(cells[c], isGiven ? '⬛' : '⬜',
            reason: 'cell ($r,$c) should reflect whether it was a clue');
      }
    }
  });

  test('includes a replayable link carrying tier and seed', () {
    expect(build(), contains('/#/p/hard-4821093'));
  });

  test('puzzleCode round-trips tier and seed', () {
    expect(puzzleCode(Difficulty.expert, 42), 'expert-42');
  });
}
