import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/shell/app_shell.dart';
import 'package:languagelearner/features/home/home_screen.dart';
import 'package:languagelearner/features/play/flashcards/flashcards_screen.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/play_placeholder_screen.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/play/summary/round_summary_screen.dart';
import 'package:languagelearner/features/settings/settings_screen.dart';
import 'package:languagelearner/features/stats/stats_screen.dart';

/// The app router. Tests override it to start on another route.
final routerProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

/// Builds the route tree.
///
/// - Three tabs with the bottom navigation: Learn, Statistics, Settings. Each
///   tab keeps its own navigation state while another tab is open.
/// - The game routes are outside the tabs, so they have no bottom navigation.
GoRouter createAppRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      for (final mode in PlayMode.values) ...[
        GoRoute(
          path: AppRoutes.play(mode),
          builder: (context, state) => switch (mode) {
            PlayMode.flashcards => const FlashcardsScreen(),
            _ => PlayPlaceholderScreen(mode: mode),
          },
        ),
        // Not a sub-route of the game: going back to the game must build a
        // new screen (a new round), not reveal the finished one below.
        GoRoute(
          path: AppRoutes.summary(mode),
          builder: (context, state) => switch (state.extra) {
            final RoundSummaryData data => RoundSummaryScreen(data: data),
            _ => PlayPlaceholderScreen(mode: mode, summary: true),
          },
        ),
      ],
    ],
  );
}
