import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';

void main() {
  test('the result lists the outcome of every decided word in round order', () {
    final words = [
      for (var i = 0; i < 4; i++)
        WordPair.fromCells(id: 'w$i', english: 'en$i', hungarian: 'hu$i'),
    ];
    final session = RoundSession(
      words: words,
      promptLanguage: PromptLanguage.english,
      random: Random(3),
    );
    final order = session.words;

    session
      ..recordAttempt(order[0], correct: true)
      ..recordAttempt(order[1], correct: false)
      ..recordHelp(order[2])
      // A later attempt on a decided word changes nothing.
      ..recordAttempt(order[1], correct: true);

    final outcomes = session.result.outcomes;

    expect(outcomes.keys.toList(), [order[0].id, order[1].id, order[2].id]);
    expect(outcomes.values.toList(), [
      WordOutcome.firstTry,
      WordOutcome.wrongFirst,
      WordOutcome.withHelp,
    ]);
  });
}
