import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/matching/match_tile.dart';
import 'package:languagelearner/features/play/mix/mix_game.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/play/typing/typing_game.dart';

import '../../../helpers/manual_scheduler.dart';

List<WordPair> _words(int count) => [
  for (var i = 0; i < count; i++)
    WordPair.fromCells(id: 'w$i', english: 'en$i', hungarian: 'hu$i'),
];

const _delay = Duration(milliseconds: 400);

/// What a step did, as seen from outside.
typedef _Step = ({MixStepType type, int start, List<String> ids});

class _Setup {
  _Setup({
    int seed = 1,
    int count = 12,
    int pairsPerPage = 5,
    List<WordPair>? words,
    PromptLanguage promptLanguage = PromptLanguage.english,
  }) {
    session = RoundSession(
      words: words ?? _words(count),
      promptLanguage: promptLanguage,
      random: Random(seed),
    );
    mix = MixGame(
      session: session,
      pairsPerPage: pairsPerPage,
      random: Random(seed),
      schedule: scheduler.call,
    );
  }

  final scheduler = ManualScheduler();
  late final RoundSession session;
  late final MixGame mix;

  /// The words the current step is about.
  List<String> get stepIds => switch (mix.stepType!) {
    MixStepType.typing => [mix.typing!.current!.id],
    MixStepType.quiz => [mix.quiz!.current!.id],
    MixStepType.matching => [
      for (final tile in mix.matching!.englishTiles) tile.word.id,
    ],
  };

  /// Solves the current step with right answers only.
  void solveStep() {
    switch (mix.stepType!) {
      case MixStepType.typing:
        final game = mix.typing!;
        game
          ..submit(session.answerText(game.current!))
          ..next();
      case MixStepType.quiz:
        final game = mix.quiz!;
        game.choose(game.options.firstWhere((o) => o.isCorrect).word);
        scheduler.elapse(_delay);
      case MixStepType.matching:
        final game = mix.matching!;
        for (final tile in List.of(game.englishTiles)) {
          game
            ..tap(tile.word, MatchSide.english)
            ..tap(tile.word, MatchSide.hungarian);
        }
        scheduler.elapse(_delay);
    }
  }

  /// Plays the whole round with right answers and reports every step.
  List<_Step> solveAll() {
    final steps = <_Step>[];
    while (!mix.isFinished) {
      steps.add((type: mix.stepType!, start: mix.index, ids: stepIds));
      solveStep();
    }
    return steps;
  }
}

