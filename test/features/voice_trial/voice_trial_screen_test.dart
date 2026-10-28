import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/system_settings_opener.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/features/voice_trial/speech_engine.dart';
import 'package:languagelearner/features/voice_trial/voice_trial_screen.dart';

import '../../helpers/fake_speech_engine.dart';
import '../../helpers/fake_system_settings_opener.dart';
import '../../helpers/fake_tts_service.dart';
import '../../helpers/pump_themed.dart';

final _deck = Deck(
  id: 'd',
  name: 'Deck',
  updatedAt: DateTime(2026, 10, 28),
  words: [
    WordPair.fromCells(id: '1', english: 'house', hungarian: 'ház'),
    WordPair.fromCells(id: '2', english: 'tree', hungarian: 'fa'),
  ],
);

Future<(FakeSpeechEngine, FakeTtsService, FakeSystemSettingsOpener)> _open(
  WidgetTester tester, {
  FakeSpeechEngine? engine,
  Deck? deck,
}) async {
  final speech = engine ?? FakeSpeechEngine();
  final tts = FakeTtsService();
  final opener = FakeSystemSettingsOpener();
  await pumpThemed(
    tester,
    const VoiceTrialScreen(),
    asScreen: true,
    overrides: [
      speechEngineProvider.overrideWithValue(speech),
      ttsServiceProvider.overrideWithValue(tts),
      systemSettingsOpenerProvider.overrideWithValue(opener),
      selectedDeckProvider.overrideWithValue(AsyncData(deck ?? _deck)),
    ],
  );
  await tester.pumpAndSettle();
  return (speech, tts, opener);
}

/// The Hungarian word on the screen tells which word was picked.
String _expectedFor(WidgetTester tester) =>
    find.text('ház').evaluate().isNotEmpty ? 'house' : 'tree';

void main() {
  testWidgets('an accepted answer shows the result and the log', (
    tester,
  ) async {
    final (speech, tts, _) = await _open(tester);
    speech.heard = [_expectedFor(tester)];

    await tester.tap(find.byKey(voiceTrialMicKey));
    await tester.pumpAndSettle();

    expect(find.byKey(voiceTrialResultKey), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('1 of 1 accepted'), findsOneWidget);
    expect(tts.stops, 1);
  });

  testWidgets('a wrong answer is rejected', (tester) async {
    final (speech, _, _) = await _open(tester);
    speech.heard = ['banana'];

    await tester.tap(find.byKey(voiceTrialMicKey));
    await tester.pumpAndSettle();

    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('0 of 1 accepted'), findsOneWidget);
  });

  testWidgets('nothing heard is shown as such', (tester) async {
    await _open(tester);

    await tester.tap(find.byKey(voiceTrialMicKey));
    await tester.pumpAndSettle();

    expect(find.text('I heard nothing'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('the word list is given as a hint only when switched on', (
    tester,
  ) async {
    final (speech, _, _) = await _open(tester);

    await tester.tap(find.byKey(voiceTrialMicKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(voiceTrialNextKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(voiceTrialHintsKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(voiceTrialMicKey));
    await tester.pumpAndSettle();

    expect(speech.hintsGiven.first, unorderedEquals(['house', 'tree']));
    expect(speech.hintsGiven.last, isEmpty);
  });

  testWidgets('the next word leaves the result', (tester) async {
    await _open(tester);

    await tester.tap(find.byKey(voiceTrialMicKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(voiceTrialNextKey));
    await tester.pumpAndSettle();

    expect(find.byKey(voiceTrialResultKey), findsNothing);
    expect(find.byKey(voiceTrialMicKey), findsOneWidget);
  });

  testWidgets('a refused permission offers the settings', (tester) async {
    final (_, _, opener) = await _open(
      tester,
      engine: FakeSpeechEngine(access: SpeechAccess.denied),
    );

    await tester.tap(find.byKey(voiceTrialMicKey));
    await tester.pumpAndSettle();

    expect(find.text('No access to the microphone'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pump();
    expect(opener.opened, 1);
  });

  testWidgets('a device without recognition says so', (tester) async {
    await _open(
      tester,
      engine: FakeSpeechEngine(access: SpeechAccess.unavailable),
    );

    await tester.tap(find.byKey(voiceTrialMicKey));
    await tester.pumpAndSettle();

    expect(
      find.text('Speech recognition is not available on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed recognition can be tried again', (tester) async {
    final speech = FakeSpeechEngine()
      ..failure = const SpeechException('failed');
    await _open(tester, engine: speech);

    await tester.tap(find.byKey(voiceTrialMicKey));
    await tester.pumpAndSettle();

    expect(find.text('Recognition failed. Try again.'), findsOneWidget);
    expect(find.byKey(voiceTrialMicKey), findsOneWidget);
  });

  testWidgets('an empty deck shows a message', (tester) async {
    await _open(
      tester,
      deck: Deck(
        id: 'e',
        name: 'E',
        words: const [],
        updatedAt: DateTime(2026),
      ),
    );

    expect(
      find.text('There are no words to practise. Open a word list first.'),
      findsOneWidget,
    );
    expect(find.byKey(voiceTrialMicKey), findsNothing);
  });
}
