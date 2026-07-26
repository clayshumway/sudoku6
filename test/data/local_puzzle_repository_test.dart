import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sudoku6/data/hive_boxes.dart';
import 'package:sudoku6/data/models/puzzle_state_hive.dart';
import 'package:sudoku6/data/models/settings_hive.dart';
import 'package:sudoku6/data/models/stats_entry_hive.dart';
import 'package:sudoku6/data/repositories/local_puzzle_repository.dart';
import 'package:sudoku6/data/repositories/puzzle_repository.dart';
import 'package:sudoku6/engine/engine.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sudoku6_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PuzzleStateHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StatsEntryHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SettingsHiveAdapter());
    }
    await Hive.openBox<PuzzleStateHive>(HiveBoxes.puzzleStates);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('a saved in-progress game round-trips through Hive', () async {
    final repo = LocalPuzzleRepository();
    final puzzle = PuzzleGenerator().generate(difficulty: Difficulty.easy, seed: 10);

    final userValues = List<int>.from(puzzle.givens.cells);
    userValues[0] = puzzle.solution[0] == 0 ? 1 : puzzle.solution[0];

    await repo.saveInProgress(GameSaveData(
      puzzle: puzzle,
      userValues: userValues,
      notes: List<int>.filled(cellCount, 0),
      elapsedSeconds: 42,
      mistakes: 2,
      hintsUsed: 1,
    ));

    final loaded = await repo.loadInProgress(Difficulty.easy);
    expect(loaded, isNotNull);
    expect(loaded!.puzzle.seed, puzzle.seed);
    expect(loaded.userValues, userValues);
    expect(loaded.elapsedSeconds, 42);
    expect(loaded.mistakes, 2);
    expect(loaded.hintsUsed, 1);
  });

  test('loadInProgress returns null when nothing is saved', () async {
    final repo = LocalPuzzleRepository();
    expect(await repo.loadInProgress(Difficulty.medium), isNull);
  });

  test('clearInProgress removes the saved game', () async {
    final repo = LocalPuzzleRepository();
    final puzzle = PuzzleGenerator().generate(difficulty: Difficulty.hard, seed: 11);
    await repo.saveInProgress(GameSaveData(
      puzzle: puzzle,
      userValues: List<int>.from(puzzle.givens.cells),
      notes: List<int>.filled(cellCount, 0),
      elapsedSeconds: 0,
      mistakes: 0,
      hintsUsed: 0,
    ));
    await repo.clearInProgress(Difficulty.hard);
    expect(await repo.loadInProgress(Difficulty.hard), isNull);
  });

  test('dailySeedFor is stable for the same date and tier', () {
    final date = DateTime(2026, 7, 19);
    final a = dailySeedFor(date, Difficulty.expert);
    final b = dailySeedFor(date, Difficulty.expert);
    expect(a, b);
    final other = dailySeedFor(date, Difficulty.easy);
    expect(a, isNot(other));
  });
}
