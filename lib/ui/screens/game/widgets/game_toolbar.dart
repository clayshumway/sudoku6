import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../state/game_controller.dart';
import '../../../../state/game_state.dart';
import 'hint_sheet.dart';

class GameToolbar extends ConsumerWidget {
  final GameState state;

  const GameToolbar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarButton(
            icon: Icons.undo,
            label: 'Undo',
            onPressed: state.undoStack.isEmpty ? null : controller.undo,
          ),
          _ToolbarButton(
            icon: Icons.backspace_outlined,
            label: 'Erase',
            onPressed: state.selectedCell == null ? null : controller.eraseCell,
          ),
          _ToolbarButton(
            icon: Icons.edit_outlined,
            label: 'Notes',
            selected: state.notesMode,
            onPressed: controller.toggleNotesMode,
          ),
          _ToolbarButton(
            icon: Icons.lightbulb_outline,
            label: 'Hint',
            onPressed: () => _showHint(context, ref),
          ),
        ],
      ),
    );
  }

  void _showHint(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    controller.useHint();
    final hint = ref.read(gameControllerProvider)?.activeHint;
    if (hint == null) return;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => HintSheet(
        step: hint,
        onApply: () {
          controller.applyHint();
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : null;
    return TextButton(
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
