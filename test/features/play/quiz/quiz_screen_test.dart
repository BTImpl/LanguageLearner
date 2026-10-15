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
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/core/widgets/choice_tile.dart';
import 'package:languagelearner/features/home/home_screen.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/quiz/quiz_screen.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_screen.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';

import '../../../helpers/fake_tts_service.dart';

/// One deck with the given words.
class _Repository implements WordRepository {
  _Repository(this.words);

  final List<WordPair> words;

  @override
  Future<List<Deck>> getDecks() async => [
    Deck(id: 'own', name: 'Own', updatedAt: DateTime.utc(2026), words: words),
  ];

  @override
  Future<void> refresh() async {}
}

List<WordPair> _plainWords(int count) => [
  for (var i = 0; i < count; i++)
    WordPair.fromCells(id: 'p$i', english: 'word$i', hungarian: 'szó$i'),
];

class _Harness {
  _Harness(this.router, this.tts, this.words);

  final GoRouter router;
  final FakeTtsService tts;

  /// The words in the order of the round.
  final List<WordPair> words;

  String get path => router.routerDelegate.currentConfiguration.uri.path;
}

Future<_Harness> _open(
  WidgetTester tester, {
  PromptLanguage promptLanguage = PromptLanguage.english,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 1000),
  WordRepository? repository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final deck = (await (repository ?? FakeWordRepository()).getDecks()).first;
  final words = RoundSession.shuffled(deck.words, Random(1));
  final tts = FakeTtsService();
  final router = createAppRouter();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        appLocaleProvider.overrideWithValue(locale),
        roundRandomProvider.overrideWithValue(Random(1)),
        ttsServiceProvider.overrideWithValue(tts),
        if (repository != null)
          wordRepositoryProvider.overrideWithValue(repository),
        initialSettingsProvider.overrideWithValue(
          AppSettings(promptLanguage: promptLanguage),
        ),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  router.go(AppRoutes.play(PlayMode.quiz));
  await tester.pumpAndSettle();
  return _Harness(router, tts, words);
}

Finder _option(String label) => find.widgetWithText(ChoiceTile, label);

ChoiceState _state(WidgetTester tester, String label) =>
    tester.widget<ChoiceTile>(_option(label)).state;

List<String> _labels(WidgetTester tester) => [
  for (final tile in tester.widgetList<ChoiceTile>(find.byType(ChoiceTile)))
    tile.label,
];

/// The labels of the answers that are not [right], in screen order.
List<String> _wrongLabels(WidgetTester tester, String right) => [
  for (final label in _labels(tester))
    if (label != right) label,
];

Future<void> _choose(WidgetTester tester, String label) async {
  await tester.tap(_option(label));
  await tester.pump();
}

