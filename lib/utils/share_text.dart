import '../engine/engine.dart';
import 'difficulty_label.dart';

/// Emoji square per digit, matching the board's colour coding
/// (1 yellow, 2 red, 3 blue, 4 green, 5 purple, 6 orange).
const _digitSquares = {
  1: '🟨',
  2: '🟥',
  3: '🟦',
  4: '🟩',
  5: '🟪',
  6: '🟧',
};

/// Wordle-style result text.
///
/// The grid shows **which cells were clues vs. which you filled in** -- never
/// the digits. Anyone playing the same seed already sees the clue positions on
/// their own board, so this reveals nothing they don't have, while still
/// conveying how much of the puzzle you actually did.
///
/// Colours only appear in the legend line, so the grid can't leak answers even
/// though it echoes the board's palette.
String buildShareText({
  required Difficulty difficulty,
  required int seed,
  required int elapsedSeconds,
  required int mistakes,
  required int hintsUsed,
  required List<int> givens,
  String? username,
  String siteUrl = 'https://s6.clayshumway.com',
}) {
  final stars = '★' * (kTierConfigs[difficulty]?.stars ?? 1);
  final buffer = StringBuffer()
    ..writeln('Sudoku 6 — ${difficultyLabel(difficulty)} $stars')
    ..writeln(
        '⏱ ${formatMinutesSeconds(elapsedSeconds)}  ·  ❌ $mistakes  ·  💡 $hintsUsed')
    ..writeln();

  for (var row = 0; row < gridSize; row++) {
    final line = StringBuffer();
    for (var col = 0; col < gridSize; col++) {
      final given = givens[row * gridSize + col] != 0;
      // ⬛ clue you were given, ⬜ cell you worked out.
      line.write(given ? '⬛' : '⬜');
    }
    buffer.writeln(line.toString());
  }

  buffer
    ..writeln()
    ..writeln('$siteUrl/#/p/${difficulty.name}-$seed');

  return buffer.toString().trimRight();
}

/// Short label for the shared puzzle, e.g. "hard-4821093".
String puzzleCode(Difficulty difficulty, int seed) =>
    '${difficulty.name}-$seed';

/// Emoji legend for the digit colours, used in-app rather than in share text.
String digitLegend() => [
      for (var d = 1; d <= 6; d++) '${_digitSquares[d]}$d',
    ].join(' ');
