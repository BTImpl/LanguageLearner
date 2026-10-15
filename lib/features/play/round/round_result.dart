import 'package:flutter/foundation.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';

/// Names of the extra counters a game mode can keep in a round.
abstract final class RoundCounters {
  /// How many times the student listened to a word.
  static const readAloud = 'readAloud';

  /// Wrong pairings in the matching game.
  static const wrongPairs = 'wrongPairs';

  /// Pages shown in the matching game.
  static const pages = 'pages';
}

/// The outcome of a finished round.
@immutable
class RoundResult {
  const RoundResult({
    required this.total,
    required this.firstTry,
    required this.withHelp,
    required this.wrongFirst,
    required this.missedWords,
    required this.helpedWords,
    required this.duration,
    this.extras = const {},
    this.outcomes = const {},
  });

  /// Number of words in the round.
  final int total;

  final int firstTry;
  final int withHelp;
  final int wrongFirst;

  /// The words whose first attempt was wrong, in round order.
  final List<WordPair> missedWords;

  /// The words solved with help, in round order.
  final List<WordPair> helpedWords;

  final Duration duration;

  /// Counters of the game mode, see [RoundCounters].
  final Map<String, int> extras;

  /// The outcome of every decided word by word id, in round order. Saved by
  /// the statistics at the end of the round.
  final Map<String, WordOutcome> outcomes;

  /// The elapsed time in whole minutes, rounded up.
  int get minutes => (duration.inSeconds + 59) ~/ 60;

  /// The value of the extra counter [name], 0 if it was never counted.
  int extra(String name) => extras[name] ?? 0;
}
