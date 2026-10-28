import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/shell/app_shell.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_state.dart';
import 'package:languagelearner/features/auth/sign_in_screen.dart';
import 'package:languagelearner/features/home/home_screen.dart';
import 'package:languagelearner/features/photo_quiz/screens/photo_capture_screen.dart';
import 'package:languagelearner/features/photo_quiz/screens/photo_fill_screen.dart';
import 'package:languagelearner/features/photo_quiz/screens/photo_processing_screen.dart';
import 'package:languagelearner/features/photo_quiz/screens/photo_review_screen.dart';
import 'package:languagelearner/features/photo_quiz/screens/saved_quizzes_screen.dart';
import 'package:languagelearner/features/play/flashcards/flashcards_screen.dart';
import 'package:languagelearner/features/play/matching/matching_screen.dart';
import 'package:languagelearner/features/play/mix/mix_screen.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/play_placeholder_screen.dart';
import 'package:languagelearner/features/play/quiz/quiz_screen.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/play/summary/round_summary_screen.dart';
import 'package:languagelearner/features/play/typing/typing_screen.dart';
import 'package:languagelearner/features/play/widgets/game_gate.dart';
import 'package:languagelearner/features/settings/settings_screen.dart';
import 'package:languagelearner/features/stats/stats_screen.dart';
import 'package:languagelearner/features/voice_trial/voice_trial_screen.dart';

/// The app router. Tests override it to start on another route.
///
/// Nobody gets past the sign-in screen without signing in: every route goes
/// there while nobody is signed in, and the sign-in screen goes to the home
/// screen once somebody is.
final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = _AuthChanges();
  ref.listen(authControllerProvider, (_, _) => authChanges.notify());
  final router = createAppRouter(
    refreshListenable: authChanges,
    redirect: (context, state) =>
        signInRedirect(ref.read(authControllerProvider), state.uri.path),
  );
  ref.onDispose(() {
    router.dispose();
    authChanges.dispose();
  });
  return router;
});

/// Where to send the student, `null` to stay at [location].
@visibleForTesting
String? signInRedirect(AuthState auth, String location) {
  final onSignIn = location == AppRoutes.signIn;
  return switch (auth) {
    SignedOut() => onSignIn ? null : AppRoutes.signIn,
    SignedIn() => onSignIn ? AppRoutes.home : null,
  };
}

/// Tells the router to check its redirect again when the sign-in changes.
class _AuthChanges extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Builds the route tree.
///
/// - Three tabs with the bottom navigation: Learn, Statistics, Settings. Each
///   tab keeps its own navigation state while another tab is open.
/// - The photo-quiz routes, the game routes and the sign-in are outside the
///   tabs, so they have no bottom navigation. A game route opened without a deck that fits the mode
///   goes back to the home screen (see `GameGate`).
///
/// Without a [redirect] every route can be opened, which is what most tests
/// want.
GoRouter createAppRouter({
  String initialLocation = AppRoutes.home,
  GoRouterRedirect? redirect,
  Listenable? refreshListenable,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: redirect,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
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
      GoRoute(
        path: AppRoutes.voiceTrial,
        builder: (context, state) => const VoiceTrialScreen(),
      ),
      GoRoute(
        path: AppRoutes.photoQuiz,
        builder: (context, state) => const PhotoCaptureScreen(),
      ),
      GoRoute(
        path: AppRoutes.photoQuizProcessing,
        builder: (context, state) => const PhotoProcessingScreen(),
      ),
      GoRoute(
        path: AppRoutes.photoQuizReview,
        builder: (context, state) => const PhotoReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.photoQuizFill,
        builder: (context, state) => const PhotoFillScreen(),
      ),
      GoRoute(
        path: AppRoutes.photoQuizSaved,
        builder: (context, state) => const SavedQuizzesScreen(),
      ),
      for (final mode in PlayMode.values) ...[
        GoRoute(
          path: AppRoutes.play(mode),
          builder: (context, state) => GameGate(
            mode: mode,
            child: switch (mode) {
              PlayMode.flashcards => const FlashcardsScreen(),
              PlayMode.matching => const MatchingScreen(),
              PlayMode.quiz => const QuizScreen(),
              PlayMode.typing => const TypingScreen(),
              PlayMode.mix => const MixScreen(),
            },
          ),
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
