import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/services/english_tts_service.dart';
import 'package:languagelearner/core/services/tts_engine.dart';

import '../../helpers/fake_tts_service.dart';

class _FakeEngine implements TtsEngine {
  _FakeEngine({this.britishAvailable = true});

  final bool britishAvailable;
  final calls = <String>[];
  Exception? failure;

  @override
  Future<void> prepare() async => calls.add('prepare');

  @override
  Future<bool> isLanguageAvailable(String language) async =>
      language == 'en-GB' && britishAvailable;

  @override
  Future<void> setLanguage(String language) async =>
      calls.add('language:$language');

  @override
  Future<void> speak(String text) async {
    final error = failure;
    if (error != null) {
      throw error;
    }
    calls.add('speak:$text');
  }

  @override
  Future<void> stop() async => calls.add('stop');
}

void main() {
  test('speaks British English when the device has it', () async {
    final engine = _FakeEngine();

    await EnglishTtsService(engine).speak('boarding pass');

    expect(engine.calls, [
      'prepare',
      'language:en-GB',
      'stop',
      'speak:boarding pass',
    ]);
  });

  test('falls back to American English', () async {
    final engine = _FakeEngine(britishAvailable: false);

    await EnglishTtsService(engine).speak('ticket');

    expect(engine.calls, contains('language:en-US'));
    expect(engine.calls, isNot(contains('language:en-GB')));
  });

  test('sets the engine up only once', () async {
    final engine = _FakeEngine();
    final service = EnglishTtsService(engine);

    await service.speak('one');
    await service.speak('two');

    expect(engine.calls.where((call) => call == 'prepare'), hasLength(1));
    expect(
      engine.calls.where((call) => call.startsWith('language')),
      hasLength(1),
    );
  });

  test('stops the previous read-aloud before a new one', () async {
    final engine = _FakeEngine();
    final service = EnglishTtsService(engine);

    await service.speak('one');
    await service.speak('two');

    expect(engine.calls.sublist(engine.calls.length - 3), [
      'speak:one',
      'stop',
      'speak:two',
    ]);
  });

  test('quick taps: only the last word is read', () async {
    final engine = _FakeEngine();
    final service = EnglishTtsService(engine);

    await Future.wait([
      service.speak('one'),
      service.speak('two'),
      service.speak('three'),
    ]);

    expect(engine.calls.where((call) => call.startsWith('speak')), [
      'speak:three',
    ]);
  });

  test('ignores blank text', () async {
    final engine = _FakeEngine();

    await EnglishTtsService(engine).speak('   ');

    expect(engine.calls, isEmpty);
  });

  test('an engine error does not reach the caller', () async {
    final engine = _FakeEngine()..failure = Exception('no voice');

    await expectLater(EnglishTtsService(engine).speak('word'), completes);
  });

  test('stop reaches the engine', () async {
    final engine = _FakeEngine();

    await EnglishTtsService(engine).stop();

    expect(engine.calls, ['stop']);
  });

  test('the fake service records what it was asked to read', () async {
    final fake = FakeTtsService();

    await fake.speak('boarding pass');
    await fake.stop();

    expect(fake.spoken, ['boarding pass']);
    expect(fake.stops, 1);
  });
}
