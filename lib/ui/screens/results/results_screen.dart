import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/difficulty_label.dart';
import '../../routing/app_router.dart';
import 'game_summary.dart';
import 'widgets/win_animation.dart';

class ResultsScreen extends StatefulWidget {
  final GameSummary summary;

  const ResultsScreen({super.key, required this.summary});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2))..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Solved!', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(difficultyLabel(summary.difficulty),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 24),
                    Text(
                      formatMinutesSeconds(summary.elapsedSeconds),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Mistakes: ${summary.mistakes}  •  Hints: ${summary.hintsUsed}'),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.go(AppRoutes.home),
                        child: const Text('Back to Home'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.pushReplacement(
                          '${AppRoutes.game}/${summary.difficulty.name}',
                        ),
                        child: const Text('Play Again'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          WinAnimation(controller: _confetti),
        ],
      ),
    );
  }
}
