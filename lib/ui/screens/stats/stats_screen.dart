import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/stats_provider.dart';
import '../../../utils/difficulty_label.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(statsHistoryProvider);
    final streakAsync = ref.watch(currentStreakProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: streakAsync.when(
              data: (streak) => Text(
                'Current streak: $streak day${streak == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Center(child: Text('No completed puzzles yet.'));
                }
                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, i) {
                    final record = history[i];
                    return ListTile(
                      title: Text(difficultyLabel(record.difficulty)),
                      subtitle: Text(
                        '${record.completedAt.month}/${record.completedAt.day}/${record.completedAt.year}',
                      ),
                      trailing: Text(formatMinutesSeconds(record.elapsedSeconds)),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
