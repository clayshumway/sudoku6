import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/solves_repository.dart';
import '../../../engine/models/difficulty.dart';
import '../../../state/auth_provider.dart';
import '../../../utils/difficulty_label.dart';
import '../../theme/palette.dart';
import '../../widgets/page_body.dart';

/// Standings across every puzzle played, as opposed to the per-puzzle board.
///
/// Difficulty and sort are independent controls, with one dependency between
/// them: the time-based sorts are meaningless across difficulties (a "best
/// time" over everything is just someone's quickest Easy), so choosing All
/// difficulties falls back to a count-based sort.
class GlobalLeaderboardScreen extends ConsumerStatefulWidget {
  const GlobalLeaderboardScreen({super.key});

  @override
  ConsumerState<GlobalLeaderboardScreen> createState() =>
      _GlobalLeaderboardScreenState();
}

class _GlobalLeaderboardScreenState
    extends ConsumerState<GlobalLeaderboardScreen> {
  // Opens on All / Most solved rather than a specific tier: any single
  // difficulty can legitimately have no solves yet, and landing on an empty
  // board makes a populated leaderboard look broken. All difficulties has
  // rows whenever anyone has ever finished a puzzle.
  Difficulty? _difficulty;
  LeaderboardSort _sort = LeaderboardSort.mostSolves;

  void _setDifficulty(Difficulty? d) {
    setState(() {
      _difficulty = d;
      if (d == null && _sort.needsDifficulty) {
        _sort = LeaderboardSort.mostSolves;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final async = ref.watch(
      globalLeaderboardProvider((difficulty: _difficulty, sort: _sort)),
    );
    final myId = ref.watch(authUserProvider).value?.id;
    final sorts = _difficulty == null
        ? LeaderboardSort.values.where((s) => !s.needsDifficulty).toList()
        : LeaderboardSort.values;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: PageBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Difficulty',
                      child: DropdownButton<Difficulty?>(
                        isExpanded: true,
                        value: _difficulty,
                        underline: const SizedBox.shrink(),
                        onChanged: _setDifficulty,
                        items: [
                          const DropdownMenuItem<Difficulty?>(
                            value: null,
                            child: Text('All'),
                          ),
                          for (final d in Difficulty.values)
                            DropdownMenuItem<Difficulty?>(
                              value: d,
                              child: Text(difficultyLabel(d)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      label: 'Sort by',
                      child: DropdownButton<LeaderboardSort>(
                        isExpanded: true,
                        value: _sort,
                        underline: const SizedBox.shrink(),
                        onChanged: (s) =>
                            setState(() => _sort = s ?? _sort),
                        items: [
                          for (final s in sorts)
                            DropdownMenuItem(value: s, child: Text(s.label)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_sort == LeaderboardSort.averageTime)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  'Players with at least 3 solves.',
                  style: TextStyle(fontSize: 12, color: palette.noteText),
                ),
              ),
            if (_difficulty == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  'Times need a difficulty — a best time across all of them is '
                  'just the easiest puzzle.',
                  style: TextStyle(fontSize: 12, color: palette.noteText),
                ),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => _Message(
                  icon: Icons.cloud_off,
                  title: "Couldn't load the leaderboard",
                  detail: 'Check your connection and try again.',
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const _Message(
                      icon: Icons.emoji_events_outlined,
                      title: 'Nothing here yet',
                      detail: 'Finish a puzzle while signed in to appear.',
                    );
                  }
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => _Row(
                      entry: entries[i],
                      rank: i + 1,
                      sort: _sort,
                      highlight: entries[i].userId == myId,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: palette.noteText)),
        child,
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final GlobalLeaderboardEntry entry;
  final int rank;
  final LeaderboardSort sort;
  final bool highlight;

  const _Row({
    required this.entry,
    required this.rank,
    required this.sort,
    required this.highlight,
  });

  /// The number the current sort ranks on, shown large on the right so the
  /// column you're sorting by is the one you can actually read.
  String get _primary => switch (sort) {
        LeaderboardSort.bestTime =>
          entry.bestMs == null ? '—' : formatMinutesSeconds(entry.bestMs! ~/ 1000),
        LeaderboardSort.averageTime => entry.averageMs == null
            ? '—'
            : formatMinutesSeconds(entry.averageMs! ~/ 1000),
        LeaderboardSort.mostSolves => '${entry.solves}',
        LeaderboardSort.cleanSolves => '${entry.cleanSolves}',
      };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    final parts = <String>[
      '${entry.solves} solve${entry.solves == 1 ? "" : "s"}',
      if (sort != LeaderboardSort.cleanSolves)
        '${entry.cleanSolves} clean'
      else if (entry.bestMs != null)
        'best ${formatMinutesSeconds(entry.bestMs! ~/ 1000)}',
      '${entry.totalMistakes} mistakes',
    ];

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
          parts.join(' · '),
          style: TextStyle(fontSize: 12, color: palette.noteText),
        ),
        trailing: Text(
          _primary,
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
