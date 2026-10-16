import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/data/fake_word_repository.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/features/play/matching/match_tile.dart';
import 'package:languagelearner/features/play/matching/matching_content.dart';
import 'package:languagelearner/features/play/mix/mix_screen.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/quiz/quiz_content.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_screen.dart';
import 'package:languagelearner/features/play/widgets/question_card.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';

import '../../../helpers/fake_tts_service.dart';

class _Harness {
  _Harness(this.router, this.words);

  final GoRouter router;

  /// The words in the order of the round.
  final List<WordPair> words;

  String get path => router.routerDelegate.currentConfiguration.uri.path;
}

Future<_Harness> _open(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  PromptLanguage promptLanguage = PromptLanguage.english,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final deck = (await FakeWordRepository().getDecks()).first;
  final words = RoundSession.shuffled(deck.words, Random(1));
  final router = createAppRouter();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        appLocaleProvider.overrideWithValue(locale),
        roundRandomProvider.overrideWithValue(Random(1)),
        ttsServiceProvider.overrideWithValue(FakeTtsService()),
        initialSettingsProvider.overrideWithValue(
          AppSettings(promptLanguage: promptLanguage),
        ),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  router.go(AppRoutes.play(PlayMode.mix));
  await tester.pumpAndSettle();
  return _Harness(router, words);
}

Finder get _field => find.byType(TextField);

/// The text of the question card, which is where the asked word is shown.
Finder _asked(String text) =>
    find.descendant(of: find.byType(QuestionCard), matching: find.text(text));

/// The right answer of a typing step: the other language than the one shown
/// in the question card, because every step draws its own direction.
String _typingAnswer(WordPair word) =>
    _asked(word.english).evaluate().isNotEmpty ? word.hungarian : word.english;

Finder _tile(WordPair word, MatchSide side) =>
    find.byKey(matchTileKey(word, side));

/// Solves the step that is on the screen, starting at `words[solved]`, and
/// returns how many words it used up.
Future<int> _solveStep(
  WidgetTester tester,
  List<WordPair> words,
  int solved,
) async {
  if (_field.evaluate().isNotEmpty) {
    await tester.enterText(_field, _typingAnswer(words[solved]));
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();
    final next = find.text('Next');
    await tester.tap(find.text(next.evaluate().isEmpty ? 'Finish' : 'Next'));
    await tester.pumpAndSettle();
    return 1;
  }
  if (find.byKey(quizOptionKey(words[solved])).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(quizOptionKey(words[solved])));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    return 1;
  }
  // Matching: the page holds the next words in the order of the round.
  var used = 0;
  while (solved + used < words.length &&
      _tile(words[solved + used], MatchSide.english).evaluate().isNotEmpty) {
    final word = words[solved + used];
    await tester.tap(_tile(word, MatchSide.english));
    await tester.pump();
    await tester.tap(_tile(word, MatchSide.hungarian));
    await tester.pump();
    used++;
  }
  await tester.pumpAndSettle();
  return used;
}

