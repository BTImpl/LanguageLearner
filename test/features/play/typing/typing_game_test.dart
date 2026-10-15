import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/play/typing/typing_game.dart';

import '../../../helpers/manual_scheduler.dart';

List<WordPair> _words(int count) => [
  for (var i = 0; i < count; i++)
    WordPair.fromCells(id: 'w$i', english: 'en$i', hungarian: 'hu$i'),
];

const _help = Duration(seconds: 3);

class _Setup {
  _Setup({
    int count = 5,
    List<WordPair>? words,
    PromptLanguage promptLanguage = PromptLanguage.english,
  }) {
    session = RoundSession(
      words: words ?? _words(count),
      promptLanguage: promptLanguage,
      random: Random(1),
    );
    game = TypingGame(session: session, schedule: scheduler.call);
  }

  final scheduler = ManualScheduler();
  late final RoundSession session;
  late final TypingGame game;

  WordPair get word => game.current!;

  /// The right answer to the current word.
  String get right => session.answerText(word);

  WordOutcome? get outcome => session.outcomeOf(word);

  /// Answers the current word right and goes on.
  void solve() {
    game
      ..submit(right)
      ..next();
  }
}

void main() {
  group('answering', () {
    test('asks the words of the round one by one', () {
      final s = _Setup(count: 3);
      final asked = <String>[];

      while (!s.game.isFinished) {
        asked.add(s.word.id);
        s.solve();
      }

      expect(asked, s.session.words.map((w) => w.id).toList());
      expect(s.game.current, isNull);
      expect(s.game.isFinished, isTrue);
    });

    test('a right answer solves the word and waits for next', () {
      final s = _Setup();
      final first = s.word;

      final result = s.game.submit(s.right);

      expect(result, SubmitResult.correct);
      expect(s.game.isSolved, isTrue);
      expect(s.game.feedback, TypingFeedback.correct);
      expect(s.game.current, first);
      expect(s.game.index, 0);
    });

    test('next moves on and clears the state', () {
      final s = _Setup();
      final first = s.word;
      s.game.submit(s.right);

      s.game.next();

      expect(s.game.current, isNot(first));
      expect(s.game.index, 1);
      expect(s.game.isSolved, isFalse);
      expect(s.game.feedback, TypingFeedback.none);
    });

    test('next does nothing before the word is solved', () {
      final s = _Setup();
      final first = s.word;

      s.game.next();
      s.game.submit('wrong');
      s.game.next();

      expect(s.game.current, first);
      expect(s.game.index, 0);
    });

    test('a wrong answer can be corrected as often as needed', () {
      final s = _Setup();
      final first = s.word;

      expect(s.game.submit('nope'), SubmitResult.wrong);
      expect(s.game.feedback, TypingFeedback.wrong);
      expect(s.game.isSolved, isFalse);
      expect(s.game.submit('still nope'), SubmitResult.wrong);
      expect(s.game.current, first);

      expect(s.game.submit(s.right), SubmitResult.correct);
      expect(s.game.feedback, TypingFeedback.correct);
    });

    test('the answer is compared like the matcher does', () {
      final s = _Setup();

      expect(
        s.game.submit('  ${s.right.toUpperCase()} '),
        SubmitResult.correct,
      );
    });

    test('every accepted answer is right', () {
      final ticket = WordPair.fromCells(
        id: 't',
        english: 'ticket',
        hungarian: 'jegy; menetjegy',
      );
      for (final answer in ['jegy', 'menetjegy']) {
        final s = _Setup(words: [ticket]);
        expect(s.game.submit(answer), SubmitResult.correct, reason: answer);
      }
    });

    test('a missing accent is a wrong answer', () {
      final passport = WordPair.fromCells(
        id: 'p',
        english: 'passport',
        hungarian: 'útlevél',
      );
      final s = _Setup(words: [passport]);

      expect(s.game.submit('utlevel'), SubmitResult.wrong);
      expect(s.game.submit('útlevél'), SubmitResult.correct);
    });

    test('an English answer is expected when the question is Hungarian', () {
      final s = _Setup(promptLanguage: PromptLanguage.hungarian);

      expect(s.game.submit(s.word.hungarian), SubmitResult.wrong);
      expect(s.game.submit(s.word.english), SubmitResult.correct);
    });

    test('an empty answer is ignored and is not an attempt', () {
      final s = _Setup();

      expect(s.game.submit(''), SubmitResult.ignored);
      expect(s.game.submit('   '), SubmitResult.ignored);

      expect(s.game.feedback, TypingFeedback.none);
      expect(s.outcome, isNull);
      expect(s.game.submit(s.right), SubmitResult.correct);
      expect(s.outcome, WordOutcome.firstTry);
    });

    test('an answer to a solved word is ignored', () {
      final s = _Setup();
      s.game.submit(s.right);

      expect(s.game.submit('nope'), SubmitResult.ignored);
      expect(s.game.feedback, TypingFeedback.correct);
      expect(s.outcome, WordOutcome.firstTry);
    });

    test('an answer after the last word is ignored', () {
      final s = _Setup(count: 1);
      s.solve();

      expect(s.game.submit('anything'), SubmitResult.ignored);
      s.game.requestHelp();
      expect(s.game.helpVisible, isFalse);
    });
  });

  group('outcome', () {
    test('right without help at the first attempt is firstTry', () {
      final s = _Setup();
      s.game.submit(s.right);

      expect(s.outcome, WordOutcome.firstTry);
    });

    test('a wrong first attempt is wrongFirst, even if corrected', () {
      final s = _Setup();
      s.game
        ..submit('nope')
        ..submit(s.right);

      expect(s.outcome, WordOutcome.wrongFirst);
    });

    test('help before the right answer is withHelp', () {
      final s = _Setup();
      s.game
        ..requestHelp()
        ..submit(s.right);

      expect(s.outcome, WordOutcome.withHelp);
    });

    test('a wrong first attempt stays wrongFirst when help follows', () {
      final s = _Setup();
      s.game
        ..submit('nope')
        ..requestHelp()
        ..submit(s.right);

      expect(s.outcome, WordOutcome.wrongFirst);
    });

    test('help asked before a wrong attempt stays withHelp', () {
      final s = _Setup();
      s.game
        ..requestHelp()
        ..submit('nope')
        ..submit(s.right);

      expect(s.outcome, WordOutcome.withHelp);
    });

    test('the counts and lists cover all three categories', () {
      final s = _Setup(count: 4);
      final order = s.session.words;
      // 0: first try, 1: with help, 2: wrong first, 3: first try.
      s.solve();
      s.game.requestHelp();
      s.solve();
      s.game.submit('nope');
      s.solve();
      s.solve();

      final result = s.game.result;
      expect(result.total, 4);
      expect(result.firstTry, 2);
      expect(result.withHelp, 1);
      expect(result.wrongFirst, 1);
      expect(result.helpedWords, [order[1]]);
      expect(result.missedWords, [order[2]]);
    });
  });

  group('help', () {
    test('shows the right answer for three seconds', () {
      final s = _Setup();
      expect(s.game.helpVisible, isFalse);
      expect(s.game.helpText, isNull);

      s.game.requestHelp();

      expect(s.game.helpVisible, isTrue);
      expect(s.game.helpText, s.right);
      s.scheduler.elapse(const Duration(milliseconds: 2999));
      expect(s.game.helpVisible, isTrue);
      s.scheduler.elapse(const Duration(milliseconds: 1));
      expect(s.game.helpVisible, isFalse);
      expect(s.game.helpText, isNull);
    });

    test('the duration is a parameter', () {
      final session = RoundSession(
        words: _words(2),
        promptLanguage: PromptLanguage.english,
        random: Random(1),
      );
      final scheduler = ManualScheduler();
      final game = TypingGame(
        session: session,
        schedule: scheduler.call,
        helpDuration: const Duration(milliseconds: 500),
      )..requestHelp();

      scheduler.elapse(const Duration(milliseconds: 500));

      expect(game.helpVisible, isFalse);
    });

    test('can be asked for again and again', () {
      final s = _Setup();
      s.game.requestHelp();
      s.scheduler.elapse(_help);
      expect(s.game.helpVisible, isFalse);

      s.game.requestHelp();

      expect(s.game.helpVisible, isTrue);
      s.scheduler.elapse(_help);
      expect(s.game.helpVisible, isFalse);
    });

    test('asking again while it shows starts the time over', () {
      final s = _Setup();
      s.game.requestHelp();
      s.scheduler.elapse(const Duration(seconds: 2));

      s.game.requestHelp();
      s.scheduler.elapse(const Duration(seconds: 2));

      expect(s.game.helpVisible, isTrue);
      s.scheduler.elapse(const Duration(seconds: 1));
      expect(s.game.helpVisible, isFalse);
      expect(s.scheduler.pending, 0);
    });

    test('stays while a wrong answer is sent', () {
      final s = _Setup();
      s.game.requestHelp();

      s.game.submit('nope');

      expect(s.game.helpVisible, isTrue);
    });

    test('goes away when the word is solved', () {
      final s = _Setup();
      s.game
        ..requestHelp()
        ..submit(s.right);

      expect(s.game.helpVisible, isFalse);
      expect(s.scheduler.pending, 0);
    });

    test('cannot be asked for once the word is solved', () {
      final s = _Setup();
      s.game.submit(s.right);

      s.game.requestHelp();

      expect(s.game.helpVisible, isFalse);
      expect(s.outcome, WordOutcome.firstTry);
    });
  });

  group('lifecycle', () {
    test('listeners are told about every change', () {
      final s = _Setup();
      var calls = 0;
      s.game.addListener(() => calls++);

      s.game.submit('nope');
      expect(calls, 1);
      s.game.requestHelp();
      expect(calls, 2);
      s.scheduler.elapse(_help);
      expect(calls, 3);
      s.game.submit(s.right);
      expect(calls, 4);
      s.game.next();
      expect(calls, 5);
    });

    test('ignored calls tell nobody', () {
      final s = _Setup();
      var calls = 0;
      s.game
        ..addListener(() => calls++)
        ..submit('')
        ..next();

      expect(calls, 0);
    });

    test('restart gives a new order and clears everything', () {
      final s = _Setup(count: 8);
      final before = s.session.words.map((w) => w.id).toList();
      s.game
        ..requestHelp()
        ..submit('nope');
      s.solve();

      s.game.restart();

      expect(s.game.index, 0);
      expect(s.game.isSolved, isFalse);
      expect(s.game.helpVisible, isFalse);
      expect(s.game.feedback, TypingFeedback.none);
      expect(s.game.result.firstTry, 0);
      expect(s.game.result.withHelp, 0);
      expect(s.session.words.map((w) => w.id).toList(), isNot(before));
      expect(s.scheduler.pending, 0);
    });

    test('dispose cancels the help and ignores everything', () {
      final s = _Setup();
      s.game.requestHelp();

      s.game.dispose();
      s.scheduler.elapse(_help);

      expect(s.scheduler.pending, 0);
      expect(s.game.submit(s.right), SubmitResult.ignored);
      s.game.requestHelp();
      expect(s.game.helpVisible, isFalse);
    });

    test('an empty deck is finished at once', () {
      final s = _Setup(count: 0);

      expect(s.game.isFinished, isTrue);
      expect(s.game.current, isNull);
      expect(s.game.submit('x'), SubmitResult.ignored);
    });
  });
}
