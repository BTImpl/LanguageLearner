import 'package:languagelearner/features/play/play_mode.dart';

/// Route paths of the app.
abstract final class AppRoutes {
  static const String signIn = '/sign-in';
  static const String home = '/';
  static const String stats = '/stats';
  static const String settings = '/settings';

  /// The quiz made from a photo, outside the tabs: where a photo is taken or
  /// chosen, the screen while it is read, and the review of the quiz.
  static const String photoQuiz = '/photo-quiz';
  static const String photoQuizProcessing = '/photo-quiz/processing';
  static const String photoQuizReview = '/photo-quiz/review';
  static const String photoQuizFill = '/photo-quiz/fill';
  static const String photoQuizSaved = '/photo-quiz/saved';

  /// Full-screen game route, without the bottom navigation.
  static String play(PlayMode mode) => '/play/${mode.name}';

  /// The round-end screen of a game.
  static String summary(PlayMode mode) => '${play(mode)}/summary';
}
