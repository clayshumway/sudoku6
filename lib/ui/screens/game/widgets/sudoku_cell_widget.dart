import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../engine/engine.dart';
import '../../../../state/game_controller.dart';
import '../../../../state/game_state.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SudokuCellWidget extends ConsumerWidget {
  final GameState state;
  final int index;
  final int row;
  final int col;

  const SudokuCellWidget({
    super.key,
    required this.state,
    required this.index,
    required this.row,
    required this.col,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGiven = state.puzzle.givens[index] != 0;
    final value = state.values[index];
    final isSelected = state.selectedCell == index;
    final isPeer = !isSelected &&
        state.selectedCell != null &&
        peersOf(state.selectedCell!).contains(index);
    final isIncorrect = state.incorrectCells.contains(index);
    final isHint = state.activeHint?.cellIndex == index;

    final baseSurface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    Color background;
    if (isHint) {
      background = Theme.of(context).colorScheme.primaryContainer;
    } else if (isIncorrect) {
      background = isDark ? AppColors.darkErrorCell : AppColors.lightErrorCell;
    } else if (value != 0) {
      // Tint by digit (1=yellow..6=orange); selection/peer nudge the
      // intensity rather than replacing the color, so the digit's color
      // stays identifiable everywhere on the board.
      final tintOpacity = isSelected ? 0.60 : (isPeer ? 0.40 : (isDark ? 0.45 : 0.20));
      background = Color.alphaBlend(
          AppColors.digitColor(value).withValues(alpha: tintOpacity), baseSurface);
    } else if (isSelected) {
      background =
          isDark ? AppColors.darkSelectedCell : AppColors.lightSelectedCell;
    } else if (isPeer) {
      background = isDark ? AppColors.darkPeerCell : AppColors.lightPeerCell;
    } else {
      background = baseSurface;
    }

    final thinColor = isDark ? AppColors.darkGridLine : AppColors.lightGridLine;
    final thickColor = isDark ? AppColors.darkBoxLine : AppColors.lightBoxLine;

    return GestureDetector(
      onTap: () => ref.read(gameControllerProvider.notifier).selectCell(index),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(
            top: BorderSide(
              color: row % 2 == 0 ? thickColor : thinColor,
              width: row % 2 == 0 ? 2 : 0.5,
            ),
            left: BorderSide(
              color: col % 3 == 0 ? thickColor : thinColor,
              width: col % 3 == 0 ? 2 : 0.5,
            ),
            right: BorderSide(
              color: col == gridSize - 1 ? thickColor : thinColor,
              width: col == gridSize - 1 ? 2 : 0.5,
            ),
            bottom: BorderSide(
              color: row == gridSize - 1 ? thickColor : thinColor,
              width: row == gridSize - 1 ? 2 : 0.5,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: value != 0
            ? Text(
                '$value',
                style: (isGiven ? AppTextStyles.givenDigit : AppTextStyles.userDigit)
                    .copyWith(
                  color: isIncorrect
                      ? (isDark ? AppColors.darkErrorText : AppColors.lightErrorText)
                      : (isGiven
                          ? (isDark ? AppColors.darkGivenText : AppColors.lightGivenText)
                          : (isDark ? AppColors.darkUserText : AppColors.lightUserText)),
                ),
              )
            : _NotesGrid(bitmask: state.notes[index]),
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  final int bitmask;

  const _NotesGrid({required this.bitmask});

  @override
  Widget build(BuildContext context) {
    if (bitmask == 0) return const SizedBox.shrink();
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(2, (r) {
          return Expanded(
            child: Row(
              children: List.generate(3, (c) {
                final digit = r * 3 + c + 1;
                final present = bitmask & digitBit(digit) != 0;
                return Expanded(
                  child: Center(
                    child: Text(
                      present ? '$digit' : '',
                      style: AppTextStyles.noteDigit.copyWith(color: onSurfaceVariant),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
