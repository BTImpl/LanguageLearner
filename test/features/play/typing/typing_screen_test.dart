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
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/prompt_language_providers.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_screen.dart';
import 'package:languagelearner/features/play/typing/typing_screen.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/features/stats/data/stats_providers.dart';

import '../../../helpers/fake_tts_service.dart';

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
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final deck = (await FakeWordRepository().getDecks()).first;
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
        initialSettingsProvider.overrideWithValue(
          AppSettings(promptLanguage: promptLanguage),
        ),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  router.go(AppRoutes.play(PlayMode.typing));
  await tester.pumpAndSettle();
  return _Harness(router, tts, words);
}

Finder get _field => find.byType(TextField);

String get _typed =>
    (_field.evaluate().single.widget as TextField).controller!.text;

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_field, text);
  await tester.pump();
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

/// Types [answer], checks it and, if it was right, goes on.
Future<void> _solve(WidgetTester tester, String answer) async {
  await _type(tester, answer);
  await _tapButton(tester, 'Check');
  // The last word has Finish instead of Next.
  final next = find.text('Next');
  await _tapButton(tester, next.evaluate().isEmpty ? 'Finish' : 'Next');
}

const _switchTooltip = 'Switch the question language';

Future<void> _switchLanguage(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_switchTooltip));
  await tester.pump();
}

/// The word of the round that is asked now, whatever the question language.
WordPair _asked(_Harness h, {required bool english}) => h.words.singleWhere(
  (w) => find.text(english ? w.english : w.hungarian).evaluate().isNotEmpty,
);

