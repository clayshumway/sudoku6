import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../engine/models/difficulty.dart';
import '../../../state/competition_provider.dart';
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

  /// Set when arriving from a shared challenge link, pinning the exact puzzle.
  final int? seed;

  /// Set when this is a competition round. Completion then submits through
  /// the server-timed RPC instead of the normal solo results flow.
  final String? competitionId;
  final int? roundNumber;

  const GameScreen({
    super.key,
    required this.difficulty,
    this.daily = false,
    this.seed,
    this.competitionId,
    this.roundNumber,
  });

  bool get isCompetitionRound => competitionId != null && roundNumber != null;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final controller = ref.read(gameControllerProvider.notifier);
      if (widget.seed != null) {
        controller.startSeededPuzzle(widget.difficulty, widget.seed!);
      } else if (widget.daily) {
        controller.startDailyPuzzle(widget.difficulty, DateTime.now());
      } else {
        controller.resume(widget.difficulty);
      }
    });
  }

  /// Reports a finished competition round. The elapsed time comes back from
  /// the server (computed from its own clocks), so nothing here can influence
  /// the recorded result beyond mistakes and hints.
  Future<void> _submitCompetitionRound(int mistakes, int hintsUsed) async {
    final repo = ref.read(competitionRepositoryProvider);
    final id = widget.competitionId!;
    try {
      await repo?.finishRound(
        competitionId: id,
        roundNumber: widget.roundNumber!,
        mistakes: mistakes,
        hintsUsed: hintsUsed,
      );
    } catch (_) {
      // Fall through to the competition screen either way -- it re-reads
      // from the server, so a failed submit shows as "not finished" rather
      // than stranding the player here.
    }
    if (!mounted) return;
    ref.invalidate(competitionViewProvider(id));
    context.pushReplacement('${AppRoutes.competition}/$id');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);

    ref.listen(gameControllerProvider, (previous, next) {
      final wasComplete = previous?.isComplete ?? false;
      if (next != null && next.isComplete && !wasComplete) {
        if (widget.isCompetitionRound) {
          _submitCompetitionRound(next.mistakes, next.hintsUsed);
          return;
        }
        final summary = GameSummary(
          difficulty: next.puzzle.difficulty,
          elapsedSeconds: next.elapsedSeconds,
          mistakes: next.mistakes,
          hintsUsed: next.hintsUsed,
          seed: next.puzzle.seed,
          givens: List<int>.unmodifiable(next.puzzle.givens.cells),
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
