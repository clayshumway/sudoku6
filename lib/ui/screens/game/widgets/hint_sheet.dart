import 'package:flutter/material.dart';

import '../../../../engine/engine.dart';

class HintSheet extends StatelessWidget {
  final SolveStep step;
  final VoidCallback onApply;

  const HintSheet({super.key, required this.step, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step.technique, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(step.explanation),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onApply, child: const Text('Fill it in')),
            ),
          ],
        ),
      ),
    );
  }
}
