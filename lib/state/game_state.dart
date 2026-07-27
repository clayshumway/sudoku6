import '../data/repositories/puzzle_repository.dart';
import '../engine/engine.dart';

class GameState {
  final Puzzle puzzle;
  final List<int> values;
  final List<int> notes;
  final List<Move> undoStack;
  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;
  final int? selectedCell;
  final bool notesMode;
  final SolveStep? activeHint;
  final Set<int> incorrectCells;

  /// Stops the clock and hides the board. Not persisted: a game reopened from
  /// a save starts running, since a pause you can't see isn't a pause.
  final bool isPaused;

  const GameState({
    required this.puzzle,
    required this.values,
    required this.notes,
    required this.undoStack,
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
    this.selectedCell,
    this.notesMode = false,
    this.activeHint,
    this.incorrectCells = const {},
    this.isPaused = false,
  });

  bool get isComplete {
    for (var i = 0; i < cellCount; i++) {
      if (values[i] != puzzle.solution[i]) return false;
    }
    return true;
  }

  factory GameState.fromPuzzle(Puzzle puzzle) {
    return GameState(
      puzzle: puzzle,
      values: List<int>.from(puzzle.givens.cells),
      notes: List<int>.filled(cellCount, 0),
      undoStack: const [],
      elapsedSeconds: 0,
      mistakes: 0,
      hintsUsed: 0,
    );
  }

  factory GameState.fromSave(GameSaveData data) {
    return GameState(
      puzzle: data.puzzle,
      values: List<int>.from(data.userValues),
      notes: List<int>.from(data.notes),
      undoStack: const [],
      elapsedSeconds: data.elapsedSeconds,
      mistakes: data.mistakes,
      hintsUsed: data.hintsUsed,
    );
  }

  GameState copyWith({
    List<int>? values,
    List<int>? notes,
    List<Move>? undoStack,
    int? elapsedSeconds,
    int? mistakes,
    int? hintsUsed,
    int? selectedCell,
    bool clearSelectedCell = false,
    bool? notesMode,
    SolveStep? activeHint,
    bool clearActiveHint = false,
    Set<int>? incorrectCells,
    bool? isPaused,
  }) {
    return GameState(
      puzzle: puzzle,
      values: values ?? this.values,
      notes: notes ?? this.notes,
      undoStack: undoStack ?? this.undoStack,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      selectedCell:
          clearSelectedCell ? null : (selectedCell ?? this.selectedCell),
      notesMode: notesMode ?? this.notesMode,
      activeHint: clearActiveHint ? null : (activeHint ?? this.activeHint),
      incorrectCells: incorrectCells ?? this.incorrectCells,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
