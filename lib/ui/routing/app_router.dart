import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/models/difficulty.dart';
import '../../state/auth_provider.dart';
import '../screens/auth/account_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/username_screen.dart';
import '../screens/compete/compete_screen.dart';
import '../screens/compete/competition_screen.dart';
import '../screens/compete/join_competition_screen.dart';
import '../screens/game/game_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/leaderboard/global_leaderboard_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
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
  static const signIn = '/sign-in';
  static const username = '/username';
  static const account = '/account';
  static const leaderboard = '/leaderboard';

  /// Aggregate standings across every puzzle, as opposed to the per-puzzle
  /// board at [leaderboard]/:difficulty/:seed.
  static const globalLeaderboard = '/leaderboards';

  /// Shareable link to one exact puzzle, e.g. /p/hard-4821093.
  /// The seed *is* the puzzle, so this needs no server lookup and works
  /// signed out.
  static const puzzle = '/p';

  static const compete = '/compete';
  static const competition = '/competition';

  /// Invite link, e.g. /c/K3F9QP -- joins then opens the competition.
  static const joinCode = '/c';
}

Difficulty _difficultyFrom(String? name) => Difficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => Difficulty.easy,
    );

/// Parses a share code like "hard-4821093". Returns null when the tier is
/// unknown or the seed isn't an integer, so a mistyped link lands on home
/// rather than silently starting the wrong puzzle.
({Difficulty difficulty, int seed})? _parsePuzzleCode(String? code) {
  if (code == null) return null;
  final dash = code.lastIndexOf('-');
  if (dash <= 0) return null;
  final tier = code.substring(0, dash);
  final seed = int.tryParse(code.substring(dash + 1));
  if (seed == null) return null;
  final match =
      Difficulty.values.where((d) => d.name == tier).firstOrNull;
  if (match == null) return null;
  return (difficulty: match, seed: seed);
}

/// Re-runs the router's redirect whenever auth or profile state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authUserProvider, (_, _) => notifyListeners());
    ref.listen(myProfileProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Solo play is never gated. Only account routes participate in
      // redirects; everything else stays reachable signed out.
      const accountRoutes = {
        AppRoutes.signIn,
        AppRoutes.username,
        AppRoutes.account,
      };
      if (!accountRoutes.contains(loc)) return null;

      final signedIn = ref.read(authUserProvider).value != null;

      if (!signedIn) {
        return loc == AppRoutes.signIn ? null : AppRoutes.signIn;
      }

      // Signed in but the profile hasn't resolved yet -- hold position rather
      // than flashing the username screen and bouncing back.
      final profileAsync = ref.read(myProfileProvider);
      if (profileAsync.isLoading) return null;

      final hasUsername = profileAsync.value != null;
      if (!hasUsername) {
        return loc == AppRoutes.username ? null : AppRoutes.username;
      }

      // Fully set up: sign-in and username screens have nothing left to do.
      if (loc == AppRoutes.signIn || loc == AppRoutes.username) {
        return AppRoutes.account;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.game}/:difficulty',
        builder: (context, state) {
          final difficulty = _difficultyFrom(state.pathParameters['difficulty']);
          final q = state.uri.queryParameters;
          return GameScreen(
            difficulty: difficulty,
            daily: q['daily'] == 'true',
            seed: int.tryParse(q['seed'] ?? ''),
            competitionId: q['competition'],
            roundNumber: int.tryParse(q['round'] ?? ''),
          );
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
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.username,
        builder: (context, state) => const UsernameScreen(),
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.globalLeaderboard,
        builder: (context, state) => const GlobalLeaderboardScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.leaderboard}/:difficulty/:seed',
        builder: (context, state) {
          final difficulty = _difficultyFrom(state.pathParameters['difficulty']);
          final seed = int.tryParse(state.pathParameters['seed'] ?? '') ?? 0;
          return LeaderboardScreen(difficulty: difficulty, seed: seed);
        },
      ),
      GoRoute(
        path: AppRoutes.compete,
        builder: (context, state) => const CompeteScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.competition}/:id',
        builder: (context, state) =>
            CompetitionScreen(competitionId: state.pathParameters['id']!),
      ),
      GoRoute(
        // /c/K3F9QP -- an invite. Joining needs an account, so the redirect
        // sends signed-out visitors to sign in and they land back here.
        path: '${AppRoutes.joinCode}/:code',
        builder: (context, state) =>
            JoinCompetitionScreen(code: state.pathParameters['code']!),
      ),
      GoRoute(
        // /p/hard-4821093 -- opens that exact puzzle for anyone with the link.
        // Builds the game directly rather than redirecting: a redirect-only
        // GoRoute doesn't register as a match, so shared links 404'd.
        path: '${AppRoutes.puzzle}/:code',
        redirect: (context, state) =>
            _parsePuzzleCode(state.pathParameters['code']) == null
                ? AppRoutes.home
                : null,
        builder: (context, state) {
          final parsed = _parsePuzzleCode(state.pathParameters['code'])!;
          return GameScreen(difficulty: parsed.difficulty, seed: parsed.seed);
        },
      ),
    ],
  );
});
