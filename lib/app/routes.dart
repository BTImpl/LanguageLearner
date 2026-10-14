import 'package:languagelearner/features/play/play_mode.dart';

/// Route paths of the app.
abstract final class AppRoutes {
  static const String home = '/';
  static const String stats = '/stats';
  static const String settings = '/settings';

  /// Full-screen game route, without the bottom navigation.
  static String play(PlayMode mode) => '/play/${mode.name}';

  /// The round-end screen of a game.
  static String summary(PlayMode mode) => '${play(mode)}/summary';
}
