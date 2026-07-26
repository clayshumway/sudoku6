import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../state/auth_provider.dart';
import '../../../utils/difficulty_label.dart';
import '../../../utils/share_text.dart';
import '../../routing/app_router.dart';
import '../../theme/palette.dart';
import 'game_summary.dart';
import 'widgets/win_animation.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final GameSummary summary;

  const ResultsScreen({super.key, required this.summary});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
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

  String _buildText() => buildShareText(
        difficulty: widget.summary.difficulty,
        seed: widget.summary.seed,
        elapsedSeconds: widget.summary.elapsedSeconds,
        mistakes: widget.summary.mistakes,
        hintsUsed: widget.summary.hintsUsed,
        givens: widget.summary.givens,
      );

  Future<void> _share() async {
    final text = _buildText();
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      // Desktop/web without a share sheet: fall back to the clipboard so the
      // button always does something useful.
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Result copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final palette = context.palette;
    final signedIn = ref.watch(isSignedInProvider);
    final authAvailable = ref.watch(authAvailableProvider);

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Solved!',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(difficultyLabel(summary.difficulty),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 24),
                    Text(
                      formatMinutesSeconds(summary.elapsedSeconds),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Mistakes: ${summary.mistakes}  •  Hints: ${summary.hintsUsed}'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.ios_share, size: 18),
                        label: const Text('Share result'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (authAvailable)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '${AppRoutes.leaderboard}/${summary.difficulty.name}/${summary.seed}',
                          ),
                          icon: const Icon(Icons.emoji_events_outlined,
                              size: 18),
                          label: const Text('Leaderboard'),
                        ),
                      ),
                    if (authAvailable && !signedIn) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to put this time on the board.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 12, color: palette.noteText),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.pushReplacement(
                          '${AppRoutes.game}/${summary.difficulty.name}',
                        ),
                        child: const Text('Play Again'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
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
