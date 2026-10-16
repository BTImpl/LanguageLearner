import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/quiz/quiz_game.dart';
import 'package:languagelearner/features/play/quiz/quiz_option.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';

import '../../../helpers/manual_scheduler.dart';

List<WordPair> _words(int count) => [
  for (var i = 0; i < count; i++)
    WordPair.fromCells(id: 'w$i', english: 'en$i', hungarian: 'hu$i'),
];

const _delay = Duration(milliseconds: 400);

class _Setup {
  _Setup({
    int count = 12,
    List<WordPair>? words,
    List<WordPair>? pool,
    PromptLanguage promptLanguage = PromptLanguage.english,
    int seed = 1,
  }) {
    session = RoundSession(
      words: words ?? _words(count),
      promptLanguage: promptLanguage,
      random: Random(seed),
    );
    game = QuizGame(
      session: session,
      pool: pool,
      random: Random(seed),
      schedule: scheduler.call,
    );
  }

  final scheduler = ManualScheduler();
  late final RoundSession session;
  late final QuizGame game;

  QuizOption get correct => game.options.firstWhere((o) => o.isCorrect);

  List<QuizOption> get wrong => [
    for (final option in game.options)
      if (!option.isCorrect) option,
  ];

  QuizOptionState stateOf(QuizOption option) => game.options
      .firstWhere((candidate) => candidate.word.id == option.word.id)
      .state;

  void answerRight() {
    game.choose(correct.word);
    scheduler.elapse(_delay);
  }
}

