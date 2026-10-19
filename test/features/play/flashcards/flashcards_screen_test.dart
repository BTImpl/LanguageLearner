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
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/features/play/flashcards/flashcards_screen.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_screen.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';

import '../../../helpers/fake_tts_service.dart';

class _Harness {
  _Harness(this.router, this.tts, this.words, this.clock);

  final GoRouter router;
  final FakeTtsService tts;

  /// The words in the order of the round.
  final List<WordPair> words;
  final _Clock clock;

  String get path => router.routerDelegate.currentConfiguration.uri.path;
}

class _Clock {
  var now = DateTime(2026, 10, 15, 10);
}

Future<_Harness> _open(
  WidgetTester tester, {
  PromptLanguage promptLanguage = PromptLanguage.english,
  Locale locale = const Locale('en'),
  bool ttsAvailable = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final deck = (await FakeWordRepository().getDecks()).first;
  final words = RoundSession.shuffled(deck.words, Random(1));
  final tts = FakeTtsService()..available = ttsAvailable;
  final clock = _Clock();
  final router = createAppRouter(initialLocation: AppRoutes.home);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        appLocaleProvider.overrideWithValue(locale),
        roundRandomProvider.overrideWithValue(Random(1)),
        ttsServiceProvider.overrideWithValue(tts),
        clockProvider.overrideWithValue(() => clock.now),
        initialSettingsProvider.overrideWithValue(
          AppSettings(promptLanguage: promptLanguage),
        ),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  router.go(AppRoutes.play(PlayMode.flashcards));
  await tester.pumpAndSettle();
  return _Harness(router, tts, words, clock);
}

Future<void> _tapCard(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _next(WidgetTester tester, [String label = 'Next']) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts with the English side of the first card', (tester) async {
    final h = await _open(tester);

    expect(find.byType(FlashcardsScreen), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('1 / 12'), findsOneWidget);
    expect(find.text(h.words[0].english), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Tap for the Hungarian side'), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsOneWidget);
  });

  testWidgets('the first card has no working Previous button', (tester) async {
    final h = await _open(tester);

    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 12'), findsOneWidget);
    expect(find.text(h.words[0].english), findsOneWidget);
  });

  testWidgets('tapping the card turns it, the Hungarian side has no speaker', (
    tester,
  ) async {
    final h = await _open(tester);

    await _tapCard(tester, h.words[0].english);

    expect(find.text(h.words[0].hungarian), findsOneWidget);
    expect(find.text('Hungarian'), findsOneWidget);
    expect(find.text('Tap for the English side'), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsNothing);

    await _tapCard(tester, h.words[0].hungarian);

    expect(find.text(h.words[0].english), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsOneWidget);
  });

  testWidgets('the speaker reads the English text and does not turn the card', (
    tester,
  ) async {
    final h = await _open(tester);

    await tester.tap(find.byTooltip('Read aloud'));
    await tester.pumpAndSettle();

    expect(h.tts.spoken, [h.words[0].english]);
    expect(find.text('English'), findsOneWidget);
    expect(find.text(h.words[0].english), findsOneWidget);
  });

  testWidgets(
    'Next shows the next card on its start side, Previous goes back',
    (tester) async {
      final h = await _open(tester);
      await _tapCard(tester, h.words[0].english);

      await _next(tester);

      expect(find.text('2 / 12'), findsOneWidget);
      expect(find.text(h.words[1].english), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 12'), findsOneWidget);
      expect(find.text(h.words[0].english), findsOneWidget);
    },
  );

  testWidgets('swiping turns the pages', (tester) async {
    final h = await _open(tester);

    await tester.fling(
      find.text(h.words[0].english),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 12'), findsOneWidget);

    await tester.fling(
      find.text(h.words[1].english),
      const Offset(300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 12'), findsOneWidget);
  });

  testWidgets('the Hungarian prompt starts on the Hungarian side', (
    tester,
  ) async {
    final h = await _open(tester, promptLanguage: PromptLanguage.hungarian);

    expect(find.text(h.words[0].hungarian), findsOneWidget);
    expect(find.text('Hungarian'), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsNothing);

    await _tapCard(tester, h.words[0].hungarian);

    expect(find.text(h.words[0].english), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsOneWidget);
  });

  testWidgets('reduced motion turns the card without animation', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final h = await _open(tester);

    await tester.tap(find.text(h.words[0].english));
    await tester.pump();

    expect(find.text(h.words[0].hungarian), findsOneWidget);
  });

  testWidgets('the last card finishes the round with a summary', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.tap(find.byTooltip('Read aloud'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 11; i++) {
      await _next(tester);
    }
    expect(find.text('12 / 12'), findsOneWidget);
    expect(find.text('Next'), findsNothing);

    h.clock.now = h.clock.now.add(const Duration(seconds: 125));
    await _next(tester, 'Finish');

    expect(h.path, AppRoutes.summary(PlayMode.flashcards));
    expect(find.byType(RoundSummaryScreen), findsOneWidget);
    expect(find.text('You viewed all 12 cards'), findsOneWidget);
    expect(find.text('Flashcards, Utazás'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Worth another look'), findsNothing);

    await tester.tap(find.text('Restart Flashcards'));
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.play(PlayMode.flashcards));
    expect(find.text('1 / 12'), findsOneWidget);
  });

  testWidgets('without a voice on the device there is no read-aloud button', (
    tester,
  ) async {
    await _open(tester, ttsAvailable: false);

    expect(find.byTooltip('Read aloud'), findsNothing);
    expect(find.text('1 / 12'), findsOneWidget);
  });

  testWidgets('the back button goes to the home screen', (tester) async {
    final h = await _open(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.home);
  });

  testWidgets('has Hungarian texts', (tester) async {
    await _open(tester, locale: const Locale('hu'));

    expect(find.text('Kártyák'), findsOneWidget);
    expect(find.text('Angol'), findsOneWidget);
    expect(find.text('Koppints a magyar oldalért'), findsOneWidget);
    expect(find.text('Előző'), findsOneWidget);
    expect(find.text('Következő'), findsOneWidget);
  });

  testWidgets('meets the tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
