import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../engine/models/difficulty.dart';
import '../../../state/competition_provider.dart';
import '../../../state/game_controller.dart';
import '../../../utils/difficulty_label.dart';
import '../../routing/app_router.dart';
import '../../theme/palette.dart';
import '../../widgets/page_body.dart';
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
  bool _pauseBusy = false;

  /// Pausing a competition round has to reach the server: the recorded time is
  /// computed there, so stopping only the on-screen clock would leave the real
  /// time climbing behind a frozen display. The local pause is applied only
  /// once the server has accepted it, so a failed call can't quietly cost
  /// someone the round.
  Future<void> _togglePause() async {
    final state = ref.read(gameControllerProvider);
    if (state == null || state.isComplete || _pauseBusy) return;
    final controller = ref.read(gameControllerProvider.notifier);
    final pausing = !state.isPaused;

    if (!widget.isCompetitionRound) {
      pausing ? controller.pause() : controller.unpause();
      return;
    }

    setState(() => _pauseBusy = true);
    try {
      final repo = ref.read(competitionRepositoryProvider);
      if (pausing) {
        await repo?.pauseRound(
            competitionId: widget.competitionId!,
            roundNumber: widget.roundNumber!);
        controller.pause();
      } else {
        await repo?.resumeRound(
            competitionId: widget.competitionId!,
            roundNumber: widget.roundNumber!);
        controller.unpause();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pausing
                ? "Couldn't pause — your clock is still running."
                : "Couldn't resume. Check your connection."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pauseBusy = false);
    }
  }

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
    // The round was *pushed* from the competition screen, so pop back to it.
    // Replacing instead stacked a fresh copy per round, which made the back
    // button appear to loop on the same screen forever.
    if (context.canPop()) {
      context.pop();
    } else {
      // Deep-linked straight into a round: nothing underneath to pop to.
      context.go('${AppRoutes.competition}/$id');
    }
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
      appBar: AppBar(
        title: Text(difficultyLabel(widget.difficulty)),
        actions: [
          IconButton(
            onPressed: state.isComplete || _pauseBusy ? null : _togglePause,
            icon: _pauseBusy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(state.isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded),
            tooltip: state.isPaused ? 'Resume' : 'Pause',
          ),
        ],
      ),
      body: SafeArea(
        child: PageBody(
          maxWidth: 520,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TimerWidget(seconds: state.elapsedSeconds),
                    MistakeCounterWidget(mistakes: state.mistakes),
                  ],
                ),
              ),
              // Paused replaces the board rather than covering it. An overlay
              // would still leave the puzzle on screen to study, which would
              // make pausing a way to buy thinking time for free.
              if (state.isPaused)
                Expanded(child: _PausedPanel(onResume: _togglePause))
              else ...[
                Expanded(
                  // Biased above center: dead-centering the board in the
                  // leftover space read as a large arbitrary gap under the
                  // timer on tall phones.
                  child: Align(
                    alignment: const Alignment(0, -0.55),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SudokuGridWidget(state: state),
                    ),
                  ),
                ),
                NumberPadWidget(state: state),
                GameToolbar(state: state),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PausedPanel extends StatelessWidget {
  final VoidCallback onResume;

  const _PausedPanel({required this.onResume});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_outline, size: 64, color: palette.primary),
            const SizedBox(height: 16),
            Text('Paused', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'The clock is stopped and the board is hidden.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.noteText),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text('Resume'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