void main() {
  group('the draw', () {
    test('every word is used exactly once', () {
      for (var seed = 1; seed <= 30; seed++) {
        final s = _Setup(seed: seed);

        final steps = s.solveAll();

        final ids = [for (final step in steps) ...step.ids];
        expect(ids, hasLength(12), reason: 'seed $seed');
        expect(ids.toSet(), hasLength(12), reason: 'seed $seed');
        expect(s.mix.isFinished, isTrue);
        expect(s.mix.stepType, isNull);
      }
    });

    test('the same seed gives the same steps', () {
      List<MixStepType> types(int seed) => [
        for (final step in _Setup(seed: seed).solveAll()) step.type,
      ];

      expect(types(7), types(7));
    });

    test('all three kinds of step come up', () {
      final seen = <MixStepType>{};
      for (var seed = 1; seed <= 30; seed++) {
        seen.addAll(_Setup(seed: seed).solveAll().map((step) => step.type));
      }

      expect(seen, MixStepType.values.toSet());
    });

    test('there are never two matching steps in a row', () {
      for (var seed = 1; seed <= 100; seed++) {
        final types = [
          for (final step in _Setup(seed: seed).solveAll()) step.type,
        ];
        for (var i = 1; i < types.length; i++) {
          expect(
            types[i] == MixStepType.matching &&
                types[i - 1] == MixStepType.matching,
            isFalse,
            reason: 'seed $seed, steps ${i - 1} and $i',
          );
        }
      }
    });
  });

  group('matching steps', () {
    test('use as many words as they show pairs', () {
      for (var seed = 1; seed <= 50; seed++) {
        final steps = _Setup(seed: seed).solveAll();
        for (final step in steps) {
          switch (step.type) {
            case MixStepType.matching:
              expect(
                step.ids,
                hasLength(min(5, 12 - step.start)),
                reason: 'seed $seed',
              );
            case MixStepType.typing || MixStepType.quiz:
              expect(step.ids, hasLength(1));
          }
        }
      }
    });

    test('the counter jumps by the number of pairs', () {
      for (var seed = 1; seed <= 50; seed++) {
        final s = _Setup(seed: seed);
        while (!s.mix.isFinished) {
          final before = s.mix.index;
          final size = s.stepIds.length;
          s.solveStep();
          expect(s.mix.index, before + size, reason: 'seed $seed');
        }
      }
    });

    test('the pairs setting is followed', () {
      final sizes = <int>{};
      for (var seed = 1; seed <= 200; seed++) {
        final s = _Setup(seed: seed, count: 20, pairsPerPage: 3);
        for (final step in s.solveAll()) {
          if (step.type == MixStepType.matching) {
            sizes.add(step.ids.length);
          }
        }
      }

      // Three pairs, or two when only two words were left.
      expect(sizes, contains(3));
      expect(sizes.difference({2, 3}), isEmpty);
    });

    test('a smaller last page uses up the rest', () {
      // Three words left and five pairs per page: the page has three pairs.
      final seed = [for (var seed = 1; seed <= 200; seed++) seed].firstWhere(
        (seed) =>
            _Setup(seed: seed, count: 3).mix.stepType == MixStepType.matching,
      );
      final s = _Setup(seed: seed, count: 3);

      expect(s.mix.matching!.englishTiles, hasLength(3));
      s.solveStep();

      expect(s.mix.isFinished, isTrue);
      expect(s.mix.completedSteps, [(type: MixStepType.matching, words: 3)]);
    });

    test('are not drawn when only one word is left', () {
      for (var seed = 1; seed <= 100; seed++) {
        final s = _Setup(seed: seed);
        for (final step in s.solveAll()) {
          if (step.type == MixStepType.matching) {
            expect(12 - step.start, greaterThanOrEqualTo(2));
          }
        }
      }
    });

    test('a one-word deck is only typing or quiz', () {
      for (var seed = 1; seed <= 50; seed++) {
        final s = _Setup(seed: seed, count: 1);

        expect(s.mix.stepType, MixStepType.typing, reason: 'seed $seed');
      }
    });
  });

  group('quiz steps', () {
    test('are not drawn when the deck has fewer than four words', () {
      final seen = <MixStepType>{};
      for (var seed = 1; seed <= 100; seed++) {
        seen.addAll(_Setup(seed: seed, count: 3).solveAll().map((s) => s.type));
      }

      expect(seen, {MixStepType.typing, MixStepType.matching});
    });

    test('are drawn when words only share a translation', () {
      final deck = [
        WordPair.fromCells(id: 'a', english: 'ticket', hungarian: 'jegy'),
        WordPair.fromCells(id: 'b', english: 'fare', hungarian: 'jegy'),
        ..._words(4),
      ];
      final seen = <MixStepType>{};
      for (var seed = 1; seed <= 50; seed++) {
        seen.addAll(
          _Setup(seed: seed, words: deck).solveAll().map((s) => s.type),
        );
      }

      expect(seen, contains(MixStepType.quiz));
    });

    test('are not drawn when a word cannot get three wrong answers', () {
      final deck = [
        WordPair.fromCells(id: 'a', english: 'ticket', hungarian: 'jegy'),
        WordPair.fromCells(id: 'b', english: 'fare', hungarian: 'jegy'),
        ..._words(2),
      ];
      final seen = <MixStepType>{};
      for (var seed = 1; seed <= 100; seed++) {
        seen.addAll(
          _Setup(seed: seed, words: deck).solveAll().map((s) => s.type),
        );
      }

      expect(seen, isNot(contains(MixStepType.quiz)));
    });

    test('draw their wrong answers from the whole deck', () {
      var usedSolvedWord = false;
      for (var seed = 1; seed <= 30 && !usedSolvedWord; seed++) {
        final s = _Setup(seed: seed);
        final solved = <String>{};
        while (!s.mix.isFinished) {
          if (s.mix.stepType == MixStepType.quiz) {
            final options = s.mix.quiz!.options;
            expect(options, hasLength(4));
            usedSolvedWord =
                usedSolvedWord ||
                options.any((o) => solved.contains(o.word.id));
          }
          solved.addAll(s.stepIds);
          s.solveStep();
        }
      }

      expect(usedSolvedWord, isTrue);
    });
  });

  group('result', () {
    test('the steps of all kinds add up in one result', () {
      for (var seed = 1; seed <= 20; seed++) {
        final s = _Setup(seed: seed);

        s.solveAll();

        final result = s.mix.result;
        expect(result.total, 12);
        expect(result.firstTry, 12, reason: 'seed $seed');
        expect(result.withHelp, 0);
        expect(result.wrongFirst, 0);
      }
    });

    test('a wrong typing answer is wrongFirst', () {
      final s = _firstOfType(MixStepType.typing);
      final game = s.mix.typing!;
      final asked = game.current!;

      game
        ..submit('nope')
        ..submit(s.session.answerText(asked))
        ..next();

      expect(s.session.outcomeOf(asked), WordOutcome.wrongFirst);
      expect(s.mix.index, 1);
    });

    test('help in a typing step is withHelp', () {
      final s = _firstOfType(MixStepType.typing);
      final game = s.mix.typing!;
      final asked = game.current!;

      game
        ..requestHelp()
        ..submit(s.session.answerText(asked))
        ..next();

      expect(s.session.outcomeOf(asked), WordOutcome.withHelp);
      expect(s.mix.result.withHelp, 1);
    });

    test('a wrong quiz answer is wrongFirst', () {
      final s = _firstOfType(MixStepType.quiz);
      final game = s.mix.quiz!;
      final asked = game.current!;

      game
        ..choose(game.options.firstWhere((o) => !o.isCorrect).word)
        ..choose(game.options.firstWhere((o) => o.isCorrect).word);
      s.scheduler.elapse(_delay);

      expect(s.session.outcomeOf(asked), WordOutcome.wrongFirst);
      expect(s.mix.index, 1);
    });

    test('a wrong pair counts in the matching extras', () {
      final s = _firstOfType(MixStepType.matching);
      final game = s.mix.matching!;
      final [a, b, ...] = [for (final t in game.englishTiles) t.word];

      game
        ..tap(a, MatchSide.english)
        ..tap(b, MatchSide.hungarian);
      s.scheduler.elapse(const Duration(seconds: 1));
      s.solveStep();

      final result = s.mix.result;
      expect(result.extra(RoundCounters.wrongPairs), 1);
      expect(result.wrongFirst, 2);
      expect(s.session.outcomeOf(a), WordOutcome.wrongFirst);
      expect(s.session.outcomeOf(b), WordOutcome.wrongFirst);
    });
  });

  group('steps', () {
    test('the next step starts when a step is over', () {
      final s = _Setup();
      final first = s.mix.stepNumber;
      var calls = 0;
      s.mix.addListener(() => calls++);

      s.solveStep();

      expect(first, 1);
      expect(s.mix.stepNumber, 2);
      expect(calls, greaterThan(0));
      expect(s.mix.completedSteps, hasLength(1));
    });

    test('only the game of the current kind exists', () {
      final s = _Setup();
      while (!s.mix.isFinished) {
        final games = [s.mix.typing, s.mix.quiz, s.mix.matching];
        expect(games.where((g) => g != null), hasLength(1));
        s.solveStep();
      }

      expect(s.mix.typing, isNull);
      expect(s.mix.quiz, isNull);
      expect(s.mix.matching, isNull);
    });

    test('the finished steps use up all the words', () {
      final s = _Setup();

      s.solveAll();

      final used = s.mix.completedSteps.fold<int>(
        0,
        (sum, step) => sum + step.words,
      );
      expect(used, 12);
    });
  });

  group('direction', () {
    test('typing and quiz steps draw both directions, matching none', () {
      final seen = <MixStepType, Set<PromptLanguage>>{
        for (final type in MixStepType.values) type: {},
      };
      for (var seed = 1; seed <= 30; seed++) {
        final s = _Setup(seed: seed);
        while (!s.mix.isFinished) {
          final language = s.mix.stepPromptLanguage;
          if (s.mix.stepType == MixStepType.matching) {
            expect(language, isNull, reason: 'seed $seed');
          } else {
            expect(language, isNotNull, reason: 'seed $seed');
            seen[s.mix.stepType!]!.add(language!);
          }
          s.solveStep();
        }
      }

      expect(seen[MixStepType.typing], PromptLanguage.values.toSet());
      expect(seen[MixStepType.quiz], PromptLanguage.values.toSet());
      expect(seen[MixStepType.matching], isEmpty);
    });

    test('the draw is the same whatever the setting of the student is', () {
      List<(MixStepType, PromptLanguage?)> draw(
        int seed,
        PromptLanguage setting,
      ) {
        final s = _Setup(seed: seed, promptLanguage: setting);
        final steps = <(MixStepType, PromptLanguage?)>[];
        while (!s.mix.isFinished) {
          steps.add((s.mix.stepType!, s.mix.stepPromptLanguage));
          s.solveStep();
        }
        return steps;
      }

      for (var seed = 1; seed <= 20; seed++) {
        expect(
          draw(seed, PromptLanguage.hungarian),
          draw(seed, PromptLanguage.english),
          reason: 'seed $seed',
        );
      }
    });

    test('the direction belongs to the step, so a round mixes them', () {
      var mixed = false;
      for (var seed = 1; seed <= 30 && !mixed; seed++) {
        final s = _Setup(seed: seed);
        final languages = <PromptLanguage>{};
        while (!s.mix.isFinished) {
          final language = s.mix.stepPromptLanguage;
          if (language != null) {
            languages.add(language);
          }
          s.solveStep();
        }
        mixed = languages.length == 2;
      }

      expect(mixed, isTrue);
    });

    test('a Hungarian typing question wants the English answer', () {
      final s = _firstStep(MixStepType.typing, PromptLanguage.hungarian);
      final game = s.mix.typing!;
      final asked = game.current!;

      expect(s.session.promptText(asked), asked.hungarian);
      expect(game.submit(asked.hungarian), SubmitResult.wrong);
      expect(game.submit(asked.english), SubmitResult.correct);
      game.next();

      expect(s.session.outcomeOf(asked), WordOutcome.wrongFirst);
      expect(s.mix.index, 1);
    });

    test('an English typing question wants the Hungarian answer', () {
      final s = _firstStep(MixStepType.typing, PromptLanguage.english);
      final game = s.mix.typing!;
      final asked = game.current!;

      expect(s.session.promptText(asked), asked.english);
      expect(game.submit(asked.english), SubmitResult.wrong);
      expect(game.submit(asked.hungarian), SubmitResult.correct);
    });

    test('the help shows the answer of the drawn direction', () {
      final s = _firstStep(MixStepType.typing, PromptLanguage.hungarian);
      final game = s.mix.typing!;

      game.requestHelp();

      expect(game.helpText, game.current!.english);
    });

    test('a Hungarian quiz question has English answers', () {
      final s = _firstStep(MixStepType.quiz, PromptLanguage.hungarian);
      final game = s.mix.quiz!;
      final asked = game.current!;

      expect(s.session.promptText(asked), asked.hungarian);
      expect(game.options, hasLength(4));
      expect(game.options.every((o) => o.text.startsWith('en')), isTrue);
      expect(game.options.singleWhere((o) => o.isCorrect).text, asked.english);
    });

    test('an English quiz question has Hungarian answers', () {
      final s = _firstStep(MixStepType.quiz, PromptLanguage.english);
      final game = s.mix.quiz!;
      final asked = game.current!;

      expect(s.session.promptText(asked), asked.english);
      expect(game.options.every((o) => o.text.startsWith('hu')), isTrue);
      expect(
        game.options.singleWhere((o) => o.isCorrect).text,
        asked.hungarian,
      );
    });

    test('the direction stays with the word after its step', () {
      final s = _firstStep(MixStepType.typing, PromptLanguage.hungarian);
      final asked = s.mix.typing!.current!;

      s.solveStep();

      expect(s.session.promptLanguageOf(asked), PromptLanguage.hungarian);
      expect(s.session.promptText(asked), asked.hungarian);
      expect(s.session.answerText(asked), asked.english);
    });

    test('a restart draws the directions again', () {
      final s = _firstStep(MixStepType.typing, PromptLanguage.hungarian);
      final asked = s.mix.typing!.current!;
      s.solveStep();

      s.mix.restart();

      // The old direction of the word is forgotten; the first step of the new
      // round has a direction of its own.
      final current = switch (s.mix.stepType!) {
        MixStepType.typing => s.mix.typing!.current,
        MixStepType.quiz => s.mix.quiz!.current,
        MixStepType.matching => null,
      };
      if (current != null) {
        expect(s.session.promptLanguageOf(current), s.mix.stepPromptLanguage);
      }
      if (current == null || current.id != asked.id) {
        expect(s.session.promptLanguageOf(asked), PromptLanguage.english);
      }
    });

    test('quiz is not drawn when one direction lacks wrong answers', () {
      // Three Hungarian texts only: an English question has just two wrong
      // Hungarian answers, so the quiz could not always be played.
      final deck = [
        for (var i = 0; i < 6; i++)
          WordPair.fromCells(
            id: 'w$i',
            english: 'en$i',
            hungarian: 'hu${i % 3}',
          ),
      ];
      final seen = <MixStepType>{};
      for (var seed = 1; seed <= 100; seed++) {
        seen.addAll(
          _Setup(seed: seed, words: deck).solveAll().map((s) => s.type),
        );
      }

      expect(seen, isNot(contains(MixStepType.quiz)));
      expect(seen, contains(MixStepType.typing));
    });
  });

  group('lifecycle', () {
    test('restart starts a new round with a new order', () {
      final s = _Setup();
      final before = s.session.words.map((w) => w.id).toList();
      s.solveStep();

      s.mix.restart();

      expect(s.mix.index, 0);
      expect(s.mix.isFinished, isFalse);
      expect(s.mix.completedSteps, isEmpty);
      expect(s.mix.result.firstTry, 0);
      expect(s.mix.stepType, isNotNull);
      expect(s.session.words.map((w) => w.id).toList(), isNot(before));
    });

    test('restart works after a finished round too', () {
      final s = _Setup();
      s.solveAll();

      s.mix.restart();

      expect(s.mix.isFinished, isFalse);
      expect(s.solveAll(), isNotEmpty);
      expect(s.mix.isFinished, isTrue);
    });

    test('dispose cancels everything', () {
      final s = _firstOfType(MixStepType.quiz);
      final game = s.mix.quiz!;
      game.choose(game.options.firstWhere((o) => o.isCorrect).word);

      s.mix.dispose();
      s.scheduler.elapse(_delay);

      expect(s.scheduler.pending, 0);
      expect(s.mix.index, 0);
      expect(s.mix.stepType, isNull);
    });

    test('an empty deck has no step', () {
      final s = _Setup(count: 0);

      expect(s.mix.isFinished, isTrue);
      expect(s.mix.stepType, isNull);
    });
  });
}

/// A setup whose first step is [type] (typing or quiz) and whose question is
/// asked in [question].
_Setup _firstStep(MixStepType type, PromptLanguage question) {
  for (var seed = 1; seed <= 500; seed++) {
    final s = _Setup(seed: seed);
    if (s.mix.stepType == type && s.mix.stepPromptLanguage == question) {
      return s;
    }
  }
  throw StateError('No seed starts with $type asking in $question.');
}

/// A setup whose first step is [type].
_Setup _firstOfType(MixStepType type) {
  for (var seed = 1; seed <= 500; seed++) {
    final s = _Setup(seed: seed);
    if (s.mix.stepType == type) {
      return s;
    }
  }
  throw StateError('No seed starts with $type.');
}
