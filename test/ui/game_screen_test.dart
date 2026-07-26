import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku6/data/repositories/puzzle_repository.dart';
import 'package:sudoku6/engine/engine.dart';
import 'package:sudoku6/state/repository_providers.dart';
import 'package:sudoku6/ui/screens/game/game_screen.dart';
import 'package:sudoku6/ui/screens/game/widgets/number_pad_widget.dart';
import 'package:sudoku6/ui/screens/game/widgets/sudoku_cell_widget.dart';

/// Synchronous stand-in so the widget test never depends on the real
/// generator's isolate hop (compute()), which doesn't play well with
/// widget-test fake-async pumping.
class _FakePuzzleRepository implements PuzzleRepository {
  final Puzzle puzzle = PuzzleGenerator().generate(difficulty: Difficulty.easy, seed: 1);

  @override
  Future<Puzzle> nextPuzzle(Difficulty difficulty) async => puzzle;

  @override
  Future<Puzzle> dailyPuzzle(Difficulty difficulty, DateTime date) async => puzzle;

  @override
  Future<void> saveInProgress(GameSaveData data) async {}

  @override
  Future<GameSaveData?> loadInProgress(Difficulty difficulty) async => null;

  @override
  Future<void> clearInProgress(Difficulty difficulty) async {}
}

void main() {
  testWidgets('GameScreen renders a 36-cell grid and a 6-button number pad',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          puzzleRepositoryProvider.overrideWithValue(_FakePuzzleRepository()),
        ],
        child: const MaterialApp(
          home: GameScreen(difficulty: Difficulty.easy),
        ),
      ),
    );

    // The game controller starts a 1s periodic ticker once a puzzle loads,
    // so pumpAndSettle would never quiesce -- pump explicitly instead.
    await tester.pump();
    await tester.pump();

    expect(find.byType(SudokuCellWidget), findsNWidgets(36));
    expect(find.byType(NumberPadWidget), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('6'), findsWidgets);
  });
}
