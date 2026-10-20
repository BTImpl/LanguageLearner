import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/mix/mix_game.dart';
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
  _Setup({int count = 4, int? maxAttempts}) {
    session = RoundSession(
      words: _words(count),
      promptLanguage: PromptLanguage.english,
      random: Random(1),
    );
    game = TypingGame(
      session: session,
      schedule: scheduler.call,
      maxAttempts: maxAttempts ?? TypingGame.defaultMaxAttempts,
    );
  }

  final scheduler = ManualScheduler();
  late final RoundSession session;
  late final TypingGame game;

  WordPair get word => game.current!;
  String get right => session.answerText(word);
  WordOutcome? get outcome => session.outcomeOf(word);

  void failTimes(int times) {
    for (var i = 0; i < times; i++) {
      game.submit('nope$i');
    }
  }
}

void main() {
  group('attempts', () {
    test('three wrong answers are allowed by default', () {
      final s = _Setup();

      expect(s.game.maxAttempts, 3);
      expect(s.game.attemptsLeft, 3);
      expect(s.game.wrongAttempts, 0);
    });

    test('every wrong answer uses one attempt', () {
      final s = _Setup();

      s.game.submit('nope');
      expect(s.game.wrongAttempts, 1);
      expect(s.game.attemptsLeft, 2);
      expect(s.game.isGivenUp, isFalse);

      s.game.submit('nope2');
      expect(s.game.wrongAttempts, 2);
      expect(s.game.attemptsLeft, 1);
      expect(s.game.isGivenUp, isFalse);
    });

    test('an empty answer does not use an attempt', () {
      final s = _Setup();

      s.game
        ..submit('')
        ..submit('   ');

      expect(s.game.wrongAttempts, 0);
    });

    test('a hidden character answer is just a wrong answer for the word', () {
      final s = _Setup();

      expect(s.game.submit('x'), SubmitResult.wrong);
      expect(s.game.wrongAttempts, 1);
    });

    test('the last attempt is announced after the second wrong answer', () {
      final s = _Setup();
      expect(s.game.isLastAttempt, isFalse);

      s.game.submit('nope');
      expect(s.game.isLastAttempt, isFalse);

      s.game.submit('nope2');
      expect(s.game.isLastAttempt, isTrue);
    });

    test('with one attempt there is no last attempt warning', () {
      final s = _Setup(maxAttempts: 1);

      expect(s.game.isLastAttempt, isFalse);
      s.game.submit('nope');
      expect(s.game.isLastAttempt, isFalse);
    });

    test('the wrong answers of one word do not count for the next', () {
      final s = _Setup();
      s.failTimes(2);
      s.game
        ..submit(s.right)
        ..next();

      expect(s.game.wrongAttempts, 0);
      expect(s.game.attemptsLeft, 3);
      expect(s.game.isLastAttempt, isFalse);
    });

    test('a right answer before the limit is solved as usual', () {
      final s = _Setup();
      s.failTimes(2);

      expect(s.game.submit(s.right), SubmitResult.correct);

      expect(s.game.isSolved, isTrue);
      expect(s.game.isGivenUp, isFalse);
      expect(s.game.isLastAttempt, isFalse);
      s.scheduler.elapse(_help * 2);
      expect(s.game.index, 0, reason: 'only next() moves on');
    });
  });

  group('giving up', () {
    test('the last wrong answer shows the right answer', () {
      final s = _Setup();
      final asked = s.word;

      s.failTimes(3);

      expect(s.game.isGivenUp, isTrue);
      expect(s.game.helpVisible, isTrue);
      expect(s.game.helpText, s.session.answerText(asked));
      expect(s.game.current, asked);
      expect(s.game.isSolved, isFalse);
      expect(s.game.index, 0);
    });

    test('it moves on by itself after the help time', () {
      final s = _Setup();
      final asked = s.word;
      s.failTimes(3);

      s.scheduler.elapse(_help - const Duration(milliseconds: 1));
      expect(s.game.current, asked);

      s.scheduler.elapse(const Duration(milliseconds: 1));

      expect(s.game.index, 1);
      expect(s.game.current, isNot(asked));
      expect(s.game.isGivenUp, isFalse);
      expect(s.game.helpVisible, isFalse);
      expect(s.game.wrongAttempts, 0);
      expect(s.game.feedback, TypingFeedback.none);
    });

    test('the listeners hear both the giving up and the moving on', () {
      final s = _Setup();
      var calls = 0;
      s.game.addListener(() => calls++);

      s.failTimes(3);
      final afterGivingUp = calls;
      expect(afterGivingUp, 3);

      s.scheduler.elapse(_help);
      expect(calls, afterGivingUp + 1);
    });

    test('nothing can be submitted or asked while the answer shows', () {
      final s = _Setup();
      s.failTimes(3);

      expect(s.game.submit(s.right), SubmitResult.ignored);
      expect(s.game.submit('nope'), SubmitResult.ignored);
      s.game.requestHelp();
      s.game.next();

      expect(s.game.isSolved, isFalse);
      expect(s.game.wrongAttempts, 3);
      expect(s.game.index, 0);
      // The help is not restarted by the ignored request.
      s.scheduler.elapse(_help);
      expect(s.game.index, 1);
    });

    test('the word counts as wrong at the first attempt', () {
      final s = _Setup();
      final asked = s.word;
      s.failTimes(3);
      s.scheduler.elapse(_help);

      final result = s.game.result;
      expect(result.wrongFirst, 1);
      expect(result.missedWords, [asked]);
      expect(result.outcomes[asked.id], WordOutcome.wrongFirst);
    });

    test('a word that was helped first stays withHelp', () {
      final s = _Setup();
      final asked = s.word;
      s.game.requestHelp();
      s.failTimes(3);
      s.scheduler.elapse(_help);

      expect(s.game.result.outcomes[asked.id], WordOutcome.withHelp);
      expect(s.game.index, 1);
    });

    test('the right answer shown by giving up does not count as help', () {
      final s = _Setup();
      final asked = s.word;
      s.failTimes(3);
      s.scheduler.elapse(_help);

      expect(s.game.result.helpedWords, isNot(contains(asked)));
      expect(s.game.result.withHelp, 0);
    });

    test('the next word is asked normally after giving up', () {
      final s = _Setup();
      s.failTimes(3);
      s.scheduler.elapse(_help);

      expect(s.game.submit(s.right), SubmitResult.correct);
      expect(s.outcome, WordOutcome.firstTry);
    });

    test('giving up on the last word finishes the round', () {
      final s = _Setup(count: 2);
      s.game
        ..submit(s.right)
        ..next();
      var finishedSeen = false;
      s.game.addListener(
        () => finishedSeen = finishedSeen || s.game.isFinished,
      );

      s.failTimes(3);
      s.scheduler.elapse(_help);

      expect(s.game.isFinished, isTrue);
      expect(finishedSeen, isTrue);
      expect(s.game.result.total, 2);
      expect(s.game.result.firstTry, 1);
      expect(s.game.result.wrongFirst, 1);
    });

    test('with one attempt the first wrong answer gives up', () {
      final s = _Setup(maxAttempts: 1);

      s.game.submit('nope');

      expect(s.game.isGivenUp, isTrue);
      s.scheduler.elapse(_help);
      expect(s.game.index, 1);
    });

    test('with ten attempts it gives up at the tenth wrong answer', () {
      final s = _Setup(maxAttempts: 10);

      s.failTimes(9);
      expect(s.game.isGivenUp, isFalse);
      expect(s.game.isLastAttempt, isTrue);

      s.game.submit('nope');
      expect(s.game.isGivenUp, isTrue);
    });

    test('disposing cancels the moving on', () {
      final s = _Setup();
      s.failTimes(3);

      s.game.dispose();

      expect(s.scheduler.pending, 0);
      s.scheduler.elapse(_help);
      expect(s.game.index, 0);
    });

    test('restarting forgets the attempts and the pending move', () {
      final s = _Setup();
      s.failTimes(3);

      s.game.restart();

      expect(s.game.isGivenUp, isFalse);
      expect(s.game.wrongAttempts, 0);
      expect(s.game.helpVisible, isFalse);
      expect(s.scheduler.pending, 0);
      s.scheduler.elapse(_help);
      expect(s.game.index, 0);
    });

    test('it refuses a game without attempts', () {
      final session = RoundSession(
        words: _words(2),
        promptLanguage: PromptLanguage.english,
      );

      expect(
        () => TypingGame(session: session, maxAttempts: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('in the Mix mode', () {
    /// A mix game whose first step is typing.
    (MixGame, RoundSession, ManualScheduler) typingMix(int attempts) {
      for (var seed = 0; seed < 200; seed++) {
        final scheduler = ManualScheduler();
        final session = RoundSession(
          words: _words(12),
          promptLanguage: PromptLanguage.english,
          random: Random(seed),
        );
        final mix = MixGame(
          session: session,
          pairsPerPage: 5,
          typingAttempts: attempts,
          random: Random(seed),
          schedule: scheduler.call,
        );
        if (mix.stepType == MixStepType.typing) {
          return (mix, session, scheduler);
        }
        mix.dispose();
      }
      throw StateError('No seed starts with a typing step.');
    }

    test('a typing step gives up after the set number of wrong answers', () {
      final (mix, session, scheduler) = typingMix(2);
      final asked = session.current!;

      mix.typing!
        ..submit('nope')
        ..submit('nope2');

      expect(mix.typing!.isGivenUp, isTrue);
      scheduler.elapse(_help);

      expect(session.index, 1);
      expect(session.current, isNot(asked));
      expect(session.outcomeOf(asked), WordOutcome.wrongFirst);
      mix.dispose();
    });

    test('the default is three wrong answers', () {
      final (mix, session, scheduler) = typingMix(
        TypingGame.defaultMaxAttempts,
      );

      mix.typing!
        ..submit('nope')
        ..submit('nope2');
      expect(mix.typing!.isGivenUp, isFalse);

      mix.typing!.submit('nope3');
      expect(mix.typing!.isGivenUp, isTrue);
      scheduler.elapse(_help);
      expect(session.index, 1);
      mix.dispose();
    });
  });
}
