import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/puzzle_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../engine/engine.dart';
import 'game_state.dart';
import 'repository_providers.dart';

class GameController extends Notifier<GameState?> {
  Timer? _ticker;
  final HumanSolver _humanSolver = HumanSolver();

  @override
  GameState? build() {
    ref.onDispose(() => _ticker?.cancel());
    return null;
  }

  /// Loads any in-progress save for this tier, or starts a fresh puzzle.
  Future<void> resume(Difficulty difficulty) async {
    final repo = ref.read(puzzleRepositoryProvider);
    final saved = await repo.loadInProgress(difficulty);
    state = saved != null ? GameState.fromSave(saved) : null;
    if (state == null) {
      await startNewGame(difficulty);
    } else {
      _startTicker();
    }
  }

  Future<void> startNewGame(Difficulty difficulty) async {
    final repo = ref.read(puzzleRepositoryProvider);
    final puzzle = await repo.nextPuzzle(difficulty);
    state = GameState.fromPuzzle(puzzle);
    _startTicker();
  }

  Future<void> startDailyPuzzle(Difficulty difficulty, DateTime date) async {
    final repo = ref.read(puzzleRepositoryProvider);
    final puzzle = await repo.dailyPuzzle(difficulty, date);
    state = GameState.fromPuzzle(puzzle);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current == null || current.isComplete) return;
      state = current.copyWith(elapsedSeconds: current.elapsedSeconds + 1);
    });
  }

  void selectCell(int index) {
    final current = state;
    if (current == null) return;
    if (current.puzzle.givens[index] != 0) return;
    state = current.copyWith(selectedCell: index, clearActiveHint: true);
  }

  void placeDigit(int digit) {
    final current = state;
    if (current == null || current.selectedCell == null) return;
    final index = current.selectedCell!;
    if (current.puzzle.givens[index] != 0) return;

    if (current.notesMode) {
      _toggleNote(current, index, digit);
      return;
    }

    final values = List<int>.from(current.values);
    final previousValue = values[index];
    final previousNotes = current.notes[index];
    values[index] = digit;

    final notes = List<int>.from(current.notes);
    notes[index] = 0;

    final move = Move(
      cellIndex: index,
      previousValue: previousValue,
      newValue: digit,
      previousNotes: previousNotes,
      newNotes: 0,
    );

    var mistakes = current.mistakes;
    final incorrect = Set<int>.from(current.incorrectCells);
    if (digit != current.puzzle.solution[index]) {
      mistakes++;
      incorrect.add(index);
    } else {
      incorrect.remove(index);
    }

    final next = current.copyWith(
      values: values,
      notes: notes,
      undoStack: [...current.undoStack, move],
      mistakes: mistakes,
      incorrectCells: incorrect,
      clearActiveHint: true,
    );
    state = next;

    if (next.isComplete) {
      unawaited(_onComplete(next));
    } else {
      unawaited(_persist(next));
    }
  }

  void _toggleNote(GameState current, int index, int digit) {
    final notes = List<int>.from(current.notes);
    final bit = digitBit(digit);
    final previousNotes = notes[index];
    notes[index] = notes[index] ^ bit;

    final move = Move(
      cellIndex: index,
      previousValue: current.values[index],
      newValue: current.values[index],
      previousNotes: previousNotes,
      newNotes: notes[index],
    );

    final next = current.copyWith(
      notes: notes,
      undoStack: [...current.undoStack, move],
    );
    state = next;
    unawaited(_persist(next));
  }

  void eraseCell() {
    final current = state;
    if (current == null || current.selectedCell == null) return;
    final index = current.selectedCell!;
    if (current.puzzle.givens[index] != 0) return;
    if (current.values[index] == 0 && current.notes[index] == 0) return;

    final values = List<int>.from(current.values);
    final notes = List<int>.from(current.notes);
    final move = Move(
      cellIndex: index,
      previousValue: values[index],
      newValue: 0,
      previousNotes: notes[index],
      newNotes: 0,
    );
    values[index] = 0;
    notes[index] = 0;

    final incorrect = Set<int>.from(current.incorrectCells)..remove(index);

    final next = current.copyWith(
      values: values,
      notes: notes,
      undoStack: [...current.undoStack, move],
      incorrectCells: incorrect,
      clearActiveHint: true,
    );
    state = next;
    unawaited(_persist(next));
  }

  void toggleNotesMode() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(notesMode: !current.notesMode);
  }

  void undo() {
    final current = state;
    if (current == null || current.undoStack.isEmpty) return;
    final stack = List<Move>.from(current.undoStack);
    final move = stack.removeLast();

    final values = List<int>.from(current.values);
    final notes = List<int>.from(current.notes);
    values[move.cellIndex] = move.previousValue;
    notes[move.cellIndex] = move.previousNotes;

    final incorrect = Set<int>.from(current.incorrectCells);
    if (move.previousValue != 0 &&
        move.previousValue != current.puzzle.solution[move.cellIndex]) {
      incorrect.add(move.cellIndex);
    } else {
      incorrect.remove(move.cellIndex);
    }

    final next = current.copyWith(
      values: values,
      notes: notes,
      undoStack: stack,
      incorrectCells: incorrect,
    );
    state = next;
    unawaited(_persist(next));
  }

  void useHint() {
    final current = state;
    if (current == null) return;
    final board = Grid(List<int>.from(current.values));
    final hint = _humanSolver.nextHint(board);
    if (hint == null) return;
    state = current.copyWith(
      activeHint: hint,
      hintsUsed: current.hintsUsed + 1,
      selectedCell: hint.cellIndex,
    );
  }

  void applyHint() {
    final current = state;
    if (current == null || current.activeHint == null) return;
    final digit = current.activeHint!.digit;
    selectCell(current.activeHint!.cellIndex);
    placeDigit(digit);
  }

  Future<void> _onComplete(GameState finished) async {
    _ticker?.cancel();
    final statsRepo = ref.read(statsRepositoryProvider);
    await statsRepo.recordCompletion(StatsRecord(
      difficulty: finished.puzzle.difficulty,
      seed: finished.puzzle.seed,
      elapsedSeconds: finished.elapsedSeconds,
      mistakes: finished.mistakes,
      hintsUsed: finished.hintsUsed,
      completedAt: DateTime.now(),
    ));
    final puzzleRepo = ref.read(puzzleRepositoryProvider);
    await puzzleRepo.clearInProgress(finished.puzzle.difficulty);
  }

  Future<void> _persist(GameState current) async {
    final repo = ref.read(puzzleRepositoryProvider);
    await repo.saveInProgress(GameSaveData(
      puzzle: current.puzzle,
      userValues: current.values,
      notes: current.notes,
      elapsedSeconds: current.elapsedSeconds,
      mistakes: current.mistakes,
      hintsUsed: current.hintsUsed,
    ));
  }
}

final gameControllerProvider =
    NotifierProvider<GameController, GameState?>(GameController.new);

final savedGameProvider =
    FutureProvider.autoDispose.family<GameSaveData?, Difficulty>((ref, difficulty) {
  return ref.watch(puzzleRepositoryProvider).loadInProgress(difficulty);
});
