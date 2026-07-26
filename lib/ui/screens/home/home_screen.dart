import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../engine/models/difficulty.dart';
import '../../routing/app_router.dart';
import 'widgets/difficulty_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku 6'),
        actions: [
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
