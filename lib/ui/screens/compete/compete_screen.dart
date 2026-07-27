import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/competition_repository.dart';
import '../../../engine/models/difficulty.dart';
import '../../../state/auth_provider.dart';
import '../../../state/competition_provider.dart';
import '../../../utils/difficulty_label.dart';
import '../../routing/app_router.dart';
import '../../theme/palette.dart';
import '../../widgets/page_body.dart';

class CompeteScreen extends ConsumerStatefulWidget {
  const CompeteScreen({super.key});

  @override
  ConsumerState<CompeteScreen> createState() => _CompeteScreenState();
}

class _CompeteScreenState extends ConsumerState<CompeteScreen> {
  Difficulty _difficulty = Difficulty.medium;
  int _rounds = 3;
  // Async by default: friends are rarely free at the same moment, and it's
  // also the mode with no lobby wait, no ready gate and no host start button.
  CompetitionMode _mode = CompetitionMode.async;
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(competeControllerProvider);
    // Creating also inserts the host as a player, which requires a profile.
    final profileAsync = ref.watch(myProfileProvider);
    final needsUsername =
        !profileAsync.isLoading && profileAsync.value == null;

    // Navigate once a create or join lands.
    ref.listen(competeControllerProvider, (prev, next) {
      final id = next.competitionId;
      if (id != null && prev?.competitionId != id) {
        ref.read(competeControllerProvider.notifier).reset();
        context.pushReplacement('${AppRoutes.competition}/$id');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Compete')),
      body: PageBody(
        child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (needsUsername) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pick a username first',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    "It's how you appear in standings.",
                    style: TextStyle(color: palette.noteText),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      await context.push(AppRoutes.username);
                      ref.invalidate(myProfileProvider);
                    },
                    child: const Text('Choose a username'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text('Start a competition',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Everyone plays the same puzzles. Nobody sees a puzzle until they '
            'start that round.',
            style: TextStyle(color: palette.noteText, height: 1.4),
          ),
          const SizedBox(height: 20),
          SegmentedButton<CompetitionMode>(
            segments: const [
              ButtonSegment(
                value: CompetitionMode.async,
                label: Text('Play anytime'),
                icon: Icon(Icons.schedule, size: 16),
              ),
              ButtonSegment(
                value: CompetitionMode.sync,
                label: Text('All together'),
                icon: Icon(Icons.group, size: 16),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: state.busy
                ? null
                : (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            _mode == CompetitionMode.async
                ? 'Everyone plays each round whenever they like, on their own '
                    'clock. Start playing straight away.'
                : 'Everyone plays each round at the same time. You start each '
                    'round once the others are ready.',
            style: TextStyle(fontSize: 12, color: palette.noteText, height: 1.4),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Difficulty'),
            trailing: DropdownButton<Difficulty>(
              value: _difficulty,
              onChanged: state.busy
                  ? null
                  : (d) => setState(() => _difficulty = d ?? _difficulty),
              items: [
                for (final d in Difficulty.values)
                  DropdownMenuItem(value: d, child: Text(difficultyLabel(d))),
              ],
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rounds'),
            trailing: DropdownButton<int>(
              value: _rounds,
              onChanged: state.busy
                  ? null
                  : (r) => setState(() => _rounds = r ?? _rounds),
              items: [
                for (final r in const [1, 3, 5, 7, 10])
                  DropdownMenuItem(value: r, child: Text('$r')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.busy || needsUsername
                ? null
                : () => ref.read(competeControllerProvider.notifier).create(
                      difficulty: _difficulty,
                      rounds: _rounds,
                      mode: _mode,
                    ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: state.busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create competition'),
            ),
          ),
          const Divider(height: 48),
          Text('Join with a code',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            enabled: !state.busy,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              // Codes are generated uppercase; accept any case and normalise
              // so a code typed from a text message just works.
              TextInputFormatter.withFunction((_, next) =>
                  next.copyWith(text: next.text.toUpperCase())),
            ],
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 8),
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'CODE',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (v) =>
                ref.read(competeControllerProvider.notifier).join(v),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: state.busy || needsUsername || _codeController.text.trim().length < 4
                ? null
                : () => ref
                    .read(competeControllerProvider.notifier)
                    .join(_codeController.text),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Join'),
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.errorText)),
          ],
          // Past and ongoing competitions. Finished ones are where Rematch
          // lives, so this doubles as the way back to old groups.
          ...ref.watch(myCompetitionsProvider).when(
                loading: () => const <Widget>[],
                error: (_, _) => const <Widget>[],
                data: (comps) => comps.isEmpty
                    ? const <Widget>[]
                    : [
                        const Divider(height: 48),
                        Text('Your competitions',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        for (final c in comps)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                                '${c.code} · ${difficultyLabel(c.difficulty)}'),
                            subtitle: Text(
                              '${c.rounds} round${c.rounds == 1 ? "" : "s"} · '
                              '${_statusLabel(c)}',
                              style: TextStyle(
                                  fontSize: 12, color: palette.noteText),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context
                                .push('${AppRoutes.competition}/${c.id}'),
                          ),
                      ],
              ),
        ],
        ),
      ),
    );
  }

  String _statusLabel(Competition c) => switch (c.status) {
        CompetitionStatus.lobby => 'waiting for players',
        CompetitionStatus.active => c.isAsync
            ? 'in progress · play anytime'
            : 'round ${c.currentRound} of ${c.rounds}',
        CompetitionStatus.complete =>
          c.rematchId != null ? 'finished · rematch started' : 'finished',
      };
}
