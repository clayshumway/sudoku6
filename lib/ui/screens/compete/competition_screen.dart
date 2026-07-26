import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/repositories/competition_repository.dart';
import '../../../state/auth_provider.dart';
import '../../../state/competition_provider.dart';
import '../../../utils/difficulty_label.dart';
import '../../routing/app_router.dart';
import '../../theme/palette.dart';
import '../../widgets/page_body.dart';

class CompetitionScreen extends ConsumerStatefulWidget {
  final String competitionId;

  const CompetitionScreen({super.key, required this.competitionId});

  @override
  ConsumerState<CompetitionScreen> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends ConsumerState<CompetitionScreen> {
  bool _starting = false;
  bool _readying = false;
  bool _rematching = false;
  String? _error;

  /// One button, whatever the chain's state: the RPC walks to the newest
  /// competition in the rematch chain and either hands back the ongoing
  /// rematch to join or creates a fresh one from the finished tip. join() is
  /// idempotent, so creator and followers share this path.
  Future<void> _goToRematch(CompetitionView view) async {
    final repo = ref.read(competitionRepositoryProvider);
    if (repo == null) return;

    setState(() {
      _rematching = true;
      _error = null;
    });
    try {
      final code = await repo.rematch(widget.competitionId);
      final newId = await repo.join(code);
      // Fire the invite emails without blocking navigation. Server-side
      // bookkeeping makes repeat calls no-ops, so this is safe from every
      // player's button.
      unawaited(repo.notifyRematch(newId));
      if (!mounted) return;
      context.pushReplacement('${AppRoutes.competition}/$newId');
    } on CompetitionException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not start the rematch.');
    } finally {
      if (mounted) setState(() => _rematching = false);
    }
  }

  Future<void> _markReady() async {
    final repo = ref.read(competitionRepositoryProvider);
    if (repo == null) return;

    setState(() {
      _readying = true;
      _error = null;
    });
    try {
      await repo.markReady(widget.competitionId);
      // Realtime/polling would catch up anyway; invalidate for snappiness.
      ref.invalidate(competitionViewProvider(widget.competitionId));
    } on CompetitionException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not mark you ready.');
    } finally {
      if (mounted) setState(() => _readying = false);
    }
  }

  String _shareUrl(String code) => 'https://s6.clayshumway.com/#/c/$code';

  Future<void> _startRound(CompetitionView view) async {
    final repo = ref.read(competitionRepositoryProvider);
    if (repo == null) return;

    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      // Seed is generated client-side by the host but only ever revealed
      // through the round row, which players can't read until it exists.
      final seed = Random.secure().nextInt(1 << 31);
      await repo.startNextRound(
          competitionId: widget.competitionId, seed: seed);
    } on CompetitionException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not start the round.');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final async = ref.watch(competitionViewProvider(widget.competitionId));
    final myId = ref.watch(authUserProvider).value?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Competition')),
      body: PageBody(
        child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Couldn't load this competition.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.noteText),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(
                      competitionViewProvider(widget.competitionId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (view) => _Body(
          view: view,
          myId: myId,
          starting: _starting,
          readying: _readying,
          rematching: _rematching,
          error: _error,
          onStart: () => _startRound(view),
          onShare: () => _share(view.competition.code),
          onPlay: () => _play(view),
          onReady: _markReady,
          onRematch: () => _goToRematch(view),
        ),
        ),
      ),
    );
  }

  Future<void> _share(String code) async {
    final text = 'Join my Sudoku 6 competition — code $code\n${_shareUrl(code)}';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite copied to clipboard')),
      );
    }
  }

  void _play(CompetitionView view) {
    final round = view.round;
    if (round == null) return;
    context.push(
      '${AppRoutes.game}/${view.competition.difficulty.name}'
      '?seed=${round.seed}'
      '&competition=${widget.competitionId}'
      '&round=${round.roundNumber}',
    );
  }
}

class _Body extends StatelessWidget {
  final CompetitionView view;
  final String? myId;
  final bool starting;
  final bool readying;
  final bool rematching;
  final String? error;
  final VoidCallback onStart;
  final VoidCallback onShare;
  final VoidCallback onPlay;
  final VoidCallback onReady;
  final VoidCallback onRematch;

  const _Body({
    required this.view,
    required this.myId,
    required this.starting,
    required this.readying,
    required this.rematching,
    required this.error,
    required this.onStart,
    required this.onShare,
    required this.onPlay,
    required this.onReady,
    required this.onRematch,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final c = view.competition;
    final isHost = c.isHost(myId);
    final iFinished = view.hasFinishedCurrent(myId);
    final roundsLeft = c.currentRound < c.rounds;
    final iReady = view.hasMarkedReady(myId);
    final allOthersReady = view.allOthersReady(c.hostId);
    // The host doesn't press Ready (their Start counts), so readiness is
    // shown out of the non-host player count.
    final othersTotal =
        view.players.where((p) => p.userId != c.hostId).length;
    final othersReady = view.readyNextRound
        .where((id) => id != c.hostId)
        .length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _CodeCard(code: c.code, onShare: onShare),
        const SizedBox(height: 20),
        Text(
          '${difficultyLabel(c.difficulty)} · '
          '${c.isComplete ? "finished" : "round ${c.currentRound == 0 ? 1 : c.currentRound} of ${c.rounds}"}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),

        if (c.isComplete) ...[
          _Winner(view: view, myId: myId),
          // Only advertise a rematch while it can still be joined. If the
          // group already ran it to completion, this player just sees the
          // normal Rematch button, which starts the next one in the chain.
          if (view.rematchJoinable)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'A rematch has been started!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: palette.primary, fontWeight: FontWeight.w600),
              ),
            ),
          FilledButton.icon(
            onPressed: rematching ? null : onRematch,
            icon: rematching
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.replay, size: 18),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(view.rematchJoinable
                  ? 'Join the rematch'
                  : 'Rematch — same settings, new puzzles'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            view.rematchJoinable
                ? 'Everyone from this competition can join it.'
                : 'Previous players get an email invite, and the old link '
                    'carries people in too.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.noteText),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.compete),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('New competition (different settings)'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Back to home'),
          ),
          const SizedBox(height: 8),
        ],

