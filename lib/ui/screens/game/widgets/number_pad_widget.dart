import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../engine/engine.dart';
import '../../../../state/game_controller.dart';
import '../../../../state/game_state.dart';
import '../../../theme/palette.dart';

class NumberPadWidget extends ConsumerWidget {
  final GameState state;

  const NumberPadWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final placedCorrectly = List<int>.filled(7, 0);
    for (var i = 0; i < cellCount; i++) {
      final v = state.values[i];
      if (v != 0 && v == state.puzzle.solution[i]) placedCorrectly[v]++;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(6, (i) {
          final digit = i + 1;
          final used = placedCorrectly[digit] >= 6;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AspectRatio(
                aspectRatio: 1,
                // Each key carries its digit's own color so the pad reads as a
                // legend for the board's color coding.
                child: OutlinedButton(
                  onPressed: used
                      ? null
                      : () => ref.read(gameControllerProvider.notifier).placeDigit(digit),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: used ? null : palette.fillFor(digit),
                    foregroundColor: used ? null : palette.textOn(digit),
                    disabledBackgroundColor: palette.surface,
                    disabledForegroundColor: palette.noteText,
                    side: BorderSide(
                      color: used ? palette.gridLine : palette.fillFor(digit),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    '$digit',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
