import 'package:go_router/go_router.dart';

import '../../engine/models/difficulty.dart';
import '../screens/game/game_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/results/game_summary.dart';
import '../screens/results/results_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/stats/stats_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const home = '/';
  static const game = '/game';
  static const results = '/results';
  static const stats = '/stats';
  static const settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.game}/:difficulty',
      builder: (context, state) {
        final difficulty = Difficulty.values.firstWhere(
          (d) => d.name == state.pathParameters['difficulty'],
          orElse: () => Difficulty.easy,
        );
        final daily = state.uri.queryParameters['daily'] == 'true';
        return GameScreen(difficulty: difficulty, daily: daily);
      },
    ),
    GoRoute(
      path: AppRoutes.results,
      builder: (context, state) =>
          ResultsScreen(summary: state.extra! as GameSummary),
    ),
    GoRoute(
      path: AppRoutes.stats,
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
