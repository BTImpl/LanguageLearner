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
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/speaking/speaking_screen.dart';
import 'package:languagelearner/features/play/speaking/speech_engine.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';

import '../../../helpers/fake_speech_engine.dart';
import '../../../helpers/fake_tts_service.dart';

class _Harness {
  _Harness(this.router, this.engine, this.tts, this.words);

  final GoRouter router;
  final FakeSpeechEngine engine;
  final FakeTtsService tts;

  /// The words in the order of the round.
  final List<WordPair> words;

  String get path => router.routerDelegate.currentConfiguration.uri.path;
}

Future<_Harness> _open(
  WidgetTester tester, {
  AppSettings settings = const AppSettings(),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final deck = (await FakeWordRepository().getDecks()).first;
  final words = RoundSession.shuffled(deck.words, Random(1));
  final engine = FakeSpeechEngine();
  final tts = FakeTtsService();
  final router = createAppRouter();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        appLocaleProvider.overrideWithValue(const Locale('en')),
        roundRandomProvider.overrideWithValue(Random(1)),
        ttsServiceProvider.overrideWithValue(tts),
        speechEngineProvider.overrideWithValue(engine),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  router.go(AppRoutes.play(PlayMode.speaking));
  await tester.pumpAndSettle();
  return _Harness(router, engine, tts, words);
}

Finder get _mic => find.byKey(const ValueKey('speaking-mic'));

/// Taps the microphone; the fake engine hears [text] (nothing when null).
Future<void> _say(WidgetTester tester, _Harness h, String? text) async {
  h.engine.heard = [?text];
  await tester.tap(_mic);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks the Hungarian word and hides the English one', (
    tester,
  ) async {
    final h = await _open(tester);
    final word = h.words.first;

    expect(find.byType(SpeakingScreen), findsOneWidget);
    expect(find.text('Speaking'), findsOneWidget);
    expect(find.text('Say it in English'), findsOneWidget);
    expect(find.text(word.hungarian), findsOneWidget);
    expect(find.text(word.english), findsNothing);
    expect(find.text('1 / ${h.words.length}'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Next word'), findsOneWidget);
    expect(_mic, findsOneWidget);
  });

  testWidgets('a right answer shows the word and moves on with Next', (
    tester,
  ) async {
    final h = await _open(tester);
    final word = h.words.first;

    await _say(tester, h, word.english);

    expect(find.text('Correct!'), findsOneWidget);
    expect(find.text(word.english), findsWidgets);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.byTooltip('Read aloud'));
    await tester.pump();
    expect(h.tts.spoken, [word.english]);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text(h.words[1].hungarian), findsOneWidget);
    expect(find.text('2 / ${h.words.length}'), findsOneWidget);
  });

  testWidgets('a wrong answer says so and can be repeated', (tester) async {
    final h = await _open(tester);
    final word = h.words.first;

    await _say(tester, h, 'completely different');

    expect(find.text("That wasn't it. Try again!"), findsOneWidget);
    expect(find.textContaining('completely different'), findsOneWidget);
    expect(find.text(word.hungarian), findsOneWidget);

    await _say(tester, h, word.english);
    expect(find.text('Correct!'), findsOneWidget);
  });

  testWidgets('says when nothing was heard', (tester) async {
    final h = await _open(tester);

    await _say(tester, h, null);

    expect(find.text('I heard nothing. Try again.'), findsOneWidget);
    expect(find.text(h.words.first.hungarian), findsOneWidget);
  });

  testWidgets('explains a denied microphone', (tester) async {
    final h = await _open(tester);
    h.engine.access = SpeechAccess.denied;

    await _say(tester, h, 'anything');

    expect(find.text('No access to the microphone'), findsOneWidget);
    expect(
      find.text(
        'Allow the microphone and speech recognition in Settings to speak.',
      ),
      findsOneWidget,
    );
    // The student can still go on.
    await tester.tap(find.text('Next word'));
    await tester.pumpAndSettle();
    expect(find.text(h.words[1].hungarian), findsOneWidget);
  });

  testWidgets('explains a device without speech recognition', (tester) async {
    final h = await _open(tester);
    h.engine.access = SpeechAccess.unavailable;

    await _say(tester, h, 'anything');

    expect(
      find.text('Speech recognition is not available on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('explains a failed recognition', (tester) async {
    final h = await _open(tester);
    h.engine.failure = const SpeechException('failed');

    await _say(tester, h, 'anything');

    expect(find.text('Recognition failed. Try again.'), findsOneWidget);
  });

  testWidgets('Help shows the answer for a few seconds', (tester) async {
    final h = await _open(tester);
    final word = h.words.first;

    await tester.tap(find.text('Help'));
    await tester.pump();

    expect(find.text(word.english), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text(word.english), findsNothing);
  });

  testWidgets('Next word skips the word', (tester) async {
    final h = await _open(tester);

    await tester.tap(find.text('Next word'));
    await tester.pumpAndSettle();

    expect(find.text(h.words[1].hungarian), findsOneWidget);
    expect(find.text('2 / ${h.words.length}'), findsOneWidget);
  });

  testWidgets('skipping every word ends in the round summary', (tester) async {
    final h = await _open(tester);

    for (var i = 0; i < h.words.length; i++) {
      await tester.tap(find.text('Next word'));
      await tester.pumpAndSettle();
    }

    expect(h.path, AppRoutes.summary(PlayMode.speaking));
    expect(find.text('Round complete'), findsOneWidget);
    expect(find.text('Restart Speaking'), findsOneWidget);
  });

  testWidgets('hands the English words to the recogniser', (tester) async {
    final h = await _open(tester);

    await _say(tester, h, h.words.first.english);

    expect(
      h.engine.hintsGiven.single,
      containsAll(h.words.map((w) => w.english)),
    );
  });

  testWidgets('hands nothing over when the setting is off', (tester) async {
    final h = await _open(
      tester,
      settings: const AppSettings(speakingHints: false),
    );

    await _say(tester, h, h.words.first.english);

    expect(h.engine.hintsGiven.single, isEmpty);
  });

  testWidgets('tells that the audio may be sent to Apple', (tester) async {
    await _open(tester);

    expect(
      find.text(
        'If English recognition is not downloaded on the phone, the audio '
        'may be sent to Apple for recognition.',
      ),
      findsOneWidget,
    );
  });
}
