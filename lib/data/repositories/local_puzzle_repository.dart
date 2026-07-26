import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../engine/engine.dart';
import '../hive_boxes.dart';
import '../models/puzzle_state_hive.dart';
import 'puzzle_repository.dart';

class _GenerateArgs {
  final Difficulty difficulty;
  final int? seed;
  const _GenerateArgs(this.difficulty, this.seed);
}

Puzzle _generateInIsolate(_GenerateArgs args) {
  return PuzzleGenerator().generate(difficulty: args.difficulty, seed: args.seed);
}

/// Deterministic per-day seed so every install gets the same puzzle for a
/// given (date, tier) -- no caching needed, it's cheaply reproducible.
int dailySeedFor(DateTime date, Difficulty difficulty) {
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  final epochDay = utcDate.difference(DateTime.utc(1970, 1, 1)).inDays;
  return epochDay * 10 + difficulty.index;
}

/// Hive-backed puzzle source. Generation runs via [compute] so a fresh
/// puzzle never jank the UI thread on native platforms (compute degrades
/// to a synchronous call on web, which is fine given sub-100ms generation).
class LocalPuzzleRepository implements PuzzleRepository {
  Box<PuzzleStateHive> get _stateBox =>
      Hive.box<PuzzleStateHive>(HiveBoxes.puzzleStates);

  @override
  Future<Puzzle> nextPuzzle(Difficulty difficulty) {
    return compute(_generateInIsolate, _GenerateArgs(difficulty, null));
  }

  @override
  Future<Puzzle> dailyPuzzle(Difficulty difficulty, DateTime date) {
    final seed = dailySeedFor(date, difficulty);
    return compute(_generateInIsolate, _GenerateArgs(difficulty, seed));
  }

  @override
  Future<Puzzle> puzzleForSeed(Difficulty difficulty, int seed) {
    return compute(_generateInIsolate, _GenerateArgs(difficulty, seed));
  }

  @override
  Future<void> saveInProgress(GameSaveData data) async {
    final hive = PuzzleStateHive(
      difficulty: data.puzzle.difficulty.name,
      seed: data.puzzle.seed,
      givens: data.puzzle.givens.cells,
      solution: data.puzzle.solution.cells,
      userValues: data.userValues,
      notes: data.notes,
      elapsedSeconds: data.elapsedSeconds,
      mistakes: data.mistakes,
      hintsUsed: data.hintsUsed,
    );
    await _stateBox.put(data.puzzle.difficulty.name, hive);
  }

  @override
  Future<GameSaveData?> loadInProgress(Difficulty difficulty) async {
    final hive = _stateBox.get(difficulty.name);
    if (hive == null) return null;

    final puzzle = Puzzle(
      givens: Grid(List<int>.from(hive.givens)),
      solution: Grid(List<int>.from(hive.solution)),
      seed: hive.seed,
      difficulty: difficulty,
      clueCount: Grid(List<int>.from(hive.givens)).clueCount,
    );

    return GameSaveData(
      puzzle: puzzle,
      userValues: List<int>.from(hive.userValues),
      notes: List<int>.from(hive.notes),
      elapsedSeconds: hive.elapsedSeconds,
      mistakes: hive.mistakes,
      hintsUsed: hive.hintsUsed,
    );
  }

  @override
  Future<void> clearInProgress(Difficulty difficulty) async {
    await _stateBox.delete(difficulty.name);
  }
}