void main() {
  testWidgets('starts with a step of the first word and 0 / 12', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byType(MixScreen), findsOneWidget);
    expect(find.text('Mix'), findsOneWidget);
    expect(find.text('0 / 12'), findsOneWidget);
  });

  testWidgets('goes through the whole round with every kind of step', (
    tester,
  ) async {
    final h = await _open(tester);

    var solved = 0;
    final kinds = <String>{};
    var guard = 0;
    while (h.path == AppRoutes.play(PlayMode.mix) && guard++ < 40) {
      if (_field.evaluate().isNotEmpty) {
        kinds.add('typing');
      } else if (find.byType(MatchingContent).evaluate().isNotEmpty) {
        kinds.add('matching');
      } else {
        kinds.add('quiz');
      }
      solved += await _solveStep(tester, h.words, solved);
      if (h.path == AppRoutes.play(PlayMode.mix)) {
        expect(find.text('$solved / 12'), findsOneWidget);
      }
    }

    expect(solved, 12);
    expect(kinds.length, greaterThan(1));
    expect(h.path, AppRoutes.summary(PlayMode.mix));
    expect(find.byType(RoundSummaryScreen), findsOneWidget);
    expect(find.text('Restart Mix'), findsOneWidget);
  });

  testWidgets('every step asks in its own direction and says so', (
    tester,
  ) async {
    final h = await _open(tester);

    var solved = 0;
    var guard = 0;
    while (h.path == AppRoutes.play(PlayMode.mix) && guard++ < 40) {
      final word = h.words[solved];
      final typing = _field.evaluate().isNotEmpty;
      final quiz = find.byKey(quizOptionKey(word)).evaluate().isNotEmpty;
      if (typing || quiz) {
        final englishQuestion = _asked(word.english).evaluate().isNotEmpty;
        final label = switch ((typing, englishQuestion)) {
          (true, true) => 'Write it in Hungarian',
          (true, false) => 'Write it in English',
          (false, true) => 'What does it mean in Hungarian?',
          (false, false) => 'How do you say it in English?',
        };
        expect(find.text(label), findsOneWidget, reason: 'word $solved');
        if (!englishQuestion) {
          expect(_asked(word.hungarian), findsOneWidget);
        }
        // Only an English question can be read aloud.
        expect(
          find.byTooltip('Read aloud'),
          englishQuestion ? findsOneWidget : findsNothing,
          reason: 'word $solved',
        );
      }
      solved += await _solveStep(tester, h.words, solved);
    }

    expect(solved, 12);
    expect(h.path, AppRoutes.summary(PlayMode.mix));
  });

  testWidgets('the setting of the student does not decide the direction', (
    tester,
  ) async {
    Future<List<bool>> directions(PromptLanguage setting) async {
      final h = await _open(tester, promptLanguage: setting);
      final englishQuestions = <bool>[];
      var solved = 0;
      var guard = 0;
      while (h.path == AppRoutes.play(PlayMode.mix) && guard++ < 40) {
        final word = h.words[solved];
        if (_field.evaluate().isNotEmpty ||
            find.byKey(quizOptionKey(word)).evaluate().isNotEmpty) {
          englishQuestions.add(_asked(word.english).evaluate().isNotEmpty);
        }
        solved += await _solveStep(tester, h.words, solved);
      }
      await tester.pumpWidget(const SizedBox());
      return englishQuestions;
    }

    final fromEnglish = await directions(PromptLanguage.english);
    final fromHungarian = await directions(PromptLanguage.hungarian);

    expect(fromHungarian, fromEnglish);
  });

  testWidgets('the summary shows a missed word as it was asked', (
    tester,
  ) async {
    final h = await _open(tester);
    final [first, second, ...] = h.words;

    // Miss the first word, whatever kind of step it is in.
    var askedInEnglish = true;
    if (_field.evaluate().isNotEmpty) {
      askedInEnglish = _asked(first.english).evaluate().isNotEmpty;
      await tester.enterText(_field, 'nope');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();
    } else if (find.byKey(quizOptionKey(first)).evaluate().isNotEmpty) {
      askedInEnglish = _asked(first.english).evaluate().isNotEmpty;
      final wrong = h.words
          .skip(1)
          .firstWhere(
            (w) => find.byKey(quizOptionKey(w)).evaluate().isNotEmpty,
          );
      await tester.tap(find.byKey(quizOptionKey(wrong)));
      await tester.pump();
    } else {
      await tester.tap(_tile(first, MatchSide.english));
      await tester.pump();
      await tester.tap(_tile(second, MatchSide.hungarian));
      await tester.pump(const Duration(seconds: 1));
    }

    var solved = 0;
    var guard = 0;
    while (h.path == AppRoutes.play(PlayMode.mix) && guard++ < 40) {
      solved += await _solveStep(tester, h.words, solved);
    }
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.summary(PlayMode.mix));
    final (asked, answer) = askedInEnglish
        ? (first.english, first.hungarian)
        : (first.hungarian, first.english);
    expect(find.text(asked), findsOneWidget);
    expect(find.text(answer), findsOneWidget);
    // The asked word is on the left, its pair on the right.
    expect(
      tester.getTopLeft(find.text(asked)).dx,
      lessThan(tester.getTopLeft(find.text(answer)).dx),
    );
  });

  testWidgets('the summary is in Hungarian too', (tester) async {
    final h = await _open(tester, locale: const Locale('hu'));

    var solved = 0;
    var guard = 0;
    while (h.path == AppRoutes.play(PlayMode.mix) && guard++ < 40) {
      if (_field.evaluate().isNotEmpty) {
        await tester.enterText(_field, _typingAnswer(h.words[solved]));
        await tester.pump();
        await tester.tap(find.text('Ellenőrzés'));
        await tester.pump();
        final next = find.text('Következő');
        await tester.tap(
          find.text(next.evaluate().isEmpty ? 'Befejezés' : 'Következő'),
        );
        await tester.pumpAndSettle();
        solved++;
      } else {
        solved += await _solveStep(tester, h.words, solved);
      }
    }

    expect(h.path, AppRoutes.summary(PlayMode.mix));
    expect(find.text('Mix újrakezdése'), findsOneWidget);
  });
}
