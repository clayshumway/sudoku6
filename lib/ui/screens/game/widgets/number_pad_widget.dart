import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../engine/engine.dart';
import '../../../../state/game_controller.dart';
import '../../../../state/game_state.dart';

class NumberPadWidget extends ConsumerWidget {
  final GameState state;

  const NumberPadWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: OutlinedButton(
                  onPressed: used
                      ? null
                      : () => ref.read(gameControllerProvider.notifier).placeDigit(digit),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    '$digit',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
