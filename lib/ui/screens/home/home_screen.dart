import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../engine/models/difficulty.dart';
import '../../../state/auth_provider.dart';
import '../../../utils/difficulty_label.dart';
import '../../routing/app_router.dart';
import '../../theme/palette.dart';
import '../../widgets/page_body.dart';
import 'widgets/difficulty_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hidden entirely when Supabase isn't configured, so an offline build
    // never shows an account button that can't work.
    final authAvailable = ref.watch(authAvailableProvider);
    final signedIn = ref.watch(isSignedInProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku 6'),
        actions: [
          if (authAvailable)
            IconButton(
              tooltip: signedIn ? 'Account' : 'Sign in',
              icon: Icon(signedIn
                  ? Icons.account_circle
                  : Icons.account_circle_outlined),
              onPressed: () => context
                  .push(signedIn ? AppRoutes.account : AppRoutes.signIn),
            ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => context.push(AppRoutes.stats),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DailyCard(),
            const SizedBox(height: 20),
            if (authAvailable) ...[
            OutlinedButton.icon(
              onPressed: () => context.push(
                  signedIn ? AppRoutes.compete : AppRoutes.signIn),
              icon: const Icon(Icons.groups_outlined, size: 18),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(signedIn
                    ? 'Compete with friends'
                    : 'Sign in to compete'),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text('Choose a difficulty',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final difficulty in Difficulty.values) ...[
            DifficultyCard(difficulty: difficulty),
            const SizedBox(height: 12),
          ],
        ],
        ),
      ),
    );
  }
}

/// The daily puzzle: same seed for everyone on a given date, tier rotating
/// with the weekday. The engine has supported deterministic dailies since v1
/// (`dailySeedFor`), but no entry point ever surfaced it -- it was reachable
/// only by hand-typing a ?daily=true URL.
class _DailyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final now = DateTime.now();
    // Monday=easy .. Friday=master, weekend wraps back around.
    final tier = Difficulty.values[(now.weekday - 1) % Difficulty.values.length];

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('${AppRoutes.game}/${tier.name}?daily=true'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.today_outlined, color: palette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily Puzzle',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${difficultyLabel(tier)} · everyone gets the same board today',
                    style: TextStyle(fontSize: 12, color: palette.noteText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
