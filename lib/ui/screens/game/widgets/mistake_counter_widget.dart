import 'package:flutter/material.dart';

class MistakeCounterWidget extends StatelessWidget {
  final int mistakes;

  const MistakeCounterWidget({super.key, required this.mistakes});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 18),
        const SizedBox(width: 4),
        Text('Mistakes: $mistakes'),
      ],
    );
  }
}
