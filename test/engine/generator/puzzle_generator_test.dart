import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku6/engine/engine.dart';

void main() {
  final generator = PuzzleGenerator();
  final solver = BacktrackingSolver();
  final humanSolver = HumanSolver();

  for (final difficulty in Difficulty.values) {
    group('$difficulty', () {
      final config = kTierConfigs[difficulty]!;

      test('50 generated puzzles are all valid, unique, and on-tier', () {
        for (var seed = 0; seed < 50; seed++) {
          final puzzle = generator.generate(difficulty: difficulty, seed: seed);

          expect(solver.hasUniqueSolution(puzzle.givens), isTrue,
              reason: 'seed=$seed');
          expect(puzzle.clueCount, inInclusiveRange(config.minClues, config.maxClues),
              reason: 'seed=$seed');

          final report = humanSolver.rate(puzzle.givens);
          expect(report.requiresGuessing, isFalse, reason: 'seed=$seed');
          expect(report.maxWeight, lessThanOrEqualTo(config.ceilingWeight),
              reason: 'seed=$seed');
          expect(report.solvedGrid, puzzle.solution, reason: 'seed=$seed');

          for (var i = 0; i < cellCount; i++) {
            final given = puzzle.givens[i];
            if (given != 0) {
              expect(given, puzzle.solution[i], reason: 'seed=$seed cell=$i');
            }
          }
        }
      });

      test('same seed reproduces an identical puzzle', () {
        final a = generator.generate(difficulty: difficulty, seed: 777);
        final b = generator.generate(difficulty: difficulty, seed: 777);
        expect(a.givens, b.givens);
        expect(a.solution, b.solution);
      });
    });
  }
}