/// Chooses the right answer and lets the next question come.
Future<void> _answerRight(WidgetTester tester, String right) async {
  await _choose(tester, right);
  // Timers do not schedule frames, so let the time pass explicitly.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets('shows the first word with four answers and the counters', (
    tester,
  ) async {
    final h = await _open(tester);
    final first = h.words.first;

    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('1 / 12'), findsOneWidget);
    expect(find.text('What does it mean in Hungarian?'), findsOneWidget);
    expect(find.text(first.english), findsOneWidget);
    expect(find.byType(ChoiceTile), findsNWidgets(4));
    expect(_option(first.hungarian), findsOneWidget);
    expect(find.text('right first time'), findsOneWidget);
    expect(find.text('wrong first time'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('Not this one. Try again!'), findsNothing);
  });

  testWidgets('a wrong answer turns red and stays, the word stays too', (
    tester,
  ) async {
    final h = await _open(tester);
    final first = h.words.first;
    final [wrong, other, _] = _wrongLabels(tester, first.hungarian);

    await _choose(tester, wrong);
    await tester.pump(const Duration(seconds: 5));

    expect(_state(tester, wrong), ChoiceState.wrong);
    expect(find.text('Not this one. Try again!'), findsOneWidget);
    expect(find.text('1 / 12'), findsOneWidget);
    expect(find.text(first.english), findsOneWidget);
    // One word was wrong at the first choice.
    expect(find.text('1'), findsOneWidget);

    // The others can still be chosen, the red one ignores taps.
    await _choose(tester, other);
    await tester.tap(_option(wrong), warnIfMissed: false);
    await tester.pump();

    expect(_state(tester, other), ChoiceState.wrong);
    expect(_state(tester, first.hungarian), ChoiceState.idle);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('the right answer turns green, then the next word comes', (
    tester,
  ) async {
    final h = await _open(tester);
    final first = h.words.first;
    final [wrong, ...] = _wrongLabels(tester, first.hungarian);

    await _choose(tester, first.hungarian);

    expect(_state(tester, first.hungarian), ChoiceState.correct);
    expect(find.text('Not this one. Try again!'), findsNothing);
    // Nothing else can be chosen while the right answer is shown.
    await tester.tap(_option(wrong), warnIfMissed: false);
    await tester.pump();
    expect(_state(tester, wrong), ChoiceState.idle);
    expect(find.text('1 / 12'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('2 / 12'), findsOneWidget);
    expect(find.text(h.words[1].english), findsOneWidget);
    expect(_option(h.words[1].hungarian), findsOneWidget);
    // One word was right at the first choice.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    for (final label in _labels(tester)) {
      expect(_state(tester, label), ChoiceState.idle);
    }
  });

  testWidgets('a word that was wrong first counts as wrong first', (
    tester,
  ) async {
    final h = await _open(tester);
    final first = h.words.first;
    final [wrong, ...] = _wrongLabels(tester, first.hungarian);

    await _choose(tester, wrong);
    await _answerRight(tester, first.hungarian);

    expect(find.text('2 / 12'), findsOneWidget);
    // Guessed 0, wrong first 1.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('an English question can be read aloud', (tester) async {
    final h = await _open(tester);

    await tester.tap(find.byTooltip('Read aloud'));
    await tester.pump();

    expect(h.tts.spoken, [h.words.first.english]);
    expect(find.text('1 / 12'), findsOneWidget);
  });

  testWidgets('a Hungarian question has English answers, no read-aloud', (
    tester,
  ) async {
    final h = await _open(tester, promptLanguage: PromptLanguage.hungarian);
    final first = h.words.first;

    expect(find.text('How do you say it in English?'), findsOneWidget);
    expect(find.text(first.hungarian), findsOneWidget);
    expect(_option(first.english), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsNothing);
  });

  testWidgets('the summary lists the word that was wrong first', (
    tester,
  ) async {
    final h = await _open(tester);
    final first = h.words.first;
    final [wrong, ...] = _wrongLabels(tester, first.hungarian);

    await _choose(tester, wrong);
    for (final word in h.words) {
      await _answerRight(tester, word.hungarian);
    }
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.summary(PlayMode.quiz));
    expect(find.byType(RoundSummaryScreen), findsOneWidget);
    expect(find.text('11 of 12 words went right first time'), findsOneWidget);
    expect(find.text('Quiz, Utazás'), findsOneWidget);
    expect(find.text('Worth another look'), findsOneWidget);
    expect(find.text(first.english), findsOneWidget);
    expect(find.text(first.hungarian), findsOneWidget);

    await tester.tap(find.text('Restart Quiz'));
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.play(PlayMode.quiz));
    expect(find.text('1 / 12'), findsOneWidget);
    expect(find.byType(ChoiceTile), findsNWidgets(4));
  });

  testWidgets('a deck with fewer than four words shows a message', (
    tester,
  ) async {
    final h = await _open(tester, repository: _Repository(_plainWords(3)));

    expect(
      find.text('This mode needs at least 4 words in the deck.'),
      findsOneWidget,
    );
    expect(find.byType(ChoiceTile), findsNothing);

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.home);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('has Hungarian texts', (tester) async {
    final h = await _open(tester, locale: const Locale('hu'));
    final first = h.words.first;
    final [wrong, ...] = _wrongLabels(tester, first.hungarian);

    expect(find.text('Tanuló'), findsOneWidget);
    expect(find.text('Mit jelent magyarul?'), findsOneWidget);
    expect(find.text('elsőre eltalált'), findsOneWidget);
    expect(find.text('elsőre hibás'), findsOneWidget);

    await _choose(tester, wrong);

    expect(find.text('Nem ez az. Próbáld újra!'), findsOneWidget);
  });

  testWidgets('works on a small screen: the answers scroll', (tester) async {
    final h = await _open(tester, size: const Size(320, 568));
    final first = h.words.first;
    final last = _labels(tester).last;

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      _option(last),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await _choose(tester, last);

    expect(
      _state(tester, last),
      last == first.hungarian ? ChoiceState.correct : ChoiceState.wrong,
    );
  });

  testWidgets('long texts wrap inside the question card and the answers', (
    tester,
  ) async {
    final words = [
      WordPair.fromCells(
        id: 'long-1',
        english: 'a connecting flight with a long layover',
        hungarian: 'csatlakozó járat hosszú átszállással a következő városba',
      ),
      WordPair.fromCells(
        id: 'long-2',
        english: 'responsibility',
        hungarian: 'felelősségvállalás és együttműködés a csapatban',
      ),
      ..._plainWords(2),
    ];
    final h = await _open(
      tester,
      size: const Size(320, 900),
      repository: _Repository(words),
    );

    expect(tester.takeException(), isNull);
    for (final label in _labels(tester)) {
      final rect = tester.getRect(_option(label));
      expect(rect.left, greaterThanOrEqualTo(20));
      expect(rect.right, lessThanOrEqualTo(300));
    }
    final first = h.words.first;
    await _answerRight(tester, first.hungarian);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets the tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
