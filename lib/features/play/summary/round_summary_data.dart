import 'package:flutter/foundation.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';

/// One statistics tile of the round-end screen.
@immutable
class SummaryStat {
  const SummaryStat({
    required this.value,
    required this.label,
    this.tone = StatTone.neutral,
  });

  final String value;
  final String label;
  final StatTone tone;
}

/// A word in the "worth another look" list: the asked text and its pair.
@immutable
class ReviewWord {
  const ReviewWord({required this.prompt, required this.answer});

  final String prompt;
  final String answer;
}

/// What the round-end screen shows. Every game mode builds one from its
/// `RoundResult` and passes it as the `extra` of the summary route.
@immutable
class RoundSummaryData {
  const RoundSummaryData({
    required this.modeName,
    required this.deckName,
    required this.headline,
    required this.stats,
    required this.restartLabel,
    required this.restartLocation,
    this.reviewWords = const [],
  }) : assert(
         stats.length >= 2 && stats.length <= 3,
         'The round-end screen shows two or three tiles.',
       );

  final String modeName;
  final String deckName;

  /// The big text of the head card, e.g. "9 of 12 words right first time".
  final String headline;

  /// Two or three tiles, shown in one row.
  final List<SummaryStat> stats;

  /// The words to look at again; the list is hidden when empty.
  final List<ReviewWord> reviewWords;

  /// The text of the primary button, e.g. "Restart Quiz".
  final String restartLabel;

  /// The route the primary button opens: the game route of the mode, which
  /// starts a new, reshuffled round.
  final String restartLocation;
}
