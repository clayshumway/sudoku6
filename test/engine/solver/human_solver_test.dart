import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku6/engine/engine.dart';

void main() {
  final humanSolver = HumanSolver();
  final generator = PuzzleGenerator();

  test('rate() fully solves an easy puzzle without guessing', () {
    final puzzle = generator.generate(difficulty: Difficulty.easy, seed: 1);
    final report = humanSolver.rate(puzzle.givens);
    expect(report.requiresGuessing, isFalse);
    expect(report.solvedGrid, puzzle.solution);
  });

  test('nextHint returns a real placement consistent with the solution', () {
    final puzzle = generator.generate(difficulty: Difficulty.medium, seed: 2);
    final hint = humanSolver.nextHint(puzzle.givens);
    expect(hint, isNotNull);
    expect(hint!.digit, puzzle.solution[hint.cellIndex]);
  });

  test('nextHint returns null for an already-solved board', () {
    final puzzle = generator.generate(difficulty: Difficulty.easy, seed: 3);
    expect(humanSolver.nextHint(puzzle.solution), isNull);
  });
}