void main() {
  testWidgets('shows the first word, the input and the two buttons', (
    tester,
  ) async {
    final h = await _open(tester);

    expect(find.byType(TypingScreen), findsOneWidget);
    expect(find.text('Exact match'), findsOneWidget);
    expect(find.text('1 / 12'), findsOneWidget);
    expect(find.text('Write it in Hungarian'), findsOneWidget);
    expect(find.text(h.words.first.english), findsOneWidget);
    expect(find.text('Your answer'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
    expect(find.text("Doesn't match. Try again!"), findsNothing);
    expect(_typed, isEmpty);
  });

  testWidgets('the input is plain: no autocorrect, no capital, no spelling', (
    tester,
  ) async {
    await _open(tester);

    final field = tester.widget<TextField>(_field);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.textCapitalization, TextCapitalization.none);
    expect(field.spellCheckConfiguration, isNotNull);
    expect(field.autofocus, isTrue);
  });

  testWidgets('a wrong answer shows the message and keeps the text', (
    tester,
  ) async {
    final h = await _open(tester);

    await _type(tester, 'nope');
    await _tapButton(tester, 'Check');

    expect(find.text("Doesn't match. Try again!"), findsOneWidget);
    expect(_typed, 'nope');
    expect(find.text('1 / 12'), findsOneWidget);
    expect(find.text(h.words.first.english), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
  });

  testWidgets('editing the text takes the message away', (tester) async {
    await _open(tester);
    await _type(tester, 'nope');
    await _tapButton(tester, 'Check');

    await _type(tester, 'nope!');

    expect(find.text("Doesn't match. Try again!"), findsNothing);
  });

  testWidgets('an empty check does nothing', (tester) async {
    await _open(tester);

    await _tapButton(tester, 'Check');

    expect(find.text("Doesn't match. Try again!"), findsNothing);
    expect(find.text('1 / 12'), findsOneWidget);
  });

  testWidgets('a right answer turns the button into Next', (tester) async {
    final h = await _open(tester);
    final first = h.words.first;

    await _type(tester, '  ${first.hungarian.toUpperCase()} ');
    await _tapButton(tester, 'Check');

    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Check'), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text("Doesn't match. Try again!"), findsNothing);
    // The solved answer cannot be edited any more.
    final solvedText = _typed;
    await tester.enterText(_field, 'something else');
    await tester.pump();
    expect(_typed, solvedText);
    expect(find.text('1 / 12'), findsOneWidget);

    await _tapButton(tester, 'Next');

    expect(find.text('2 / 12'), findsOneWidget);
    expect(find.text(h.words[1].english), findsOneWidget);
    expect(_typed, isEmpty);
    expect(find.text('Check'), findsOneWidget);
  });

  testWidgets('the keyboard send key checks, then moves on', (tester) async {
    final h = await _open(tester);
    await _type(tester, h.words.first.hungarian);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Next'), findsOneWidget);
    expect(find.text('1 / 12'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('2 / 12'), findsOneWidget);
  });

  testWidgets('the help shows the answer with a countdown for 3 seconds', (
    tester,
  ) async {
    final h = await _open(tester);
    final answer = h.words.first.hungarian;
    expect(find.text(answer), findsNothing);

    await _tapButton(tester, 'Help');

    expect(find.text(answer), findsOneWidget);
    expect(find.text('3 s left'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2 s left'), findsOneWidget);
    expect(find.text(answer), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.text('1 s left'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text(answer), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('the help can be asked again', (tester) async {
    final h = await _open(tester);
    final answer = h.words.first.hungarian;
    await _tapButton(tester, 'Help');
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('1 s left'), findsOneWidget);

    await _tapButton(tester, 'Help');

    expect(find.text('3 s left'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(answer), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text(answer), findsNothing);

    await _tapButton(tester, 'Help');
    expect(find.text(answer), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('the help goes away when the answer is right', (tester) async {
    final h = await _open(tester);
    final answer = h.words.first.hungarian;
    await _tapButton(tester, 'Help');
    expect(find.text('3 s left'), findsOneWidget);

    await _type(tester, answer);
    await _tapButton(tester, 'Check');

    expect(find.text('3 s left'), findsNothing);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('an English question can be read aloud', (tester) async {
    final h = await _open(tester);

    await tester.tap(find.byTooltip('Read aloud'));
    await tester.pump();

    expect(h.tts.spoken, [h.words.first.english]);
  });

  testWidgets('a Hungarian question wants an English answer, no read-aloud', (
    tester,
  ) async {
    final h = await _open(tester, promptLanguage: PromptLanguage.hungarian);
    final first = h.words.first;

    expect(find.text('Write it in English'), findsOneWidget);
    expect(find.text(first.hungarian), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsNothing);

    await _type(tester, first.english);
    await _tapButton(tester, 'Check');

    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('the summary shows right, helped and wrong words', (
    tester,
  ) async {
    final h = await _open(tester);
    final [first, second, ...rest] = h.words;

    // First word: wrong, then right. Second word: help, then right.
    await _type(tester, 'nope');
    await _tapButton(tester, 'Check');
    await _solve(tester, first.hungarian);
    await _tapButton(tester, 'Help');
    await _solve(tester, second.hungarian);
    for (final word in rest) {
      await _solve(tester, word.hungarian);
    }
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.summary(PlayMode.typing));
    expect(find.byType(RoundSummaryScreen), findsOneWidget);
    expect(find.text('10 of 12 words went right first time'), findsOneWidget);
    expect(find.text('Exact match, Utazás'), findsOneWidget);
    expect(find.text('right first time'), findsOneWidget);
    expect(find.text('with help'), findsOneWidget);
    expect(find.text('wrong first time'), findsOneWidget);
    expect(find.text('Worth another look'), findsOneWidget);
    expect(find.text(first.english), findsOneWidget);
    expect(find.text(second.english), findsOneWidget);

    await tester.tap(find.text('Restart Exact match'));
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.play(PlayMode.typing));
    expect(find.text('1 / 12'), findsOneWidget);
    expect(_typed, isEmpty);
  });

  testWidgets('the last word ends with Finish', (tester) async {
    final h = await _open(tester);
    for (final word in h.words.take(11)) {
      await _solve(tester, word.hungarian);
    }

    await _type(tester, h.words.last.hungarian);
    await _tapButton(tester, 'Check');

    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('has Hungarian texts', (tester) async {
    await _open(tester, locale: const Locale('hu'));

    expect(find.text('Pontos egyezés'), findsOneWidget);
    expect(find.text('Írd le magyarul'), findsOneWidget);
    expect(find.text('A válaszod'), findsOneWidget);
    expect(find.text('Segítség'), findsOneWidget);
    expect(find.text('Ellenőrzés'), findsOneWidget);

    await _type(tester, 'nope');
    await _tapButton(tester, 'Ellenőrzés');
    expect(find.text('Nem egyezik. Próbáld újra!'), findsOneWidget);

    await _tapButton(tester, 'Segítség');
    expect(find.text('még 3 mp látszik'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('everything stays reachable with the keyboard open', (
    tester,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    final h = await _open(tester, size: const Size(320, 568));

    expect(tester.takeException(), isNull);
    // The buttons sit above the keyboard.
    expect(tester.getRect(find.text('Check')).bottom, lessThanOrEqualTo(268));
    expect(tester.getRect(find.text('Help')).bottom, lessThanOrEqualTo(268));

    await _tapButton(tester, 'Help');
    await tester.ensureVisible(_field);
    await _type(tester, h.words.first.hungarian);
    await _tapButton(tester, 'Check');

    expect(tester.takeException(), isNull);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('the switch button asks in the other language', (tester) async {
    final h = await _open(tester);
    expect(find.text('Write it in Hungarian'), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsOneWidget);

    await _switchLanguage(tester);

    expect(find.text('Write it in English'), findsOneWidget);
    expect(find.text('Write it in Hungarian'), findsNothing);
    expect(find.byTooltip('Read aloud'), findsNothing);
    // The English word is the right answer now, where the Hungarian was.
    final asked = _asked(h, english: false);
    await _type(tester, asked.english);
    await _tapButton(tester, 'Check');
    expect(find.text('Next'), findsOneWidget);
    expect(find.text("Doesn't match. Try again!"), findsNothing);
  });

  testWidgets('the old answer language is wrong after the switch', (
    tester,
  ) async {
    final h = await _open(tester);
    await _switchLanguage(tester);

    await _type(tester, _asked(h, english: false).hungarian);
    await _tapButton(tester, 'Check');

    expect(find.text("Doesn't match. Try again!"), findsOneWidget);
  });

  testWidgets('switching in the middle restarts the round from scratch', (
    tester,
  ) async {
    final h = await _open(tester);
    await _solve(tester, h.words[0].hungarian);
    await _solve(tester, h.words[1].hungarian);
    await _tapButton(tester, 'Help');
    await _type(tester, 'nope');
    await _tapButton(tester, 'Check');
    expect(find.text('3 / 12'), findsOneWidget);
    expect(find.text('3 s left'), findsOneWidget);
    expect(find.text("Doesn't match. Try again!"), findsOneWidget);

    await _switchLanguage(tester);

    expect(find.text('1 / 12'), findsOneWidget);
    expect(_typed, isEmpty);
    expect(find.text("Doesn't match. Try again!"), findsNothing);
    expect(find.text('3 s left'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Check'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('the unfinished round saves no statistics', (tester) async {
    final h = await _open(tester);
    await _solve(tester, h.words[0].hungarian);

    await _switchLanguage(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TypingScreen)),
    );
    await tester.pumpAndSettle();
    expect(container.read(statsRevisionProvider), 0);
    expect(h.path, AppRoutes.play(PlayMode.typing));
    expect(find.byType(RoundSummaryScreen), findsNothing);
  });

  testWidgets('switching twice goes back to the default direction', (
    tester,
  ) async {
    await _open(tester);

    await _switchLanguage(tester);
    await _switchLanguage(tester);

    expect(find.text('Write it in Hungarian'), findsOneWidget);
  });

  testWidgets('the switch works from a Hungarian default, too', (tester) async {
    await _open(tester, promptLanguage: PromptLanguage.hungarian);
    expect(find.text('Write it in English'), findsOneWidget);

    await _switchLanguage(tester);

    expect(find.text('Write it in Hungarian'), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsOneWidget);
  });

  testWidgets('the stored setting stays, the menu clears the switch', (
    tester,
  ) async {
    final h = await _open(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TypingScreen)),
    );

    await _switchLanguage(tester);

    expect(
      container.read(settingsProvider).promptLanguage,
      PromptLanguage.english,
    );
    expect(
      container.read(effectivePromptLanguageProvider),
      PromptLanguage.hungarian,
    );

    h.router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    h.router.go(AppRoutes.play(PlayMode.typing));
    await tester.pumpAndSettle();

    expect(find.text('Write it in Hungarian'), findsOneWidget);
    expect(
      container.read(settingsProvider).promptLanguage,
      PromptLanguage.english,
    );
  });

  testWidgets('the restart at the end of the round keeps the switch', (
    tester,
  ) async {
    final h = await _open(tester);
    await _switchLanguage(tester);
    // The restarted round has its own order: answer whatever is asked.
    for (var i = 0; i < h.words.length; i++) {
      await _solve(tester, _asked(h, english: false).english);
    }
    await tester.pumpAndSettle();
    expect(find.byType(RoundSummaryScreen), findsOneWidget);

    await tester.tap(find.text('Restart Exact match'));
    await tester.pumpAndSettle();

    expect(find.text('Write it in English'), findsOneWidget);
    expect(find.text('1 / 12'), findsOneWidget);

    h.router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    h.router.go(AppRoutes.play(PlayMode.typing));
    await tester.pumpAndSettle();

    expect(find.text('Write it in Hungarian'), findsOneWidget);
  });

  testWidgets('the switch button has a Hungarian label', (tester) async {
    await _open(tester, locale: const Locale('hu'));

    expect(find.byTooltip('Kérdés nyelvének váltása'), findsOneWidget);

    await tester.tap(find.byTooltip('Kérdés nyelvének váltása'));
    await tester.pump();

    expect(find.text('Írd le angolul'), findsOneWidget);
  });

  testWidgets('the title stays centered next to the switch button', (
    tester,
  ) async {
    await _open(tester);

    final center = tester.getCenter(find.text('Exact match')).dx;
    expect(center, closeTo(390 / 2, 0.5));
    expect(find.byTooltip(_switchTooltip), findsOneWidget);
    final size = tester.getSize(find.byTooltip(_switchTooltip));
    expect(size, const Size(44, 44));
  });

  testWidgets('the switch button stays reachable with the keyboard open', (
    tester,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await _open(tester, size: const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byTooltip(_switchTooltip)).bottom,
      lessThanOrEqualTo(268),
    );

    await _switchLanguage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Write it in English'), findsOneWidget);
  });

  testWidgets('meets the tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('leaving before any progress needs no confirmation', (
    tester,
  ) async {
    final h = await _open(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Leave the round?'), findsNothing);
    expect(h.path, AppRoutes.home);
  });

  testWidgets('leaving a round with progress asks first', (tester) async {
    final h = await _open(tester);
    await _solve(tester, h.words.first.hungarian);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Leave the round?'), findsOneWidget);
    expect(h.path, AppRoutes.play(PlayMode.typing));

    await tester.tap(find.text('Keep playing'));
    await tester.pumpAndSettle();
    expect(h.path, AppRoutes.play(PlayMode.typing));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.home);
  });
}