        // Lobby: waiting for people before anything is playable.
        if (c.inLobby) ...[
          Text('Players (${view.players.length})',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final p in view.players)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(p.username),
              trailing: p.userId == c.hostId
                  ? Text('host', style: TextStyle(color: palette.noteText))
                  : null,
            ),
          const SizedBox(height: 8),
          if (!view.canStart)
            Text(
              'Waiting for at least one more player. Share the code above.',
              style: TextStyle(color: palette.noteText),
            ),
          if (isHost) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: view.canStart && !starting ? onStart : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: starting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(view.canStart
                        ? 'Start round 1'
                        : 'Need 2 players to start'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Starting reveals the puzzle to everyone at once. You can start "
              "without waiting for stragglers.",
              style: TextStyle(fontSize: 12, color: palette.noteText),
            ),
          ] else
            Text('Waiting for the host to start.',
                style: TextStyle(color: palette.noteText)),
        ],

        // A round is live.
        if (!c.inLobby && !c.isComplete) ...[
          if (!iFinished)
            FilledButton(
              onPressed: onPlay,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Play round ${c.currentRound}'),
              ),
            )
          else ...[
            Row(
              children: [
                Icon(Icons.check_circle, color: palette.primary, size: 18),
                const SizedBox(width: 8),
                Text('You finished round ${c.currentRound}',
                    style: TextStyle(color: palette.noteText)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${view.finishedCurrentRound.length} of ${view.players.length} '
              'players done',
              style: TextStyle(fontSize: 12, color: palette.noteText),
            ),
            // The between-rounds pause: non-host players signal Ready, and
            // the next round can't begin until everyone has.
            if (roundsLeft && !isHost) ...[
              const SizedBox(height: 12),
              if (!iReady)
                FilledButton(
                  onPressed: readying ? null : onReady,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: readying
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Ready for round ${c.currentRound + 1}'),
                  ),
                )
              else
                Row(
                  children: [
                    Icon(Icons.hourglass_top,
                        color: palette.noteText, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Ready — waiting for the host to start '
                      '($othersReady of $othersTotal ready)',
                      style: TextStyle(color: palette.noteText),
                    ),
                  ],
                ),
            ],
          ],
          if (isHost && roundsLeft) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: starting || !allOthersReady ? null : onStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(allOthersReady
                    ? 'Start round ${c.currentRound + 1}'
                    : 'Waiting for ready ($othersReady of $othersTotal)'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Everyone else taps Ready first. Starting counts as yours.',
              style: TextStyle(fontSize: 12, color: palette.noteText),
            ),
          ],
        ],

        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: TextStyle(color: palette.errorText)),
        ],

        if (view.standings.isNotEmpty) ...[
          const Divider(height: 40),
          Text('Standings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _Standings(view: view, myId: myId),
        ],
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onShare;

  const _CodeCard({required this.code, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.gridLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite code',
                    style: TextStyle(fontSize: 12, color: palette.noteText)),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share invite',
          ),
        ],
      ),
    );
  }
}

class _Standings extends StatelessWidget {
  final CompetitionView view;
  final String? myId;

  const _Standings({required this.view, required this.myId});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        for (var i = 0; i < view.standings.length; i++)
          Builder(builder: (context) {
            final s = view.standings[i];
            final isMe = s.userId == myId;
            return Container(
              color: isMe ? palette.selectedCell : null,
              child: ListTile(
                dense: true,
                leading: SizedBox(
                  width: 24,
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: palette.noteText)),
                ),
                title: Text(s.username,
                    style: TextStyle(
                        fontWeight:
                            isMe ? FontWeight.w700 : FontWeight.w500)),
                subtitle: Text(
                  '${s.roundsPlayed} round${s.roundsPlayed == 1 ? "" : "s"} · '
                  '${s.totalMistakes} mistakes',
                  style: TextStyle(fontSize: 12, color: palette.noteText),
                ),
                trailing: Text(
                  formatMinutesSeconds(s.totalMs ~/ 1000),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _Winner extends StatelessWidget {
  final CompetitionView view;
  final String? myId;

  const _Winner({required this.view, required this.myId});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (view.standings.isEmpty) return const SizedBox.shrink();
    final winner = view.standings.first;
    final iWon = winner.userId == myId;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.primary, width: 2),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            iWon ? 'You win!' : '${winner.username} wins',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${formatMinutesSeconds(winner.totalMs ~/ 1000)} across '
            '${winner.roundsPlayed} round${winner.roundsPlayed == 1 ? "" : "s"}',
            style: TextStyle(color: palette.noteText),
          ),
        ],
      ),
    );
  }
}
