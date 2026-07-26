import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/solves_repository.dart';
import '../../../engine/models/difficulty.dart';
import '../../../state/auth_provider.dart';
import '../../../utils/difficulty_label.dart';
import '../../theme/palette.dart';

class LeaderboardScreen extends ConsumerWidget {
  final Difficulty difficulty;
  final int seed;

  const LeaderboardScreen({
    super.key,
    required this.difficulty,
    required this.seed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final async = ref.watch(
      leaderboardProvider((difficulty: difficulty, seed: seed)),
    );
    final myId = ref.watch(authUserProvider).value?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${difficultyLabel(difficulty)} · puzzle $seed',
              style: TextStyle(fontSize: 13, color: palette.noteText),
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(
          icon: Icons.cloud_off,
          title: "Couldn't load the leaderboard",
          detail: 'Check your connection and try again.',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const _Message(
              icon: Icons.emoji_events_outlined,
              title: 'No times yet',
              detail: 'Be the first to finish this puzzle.',
            );
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = entries[i];
              final isMe = e.userId == myId;
              return _Row(entry: e, rank: i + 1, highlight: isMe);
            },
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool highlight;

  const _Row({
    required this.entry,
    required this.rank,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Medals for the top three, plain numerals after -- enough to make the
    // top of the board feel like something without turning it into noise.
    const medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Container(
      color: highlight ? palette.selectedCell : null,
      child: ListTile(
        leading: SizedBox(
          width: 32,
          child: Text(
            medals[rank] ?? '$rank',
            style: TextStyle(
              fontSize: medals.containsKey(rank) ? 20 : 15,
              fontWeight: FontWeight.w600,
              color: palette.noteText,
            ),
          ),
        ),
        title: Text(
          entry.username,
          style: TextStyle(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${entry.mistakes} mistakes · ${entry.hintsUsed} hints',
          style: TextStyle(fontSize: 12, color: palette.noteText),
        ),
        trailing: Text(
          formatMinutesSeconds(entry.elapsedMs ~/ 1000),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: palette.noteText),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.noteText),
            ),
          ],
        ),
      ),
    );
  }
}
