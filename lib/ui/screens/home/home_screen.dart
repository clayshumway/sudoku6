import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../engine/models/difficulty.dart';
import '../../../state/auth_provider.dart';
import '../../routing/app_router.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
    );
  }
}
