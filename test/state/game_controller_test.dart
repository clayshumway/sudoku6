import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sudoku6/data/repositories/puzzle_repository.dart';
import 'package:sudoku6/data/repositories/stats_repository.dart';
import 'package:sudoku6/engine/engine.dart';
import 'package:sudoku6/state/game_controller.dart';
import 'package:sudoku6/state/repository_providers.dart';

class _MockPuzzleRepository extends Mock implements PuzzleRepository {}

class _MockStatsRepository extends Mock implements StatsRepository {}

void main() {
  late _MockPuzzleRepository puzzleRepository;
  late _MockStatsRepository statsRepository;
  late ProviderContainer container;
  late Puzzle testPuzzle;

  setUpAll(() {
    final fallbackPuzzle =
        PuzzleGenerator().generate(difficulty: Difficulty.easy, seed: 0);
    registerFallbackValue(GameSaveData(
      puzzle: fallbackPuzzle,
      userValues: fallbackPuzzle.givens.cells,
      notes: List<int>.filled(cellCount, 0),
      elapsedSeconds: 0,
      mistakes: 0,
      hintsUsed: 0,
    ));
    registerFallbackValue(StatsRecord(
      difficulty: Difficulty.easy,
      seed: 0,
      elapsedSeconds: 0,
      mistakes: 0,
      hintsUsed: 0,
      completedAt: DateTime(2026),
    ));
    registerFallbackValue(Difficulty.easy);
  });

  setUp(() {
    testPuzzle = PuzzleGenerator().generate(difficulty: Difficulty.easy, seed: 5);
    puzzleRepository = _MockPuzzleRepository();
    statsRepository = _MockStatsRepository();
    when(() => puzzleRepository.nextPuzzle(any())).thenAnswer((_) async => testPuzzle);
    when(() => puzzleRepository.saveInProgress(any())).thenAnswer((_) async {});
    when(() => puzzleRepository.clearInProgress(any())).thenAnswer((_) async {});
    when(() => statsRepository.recordCompletion(any())).thenAnswer((_) async {});

    container = ProviderContainer(overrides: [
      puzzleRepositoryProvider.overrideWithValue(puzzleRepository),
      statsRepositoryProvider.overrideWithValue(statsRepository),
    ]);
    addTearDown(container.dispose);
  });

  test('startNewGame populates state from the repository puzzle', () async {
    final controller = container.read(gameControllerProvider.notifier);
    await controller.startNewGame(Difficulty.easy);

    final state = container.read(gameControllerProvider);
    expect(state, isNotNull);
    expect(state!.puzzle.seed, testPuzzle.seed);
    expect(state.values, testPuzzle.givens.cells);
  });

  test('placeDigit fills a cell, tracks mistakes, and persists', () async {
    final controller = container.read(gameControllerProvider.notifier);
    await controller.startNewGame(Difficulty.easy);

    final emptyCell =
        List<int>.generate(cellCount, (i) => i).firstWhere((i) => testPuzzle.givens[i] == 0);
    final correctDigit = testPuzzle.solution[emptyCell];
    final wrongDigit = correctDigit == 6 ? 1 : correctDigit + 1;

    controller.selectCell(emptyCell);
    controller.placeDigit(wrongDigit);

    var state = container.read(gameControllerProvider)!;
    expect(state.values[emptyCell], wrongDigit);
    expect(state.mistakes, 1);
    expect(state.incorrectCells.contains(emptyCell), isTrue);

    controller.placeDigit(correctDigit);
    state = container.read(gameControllerProvider)!;
    expect(state.values[emptyCell], correctDigit);
    expect(state.incorrectCells.contains(emptyCell), isFalse);

    verify(() => puzzleRepository.saveInProgress(any())).called(greaterThan(0));
  });

  test('undo reverts the last move', () async {
    final controller = container.read(gameControllerProvider.notifier);
    await controller.startNewGame(Difficulty.easy);

    final emptyCell =
        List<int>.generate(cellCount, (i) => i).firstWhere((i) => testPuzzle.givens[i] == 0);
    controller.selectCell(emptyCell);
    controller.placeDigit(1);
    expect(container.read(gameControllerProvider)!.values[emptyCell], 1);

    controller.undo();
    expect(container.read(gameControllerProvider)!.values[emptyCell], 0);
  });

  test('completing the puzzle records stats and clears the saved game', () async {
    final controller = container.read(gameControllerProvider.notifier);
    await controller.startNewGame(Difficulty.easy);

    final values = List<int>.from(testPuzzle.solution.cells);
    for (var i = 0; i < cellCount; i++) {
      if (testPuzzle.givens[i] == 0) {
        controller.selectCell(i);
        controller.placeDigit(values[i]);
      }
    }

    await Future<void>.delayed(Duration.zero);
    verify(() => statsRepository.recordCompletion(any())).called(1);
    verify(() => puzzleRepository.clearInProgress(Difficulty.easy)).called(1);
  });
}
