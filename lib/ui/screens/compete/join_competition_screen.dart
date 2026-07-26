import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../state/auth_provider.dart';
import '../../../state/competition_provider.dart';
import '../../routing/app_router.dart';
import '../../theme/palette.dart';

/// Landing screen for an invite link. Joining requires an account, so this
/// explains why rather than bouncing an unexpecting visitor to a sign-in form.
class JoinCompetitionScreen extends ConsumerStatefulWidget {
  final String code;

  const JoinCompetitionScreen({super.key, required this.code});

  @override
  ConsumerState<JoinCompetitionScreen> createState() =>
      _JoinCompetitionScreenState();
}

class _JoinCompetitionScreenState
    extends ConsumerState<JoinCompetitionScreen> {
  bool _attempted = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final signedIn = ref.watch(isSignedInProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final state = ref.watch(competeControllerProvider);
    final code = widget.code.toUpperCase();

    // Being signed in isn't enough: a player row references profiles, and
    // someone arriving via an invite signs up *before* ever seeing the
    // username screen. Joining without a profile fails on a foreign key with
    // an error the user can do nothing about.
    final hasUsername = profileAsync.value != null;
    final needsUsername = signedIn && !profileAsync.isLoading && !hasUsername;

    ref.listen(competeControllerProvider, (prev, next) {
      final id = next.competitionId;
      if (id != null && prev?.competitionId != id) {
        ref.read(competeControllerProvider.notifier).reset();
        context.pushReplacement('${AppRoutes.competition}/$id');
      }
    });

    // Auto-join once they're signed in *and* have a username, so an invite is
    // one tap for someone who already has an account.
    if (signedIn && hasUsername && !_attempted && !state.busy) {
      _attempted = true;
      Future.microtask(
          () => ref.read(competeControllerProvider.notifier).join(code));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Join competition')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You\'ve been invited',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                code,
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8),
              ),
              const SizedBox(height: 24),
              if (!signedIn) ...[
                Text(
                  'Competitions need an account so scores can be attributed. '
                  'It takes one email code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.noteText, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.signIn),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    child: Text('Sign in to join'),
                  ),
                ),
              ] else if (needsUsername) ...[
                Text(
                  'Pick a username first — it\'s how you\'ll show up in the '
                  'standings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.noteText, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    await context.push(AppRoutes.username);
                    // Re-read on return so the auto-join above can fire.
                    ref.invalidate(myProfileProvider);
                    if (mounted) setState(() => _attempted = false);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    child: Text('Choose a username'),
                  ),
                ),
              ] else if (state.error != null) ...[
                Text(state.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.errorText)),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref
                      .read(competeControllerProvider.notifier)
                      .join(code),
                  child: const Text('Try again'),
                ),
              ] else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
