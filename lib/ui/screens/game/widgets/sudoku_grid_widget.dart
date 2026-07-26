import 'package:flutter/material.dart';

import '../../../../engine/engine.dart';
import '../../../../state/game_state.dart';
import 'sudoku_cell_widget.dart';

class SudokuGridWidget extends StatelessWidget {
  final GameState state;

  const SudokuGridWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(gridSize, (row) {
            return Expanded(
              child: Row(
                children: List.generate(gridSize, (col) {
                  final index = cellIndex(row, col);
                  return Expanded(
                    child: SudokuCellWidget(
                      state: state,
                      index: index,
                      row: row,
                      col: col,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}