void main() {
  group('options', () {
    test('every question has four different answers with the right one', () {
      final s = _Setup();
      final asked = <String>[];

      while (!s.game.isFinished) {
        final options = s.game.options;
        expect(options, hasLength(4));
        expect(options.map((o) => o.text).toSet(), hasLength(4));
        expect(options.where((o) => o.isCorrect), hasLength(1));
        expect(s.correct.text, s.session.answerText(s.game.current!));
        asked.add(s.game.current!.id);
        s.answerRight();
      }

      expect(asked, hasLength(12));
      expect(asked.toSet(), hasLength(12));
    });

    test('the wrong answers come from the deck', () {
      final s = _Setup();
      final ids = s.session.words.map((word) => word.id).toSet();

      while (!s.game.isFinished) {
        for (final option in s.wrong) {
          expect(ids, contains(option.word.id));
          expect(option.word.id, isNot(s.game.current!.id));
        }
        s.answerRight();
      }
    });

    test('the right answer does not always sit in the same place', () {
      final places = <int>{};
      for (var seed = 1; seed <= 20; seed++) {
        final s = _Setup(seed: seed);
        places.add(s.game.options.indexWhere((o) => o.isCorrect));
      }

      expect(places.length, greaterThan(1));
    });

    test('a Hungarian question has English answers', () {
      final s = _Setup(promptLanguage: PromptLanguage.hungarian);

      for (final option in s.game.options) {
        expect(option.text, startsWith('en'));
      }
      expect(s.correct.text, s.game.current!.english);
    });

    test('wrong answers come from the whole deck, not only the round', () {
      final deck = _words(6);
      final s = _Setup(words: deck.sublist(0, 2), pool: deck);

      expect(s.game.isPlayable, isTrue);
      expect(s.game.options, hasLength(4));
      final inRound = deck.sublist(0, 2).map((word) => word.id).toSet();
      expect(s.wrong.where((o) => !inRound.contains(o.word.id)), isNotEmpty);
    });

    test('a word with the same translation is never a wrong answer', () {
      final deck = [
        WordPair.fromCells(id: 'a', english: 'ticket', hungarian: 'jegy'),
        WordPair.fromCells(id: 'b', english: 'fare', hungarian: ' Jegy '),
        ..._words(5),
      ];
      final s = _Setup(words: deck);

      expect(s.game.isPlayable, isTrue);
      while (!s.game.isFinished) {
        expect(
          s.game.options.map((o) => o.text.trim().toLowerCase()).toSet(),
          hasLength(4),
        );
        s.answerRight();
      }
    });

    test('a word that accepts the right answer is not a wrong answer', () {
      final deck = [
        WordPair.fromCells(id: 'a', english: 'ticket', hungarian: 'jegy'),
        WordPair.fromCells(
          id: 'b',
          english: 'fare',
          hungarian: 'viteldíj; jegy',
        ),
        ..._words(5),
      ];
      final s = _Setup(words: deck);

      while (!s.game.isFinished) {
        if (s.game.current!.id == 'a') {
          expect(s.wrong.map((o) => o.word.id), isNot(contains('b')));
        }
        s.answerRight();
      }
    });
  });

  group('direction of a word', () {
    test('a word with its own direction gets answers in that language', () {
      final session = RoundSession(
        words: _words(12),
        promptLanguage: PromptLanguage.english,
        random: Random(1),
      );
      final asked = session.words.first;
      session.setPromptLanguage(asked, PromptLanguage.hungarian);

      final game = QuizGame(session: session, random: Random(1));

      expect(game.isPlayable, isTrue);
      expect(game.current, asked);
      expect(game.options, hasLength(4));
      expect(game.options.every((o) => o.text.startsWith('en')), isTrue);
      expect(game.options.singleWhere((o) => o.isCorrect).text, asked.english);
      game.dispose();
    });

    test('isPlayableIn tells which directions the deck can be asked in', () {
      // Three Hungarian texts only: an English question has just two wrong
      // Hungarian answers, a Hungarian question has plenty of English ones.
      final words = [
        for (var i = 0; i < 6; i++)
          WordPair.fromCells(
            id: 'w$i',
            english: 'en$i',
            hungarian: 'hu${i % 3}',
          ),
      ];
      final session = RoundSession(
        words: words,
        promptLanguage: PromptLanguage.english,
        random: Random(1),
      );

      expect(QuizGame.isPlayableIn(session, PromptLanguage.english), isFalse);
      expect(QuizGame.isPlayableIn(session, PromptLanguage.hungarian), isTrue);
    });

    test('isPlayableIn takes the wrong answers from the given pool', () {
      final session = RoundSession(
        words: _words(2),
        promptLanguage: PromptLanguage.english,
        random: Random(1),
      );

      expect(QuizGame.isPlayableIn(session, PromptLanguage.english), isFalse);
      expect(
        QuizGame.isPlayableIn(session, PromptLanguage.english, pool: _words(8)),
        isTrue,
      );
    });
  });

  group('answering', () {
    test('a wrong answer turns red, stays and the word does not move on', () {
      final s = _Setup();
      final asked = s.game.current;
      final picked = s.wrong.first;

      s.game.choose(picked.word);
      s.scheduler.elapse(const Duration(seconds: 5));

      expect(s.stateOf(picked), QuizOptionState.wrong);
      expect(s.game.current, asked);
      expect(s.game.index, 0);
      expect(s.scheduler.pending, 0);
    });

    test('the other answers can still be chosen after a wrong one', () {
      final s = _Setup();
      final picked = s.wrong.first;
      final other = s.wrong.last;

      s.game
        ..choose(picked.word)
        ..choose(other.word);

      expect(s.stateOf(picked), QuizOptionState.wrong);
      expect(s.stateOf(other), QuizOptionState.wrong);
      expect(s.stateOf(s.correct), QuizOptionState.idle);
    });

    test('a chosen wrong answer is ignored when chosen again', () {
      final s = _Setup();
      final picked = s.wrong.first;

      s.game
        ..choose(picked.word)
        ..choose(picked.word);

      expect(s.session.result.wrongFirst, 1);
      expect(s.stateOf(picked), QuizOptionState.wrong);
    });

    test('the right answer turns green, the next question follows later', () {
      final s = _Setup();
      final first = s.game.current;

      s.game.choose(s.correct.word);

      expect(s.stateOf(s.correct), QuizOptionState.correct);
      expect(s.game.current, first);
      s.scheduler.elapse(const Duration(milliseconds: 399));
      expect(s.game.current, first);
      s.scheduler.elapse(const Duration(milliseconds: 1));
      expect(s.game.current, isNot(first));
      expect(s.game.index, 1);
      expect(
        s.game.options.every((o) => o.state == QuizOptionState.idle),
        isTrue,
      );
    });

    test('choices are ignored while the right answer is shown', () {
      final s = _Setup();
      final asked = s.game.current;
      final right = s.correct;
      final picked = s.wrong.first;

      s.game
        ..choose(right.word)
        ..choose(picked.word);
      s.scheduler.elapse(_delay);

      expect(s.session.outcomeOf(asked!), isNotNull);
      expect(s.session.result.firstTry, 1);
      expect(s.session.result.wrongFirst, 0);
    });

    test('a word that is not an option is ignored', () {
      final s = _Setup(words: _words(6).sublist(0, 2), pool: _words(6));
      final notShown = _words(
        6,
      ).firstWhere((word) => !s.game.options.any((o) => o.word.id == word.id));

      s.game.choose(notShown);

      expect(s.session.result.wrongFirst, 0);
      expect(
        s.game.options.every((o) => o.state == QuizOptionState.idle),
        isTrue,
      );
    });
  });

  group('result', () {
    test('only the first choice counts', () {
      final s = _Setup();
      final firstWord = s.game.current!;
      s.game.choose(s.wrong.first.word);
      s.answerRight();
      final secondWord = s.game.current!;
      s.answerRight();

      final result = s.game.result;
      expect(s.session.outcomeOf(firstWord), WordOutcome.wrongFirst);
      expect(s.session.outcomeOf(secondWord), WordOutcome.firstTry);
      expect(result.firstTry, 1);
      expect(result.wrongFirst, 1);
      expect(result.missedWords, [firstWord]);
    });

    test('several wrong choices are still one wrong word', () {
      final s = _Setup();
      for (final option in s.wrong) {
        s.game.choose(option.word);
      }
      s.answerRight();

      expect(s.game.result.wrongFirst, 1);
      expect(s.game.result.firstTry, 0);
    });

    test('the counts can be read during the round', () {
      final s = _Setup();
      expect(s.game.firstTryCount, 0);
      expect(s.game.wrongFirstCount, 0);

      s.answerRight();
      s.game.choose(s.wrong.first.word);
      s.answerRight();
      s.answerRight();

      expect(s.game.firstTryCount, 2);
      expect(s.game.wrongFirstCount, 1);
    });

    test('the round is finished after the last right answer', () {
      final s = _Setup(count: 5);
      var questions = 0;

      while (!s.game.isFinished) {
        questions++;
        s.answerRight();
      }

      expect(questions, 5);
      expect(s.game.current, isNull);
      expect(s.game.options, isEmpty);
      expect(s.game.result.total, 5);
      expect(s.game.result.firstTry, 5);
    });
  });

  group('not enough words', () {
    test('three words are not playable and nothing throws', () {
      final s = _Setup(count: 3);

      expect(s.game.isPlayable, isFalse);
      expect(s.game.current, isNull);
      expect(s.game.options, isEmpty);
      s.game.choose(s.session.words.first);
      expect(s.session.result.firstTry, 0);
      expect(s.scheduler.pending, 0);
    });

    test('four words are playable', () {
      final s = _Setup(count: 4);

      expect(s.game.isPlayable, isTrue);
      expect(s.game.options.map((o) => o.word.id).toSet(), hasLength(4));
    });

    test('four words with a shared translation are not playable', () {
      final deck = [
        WordPair.fromCells(id: 'a', english: 'ticket', hungarian: 'jegy'),
        WordPair.fromCells(id: 'b', english: 'fare', hungarian: 'jegy'),
        ..._words(2),
      ];

      expect(_Setup(words: deck).game.isPlayable, isFalse);
    });

    test('an empty deck is finished at once', () {
      final s = _Setup(count: 0);

      expect(s.game.isFinished, isTrue);
      expect(s.game.current, isNull);
    });
  });

  group('lifecycle', () {
    test('listeners are told about every change', () {
      final s = _Setup();
      var calls = 0;
      s.game
        ..addListener(() => calls++)
        ..choose(s.wrong.first.word);
      expect(calls, 1);

      s.game.choose(s.correct.word);
      expect(calls, 2);
      s.scheduler.elapse(_delay);
      expect(calls, 3);
    });

    test('restart gives a new order and clears the outcomes', () {
      final s = _Setup();
      final before = s.session.words.map((w) => w.id).toList();
      s.game.choose(s.wrong.first.word);
      s.answerRight();

      s.game.restart();

      expect(s.game.index, 0);
      expect(s.game.isFinished, isFalse);
      expect(s.game.result.firstTry, 0);
      expect(s.game.result.wrongFirst, 0);
      expect(s.game.options, hasLength(4));
      expect(s.session.words.map((w) => w.id).toList(), isNot(before));
    });

    test('restart drops the pending step of the old round', () {
      final s = _Setup();
      s.game.choose(s.correct.word);

      s.game.restart();
      s.scheduler.elapse(_delay);

      expect(s.game.index, 0);
      expect(s.scheduler.pending, 0);
    });

    test('dispose cancels the pending step and ignores choices', () {
      final s = _Setup();
      s.game.choose(s.correct.word);

      s.game.dispose();
      s.scheduler.elapse(_delay);
      s.game.choose(s.wrong.first.word);

      expect(s.game.index, 0);
      expect(s.scheduler.pending, 0);
    });
  });
}
