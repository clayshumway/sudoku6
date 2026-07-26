import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../engine/models/difficulty.dart';
import '../../../../state/game_controller.dart';
import '../../../../state/stats_provider.dart';
import '../../../../utils/difficulty_label.dart';
import '../../../routing/app_router.dart';

class DifficultyCard extends ConsumerWidget {
  final Difficulty difficulty;

  const DifficultyCard({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = kTierConfigs[difficulty]!;
    final saved = ref.watch(savedGameProvider(difficulty));
    final hasSave = saved.maybeWhen(data: (d) => d != null, orElse: () => false);
    final bestTime = ref.watch(bestTimeProvider(difficulty));

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('${AppRoutes.game}/${difficulty.name}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(difficultyLabel(difficulty),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < config.stars ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      }),
                    ),
                    bestTime.maybeWhen(
                      data: (record) => record == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Best: ${formatMinutesSeconds(record.elapsedSeconds)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              if (hasSave)
                const Chip(label: Text('Continue'))
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
