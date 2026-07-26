import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../engine/engine.dart';
import '../../../../state/game_controller.dart';
import '../../../../state/game_state.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/palette.dart';

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
    final palette = context.palette;
    final isGiven = state.puzzle.givens[index] != 0;
    final value = state.values[index];
    final isSelected = state.selectedCell == index;
    final isPeer = !isSelected &&
        state.selectedCell != null &&
        peersOf(state.selectedCell!).contains(index);
    final isIncorrect = state.incorrectCells.contains(index);
    final isHint = state.activeHint?.cellIndex == index;
    final isFilled = value != 0;

    // Background precedence: feedback states (hint, mistake) win over the
    // digit's own color, since they carry information the player needs now.
    // Otherwise a filled cell always shows its digit fill at full strength --
    // selection and peer state are layered on top rather than replacing it,
    // so the color coding stays readable everywhere on the board.
    final Color background;
    if (isHint) {
      background = palette.hintCell;
    } else if (isIncorrect) {
      background = palette.errorCell;
    } else if (isFilled) {
      background = palette.fillFor(value);
    } else if (isSelected) {
      background = palette.selectedCell;
    } else if (isPeer) {
      background = palette.peerCell;
    } else {
      background = palette.surface;
    }

    final Color textColor;
    if (isIncorrect) {
      textColor = palette.errorText;
    } else if (isFilled && !isHint) {
      textColor = palette.textOn(value);
    } else {
      textColor = isGiven ? palette.givenText : palette.userText;
    }

    return GestureDetector(
      onTap: () => ref.read(gameControllerProvider.notifier).selectCell(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              border: Border(
                top: BorderSide(
                  color: row % 2 == 0 ? palette.boxLine : palette.gridLine,
                  width: row % 2 == 0 ? 2 : 0.5,
                ),
                left: BorderSide(
                  color: col % 3 == 0 ? palette.boxLine : palette.gridLine,
                  width: col % 3 == 0 ? 2 : 0.5,
                ),
                right: BorderSide(
                  color: col == gridSize - 1 ? palette.boxLine : palette.gridLine,
                  width: col == gridSize - 1 ? 2 : 0.5,
                ),
                bottom: BorderSide(
                  color: row == gridSize - 1 ? palette.boxLine : palette.gridLine,
                  width: row == gridSize - 1 ? 2 : 0.5,
                ),
              ),
            ),
            child: Center(
              child: isFilled
                  ? Text(
                      '$value',
                      style: (isGiven
                              ? AppTextStyles.givenDigit
                              : AppTextStyles.userDigit)
                          .copyWith(color: textColor),
                    )
                  : _NotesGrid(bitmask: state.notes[index], color: palette.noteText),
            ),
          ),
          // Peer scrim: keeps the row/col/box hint visible on filled cells
          // without muddying the digit color underneath.
          if (isPeer && isFilled)
            IgnorePointer(
              child: ColoredBox(color: palette.peerScrim),
            ),
          // Selection is a ring, not a fill swap, for the same reason.
          // On a filled cell the ring borrows that digit's text color: the
          // palette's own ring color can collide with a same-hue fill (a cyan
          // ring vanishes on a cyan cell), whereas every text/fill pair is
          // already contrast-checked.
          if (isSelected)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isFilled && !isHint && !isIncorrect
                        ? palette.textOn(value)
                        : palette.selectionRing,
                    width: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  final int bitmask;
  final Color color;

  const _NotesGrid({required this.bitmask, required this.color});

  @override
  Widget build(BuildContext context) {
    if (bitmask == 0) return const SizedBox.shrink();
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
                      style: AppTextStyles.noteDigit.copyWith(color: color),
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
