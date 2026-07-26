import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../engine/models/difficulty.dart';
import '../../../state/game_controller.dart';
import '../../../utils/difficulty_label.dart';
import '../../routing/app_router.dart';
import '../results/game_summary.dart';
import 'widgets/game_toolbar.dart';
import 'widgets/mistake_counter_widget.dart';
import 'widgets/number_pad_widget.dart';
import 'widgets/sudoku_grid_widget.dart';
import 'widgets/timer_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  final Difficulty difficulty;
  final bool daily;

  const GameScreen({super.key, required this.difficulty, this.daily = false});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final controller = ref.read(gameControllerProvider.notifier);
      if (widget.daily) {
        controller.startDailyPuzzle(widget.difficulty, DateTime.now());
      } else {
        controller.resume(widget.difficulty);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);

    ref.listen(gameControllerProvider, (previous, next) {
      final wasComplete = previous?.isComplete ?? false;
      if (next != null && next.isComplete && !wasComplete) {
        final summary = GameSummary(
          difficulty: next.puzzle.difficulty,
          elapsedSeconds: next.elapsedSeconds,
          mistakes: next.mistakes,
          hintsUsed: next.hintsUsed,
        );
        context.pushReplacement(AppRoutes.results, extra: summary);
      }
    });

    if (state == null || state.puzzle.difficulty != widget.difficulty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(difficultyLabel(widget.difficulty))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TimerWidget(seconds: state.elapsedSeconds),
                  MistakeCounterWidget(mistakes: state.mistakes),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SudokuGridWidget(state: state),
                ),
              ),
            ),
            NumberPadWidget(state: state),
            GameToolbar(state: state),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
