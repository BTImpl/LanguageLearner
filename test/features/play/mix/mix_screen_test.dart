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
          AppSettings(promptLanguage: PromptLanguage.english),
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
    await tester.enterText(_field, words[solved].hungarian);
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

  testWidgets('the summary is in Hungarian too', (tester) async {
    final h = await _open(tester, locale: const Locale('hu'));

    var solved = 0;
    var guard = 0;
    while (h.path == AppRoutes.play(PlayMode.mix) && guard++ < 40) {
      if (_field.evaluate().isNotEmpty) {
        await tester.enterText(_field, h.words[solved].hungarian);
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
