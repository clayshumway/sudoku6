import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/models/difficulty.dart';
import '../../state/auth_provider.dart';
import '../screens/auth/account_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/username_screen.dart';
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
  static const signIn = '/sign-in';
  static const username = '/username';
  static const account = '/account';
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
    ],
  );
});
