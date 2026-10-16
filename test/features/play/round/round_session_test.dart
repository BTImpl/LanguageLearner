import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';

List<WordPair> _words(int count) => [
  for (var i = 0; i < count; i++)
    WordPair.fromCells(id: 'w$i', english: 'en$i; en$i-b', hungarian: 'hu$i'),
];

RoundSession _session({
  int count = 12,
  int seed = 1,
  PromptLanguage promptLanguage = PromptLanguage.english,
  DateTime Function()? now,
}) => RoundSession(
  words: _words(count),
  promptLanguage: promptLanguage,
  random: Random(seed),
  now: now,
);

List<String> _ids(RoundSession session) =>
    session.words.map((word) => word.id).toList();

void main() {
  group('shuffling', () {
    test('contains every word exactly once', () {
      final session = _session();

      expect(_ids(session)..sort(), _ids(_session(seed: 99))..sort());
      expect(_ids(session).toSet(), hasLength(12));
      expect(session.total, 12);
    });

    test('the same seed gives the same order', () {
      expect(_ids(_session()), _ids(_session()));
    });

    test('different seeds give a different order', () {
      expect(_ids(_session()), isNot(_ids(_session(seed: 2))));
    });

    test('the order differs from the deck order', () {
      expect(
        _ids(_session()),
        isNot(
          _ids(
            RoundSession(
              words: _words(12),
              promptLanguage: PromptLanguage.english,
              random: _NoShuffle(),
            ),
          ),
        ),
      );
    });

    test('does not change the deck it was given', () {
      final deck = _words(5);
      RoundSession(
        words: deck,
        promptLanguage: PromptLanguage.english,
        random: Random(3),
      );

      expect(deck.map((word) => word.id), ['w0', 'w1', 'w2', 'w3', 'w4']);
    });

    test('restart gives a new order and clears the outcomes', () {
      final session = _session();
      final before = _ids(session);
      session
        ..recordAttempt(session.current!, correct: false)
        ..count(RoundCounters.readAloud)
        ..advance(3)
        ..restart();

      expect(_ids(session)..sort(), before..sort());
      expect(session.index, 0);
      expect(session.isFinished, isFalse);
      expect(session.result.wrongFirst, 0);
      expect(session.result.extra(RoundCounters.readAloud), 0);
    });
  });

  group('progress', () {
    test('walks through the words and finishes after the last one', () {
      final session = _session(count: 3);
      final seen = <String>[];

      while (!session.isFinished) {
        seen.add(session.current!.id);
        session.advance();
      }

      expect(seen, _ids(session));
      expect(session.index, 3);
      expect(session.current, isNull);
    });

    test('advance never goes past the end, back never before the start', () {
      final session = _session(count: 3)
        ..advance(10)
        ..advance();

      expect(session.index, 3);

      session
        ..back()
        ..back()
        ..back()
        ..back();

      expect(session.index, 0);
      expect(session.isFinished, isFalse);
    });

    test('an empty deck is finished right away', () {
      final session = _session(count: 0);

      expect(session.isEmpty, isTrue);
      expect(session.isFinished, isTrue);
      expect(session.current, isNull);
      expect(session.result.total, 0);
      expect(session.result.firstTry, 0);
      expect(session.result.missedWords, isEmpty);
    });
  });

  group('outcomes', () {
    test('the first attempt decides', () {
      final session = _session(count: 4);
      final [a, b, c, d] = session.words;

      session
        ..recordAttempt(a, correct: true)
        ..recordAttempt(a, correct: false)
        ..recordAttempt(b, correct: false)
        ..recordAttempt(b, correct: true)
        ..recordHelp(c)
        ..recordAttempt(c, correct: true)
        ..recordAttempt(d, correct: true)
        ..recordHelp(d);

      expect(session.outcomeOf(a), WordOutcome.firstTry);
      expect(session.outcomeOf(b), WordOutcome.wrongFirst);
      expect(session.outcomeOf(c), WordOutcome.withHelp);
      expect(session.outcomeOf(d), WordOutcome.firstTry);
    });

    test('the result counts every category and lists the words', () {
      final session = _session(count: 5);
      final w = session.words;

      session
        ..recordAttempt(w[0], correct: true)
        ..recordAttempt(w[1], correct: false)
        ..recordHelp(w[2])
        ..recordAttempt(w[3], correct: false);
      final result = session.result;

      expect(result.total, 5);
      expect(result.firstTry, 1);
      expect(result.wrongFirst, 2);
      expect(result.withHelp, 1);
      expect(result.missedWords, [w[1], w[3]]);
      expect(result.helpedWords, [w[2]]);
      expect(session.outcomeOf(w[4]), isNull);
    });

    test('rejects a word that is not in the round', () {
      final session = _session(count: 2);
      final stranger = WordPair.fromCells(
        id: 'x',
        english: 'x',
        hungarian: 'x',
      );

      expect(
        () => session.recordAttempt(stranger, correct: true),
        throwsArgumentError,
      );
    });

    test('extra counters add up', () {
      final session = _session()
        ..count(RoundCounters.readAloud)
        ..count(RoundCounters.readAloud)
        ..count(RoundCounters.wrongPairs, 3);
      final result = session.result;

      expect(result.extra(RoundCounters.readAloud), 2);
      expect(result.extra(RoundCounters.wrongPairs), 3);
      expect(result.extra(RoundCounters.pages), 0);
    });
  });

  group('duration', () {
    test('runs until the round is finished, then stops', () {
      var now = DateTime(2026, 10, 14, 12);
      final session = _session(count: 2, now: () => now);

      now = now.add(const Duration(seconds: 61));
      expect(session.result.duration, const Duration(seconds: 61));
      expect(session.result.minutes, 2);

      session.advance(2);
      now = now.add(const Duration(minutes: 10));

      expect(session.result.duration, const Duration(seconds: 61));
    });

    test('is rounded up to whole minutes', () {
      RoundResult withSeconds(int seconds) => RoundResult(
        total: 0,
        firstTry: 0,
        withHelp: 0,
        wrongFirst: 0,
        missedWords: const [],
        helpedWords: const [],
        duration: Duration(seconds: seconds),
      );

      expect(withSeconds(0).minutes, 0);
      expect(withSeconds(1).minutes, 1);
      expect(withSeconds(60).minutes, 1);
      expect(withSeconds(61).minutes, 2);
    });
  });

  group('prompt language', () {
    test('English prompt: English question, Hungarian answers', () {
      final session = _session();
      final word = session.words.first;

      expect(session.promptIsEnglish, isTrue);
      expect(session.promptText(word), word.english);
      expect(session.answerText(word), word.hungarian);
      expect(session.acceptedAnswers(word), word.acceptedHungarian);
    });

    test('Hungarian prompt: Hungarian question, English answers', () {
      final session = _session(promptLanguage: PromptLanguage.hungarian);
      final word = session.words.first;

      expect(session.promptIsEnglish, isFalse);
      expect(session.promptText(word), word.hungarian);
      expect(session.answerText(word), word.english);
      expect(session.acceptedAnswers(word), word.acceptedEnglish);
      expect(session.acceptedAnswers(word), hasLength(2));
    });
  });

  group('direction of a word', () {
    test('a word follows the prompt language of the session by default', () {
      final session = _session(promptLanguage: PromptLanguage.hungarian);
      final word = session.words.first;

      expect(session.promptLanguageOf(word), PromptLanguage.hungarian);
      expect(session.promptIsEnglishFor(word), isFalse);
    });

    test('a word can be asked in the other direction on its own', () {
      final session = _session();
      final [first, second, ...] = session.words;

      session.setPromptLanguage(first, PromptLanguage.hungarian);

      expect(session.promptLanguageOf(first), PromptLanguage.hungarian);
      expect(session.promptIsEnglishFor(first), isFalse);
      expect(session.promptText(first), first.hungarian);
      expect(session.answerText(first), first.english);
      expect(session.acceptedAnswers(first), first.acceptedEnglish);
      // The other words and the session itself are not touched.
      expect(session.promptLanguageOf(second), PromptLanguage.english);
      expect(session.promptText(second), second.english);
      expect(session.promptLanguage, PromptLanguage.english);
      expect(session.promptIsEnglish, isTrue);
    });

    test('the direction of a word can be changed again', () {
      final session = _session();
      final word = session.words.first;

      session
        ..setPromptLanguage(word, PromptLanguage.hungarian)
        ..setPromptLanguage(word, PromptLanguage.english);

      expect(session.promptText(word), word.english);
    });

    test('a restart forgets the directions of the words', () {
      final session = _session();
      final word = session.words.first;
      session.setPromptLanguage(word, PromptLanguage.hungarian);

      session.restart();

      expect(session.promptLanguageOf(word), PromptLanguage.english);
      expect(session.promptText(word), word.english);
    });

    test('a word outside the round cannot get a direction', () {
      final session = _session();
      final stranger = WordPair.fromCells(
        id: 'x',
        english: 'stranger',
        hungarian: 'idegen',
      );

      expect(
        () => session.setPromptLanguage(stranger, PromptLanguage.hungarian),
        throwsArgumentError,
      );
    });

    test('the static helpers give the texts of a direction', () {
      final word = _words(1).single;

      expect(
        RoundSession.promptIn(word, PromptLanguage.hungarian),
        word.hungarian,
      );
      expect(
        RoundSession.answerIn(word, PromptLanguage.hungarian),
        word.english,
      );
      expect(
        RoundSession.acceptedIn(word, PromptLanguage.hungarian),
        word.acceptedEnglish,
      );
      expect(RoundSession.promptIn(word, PromptLanguage.english), word.english);
      expect(
        RoundSession.answerIn(word, PromptLanguage.english),
        word.hungarian,
      );
      expect(
        RoundSession.acceptedIn(word, PromptLanguage.english),
        word.acceptedHungarian,
      );
    });
  });
}

/// A [Random] that always picks the last candidate: Fisher–Yates then swaps
/// nothing, so the order stays the deck order.
class _NoShuffle implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => max - 1;
}
