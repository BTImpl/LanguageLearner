import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/play/speaking/speaking_game.dart';
import 'package:languagelearner/features/play/speaking/speech_engine.dart';

import '../../../helpers/fake_speech_engine.dart';
import '../../../helpers/manual_scheduler.dart';

List<WordPair> _words(int count) => [
  for (var i = 0; i < count; i++)
    WordPair.fromCells(id: 'w$i', english: 'english$i', hungarian: 'hu$i'),
];

const _help = Duration(seconds: 3);

/// An engine whose listening ends when the test says so.
class _SlowEngine implements SpeechEngine {
  final _done = Completer<SpeechHearing>();
  var stops = 0;

  void say(String text) => _done.complete(SpeechHearing(alternatives: [text]));

  @override
  Future<SpeechStatus> status() async => SpeechStatus.ready;

  @override
  Future<SpeechAccess> requestAccess() async => SpeechAccess.granted;

  @override
  Future<SpeechHearing> listen({
    required List<String> hints,
    void Function(String text)? onPartial,
    Duration maxDuration = const Duration(seconds: 8),
  }) => _done.future;

  @override
  Future<void> stop() async => stops++;
}

class _Setup {
  _Setup({int count = 4, int maxAttempts = 3, SpeechEngine? custom})
    : engine = FakeSpeechEngine() {
    session = RoundSession(
      words: _words(count),
      promptLanguage: PromptLanguage.hungarian,
      random: Random(1),
    );
    game = SpeakingGame(
      session: session,
      engine: custom ?? engine,
      hints: const ['english0', 'english1'],
      schedule: scheduler.call,
      maxAttempts: maxAttempts,
    );
  }

  final FakeSpeechEngine engine;
  final scheduler = ManualScheduler();
  late final RoundSession session;
  late final SpeakingGame game;

  WordPair get word => game.current!;

  String get right => session.answerText(word);

  WordOutcome? get outcome => session.outcomeOf(word);

  /// Says [text] and waits for the verdict.
  Future<void> say(String text) async {
    engine.heard = [text];
    await game.listen();
  }
}

void main() {
  group('saying the answer', () {
    test('asks in Hungarian and accepts the English word', () async {
      final s = _Setup();
      final asked = s.word;

      expect(s.session.promptText(asked), asked.hungarian);
      await s.say(s.right);

      expect(s.game.isSolved, isTrue);
      expect(s.game.feedback, SpeakingFeedback.correct);
      expect(s.game.heard, s.right);
      expect(s.outcome, WordOutcome.firstTry);
    });

    test('next goes on only after the right answer', () async {
      final s = _Setup();
      final first = s.word;

      s.game.next();
      expect(s.word, first);

      await s.say(s.right);
      s.game.next();

      expect(s.word, isNot(first));
      expect(s.game.index, 1);
      expect(s.game.isSolved, isFalse);
      expect(s.game.feedback, SpeakingFeedback.none);
    });

    test('the round finishes after the last word', () async {
      final s = _Setup(count: 2);
      for (var i = 0; i < 2; i++) {
        await s.say(s.right);
        s.game.next();
      }

      expect(s.game.isFinished, isTrue);
      expect(s.game.result.firstTry, 2);
    });

    test('a wrong answer can be repeated; the first one decides', () async {
      final s = _Setup();

      await s.say('something else');
      expect(s.game.feedback, SpeakingFeedback.wrong);
      expect(s.game.heard, 'something else');
      expect(s.game.wrongAttempts, 1);
      expect(s.game.isSolved, isFalse);

      await s.say(s.right);
      expect(s.game.isSolved, isTrue);
      expect(s.outcome, WordOutcome.wrongFirst);
    });

    test('a close reading is accepted', () async {
      final s = _Setup();

      await s.say(s.right.toUpperCase());

      expect(s.game.isSolved, isTrue);
    });

    test('hands the hints to the recogniser', () async {
      final s = _Setup();

      await s.say(s.right);

      expect(s.engine.hintsGiven.single, ['english0', 'english1']);
    });
  });

  group('attempts', () {
    test('the last wrong answer shows the answer and moves on', () async {
      final s = _Setup(maxAttempts: 2);
      final first = s.word;

      await s.say('no');
      expect(s.game.isLastAttempt, isTrue);
      await s.say('nope');

      expect(s.game.isGivenUp, isTrue);
      expect(s.game.helpText, s.session.answerText(first));
      expect(s.word, first);

      s.scheduler.elapse(_help);

      expect(s.word, isNot(first));
      expect(s.game.isGivenUp, isFalse);
      expect(s.game.wrongAttempts, 0);
      expect(s.session.outcomeOf(first), WordOutcome.wrongFirst);
    });

    test('nothing can be said once the attempts are used up', () async {
      final s = _Setup(maxAttempts: 1);

      await s.say('no');
      await s.say(s.right);

      expect(s.game.isSolved, isFalse);
      expect(s.engine.hintsGiven, hasLength(1));
    });
  });

  group('silence and errors are no attempts', () {
    test('nothing heard', () async {
      final s = _Setup();

      s.engine.heard = [];
      await s.game.listen();

      expect(s.game.feedback, SpeakingFeedback.nothing);
      expect(s.game.wrongAttempts, 0);
      expect(s.outcome, isNull);
      expect(s.game.isListening, isFalse);
    });

    test('access denied, and it is asked again next time', () async {
      final s = _Setup();
      s.engine.access = SpeechAccess.denied;

      await s.game.listen();

      expect(s.game.feedback, SpeakingFeedback.denied);
      expect(s.engine.hintsGiven, isEmpty);
      expect(s.outcome, isNull);

      s.engine.access = SpeechAccess.granted;
      await s.say(s.right);

      expect(s.engine.accessRequests, 2);
      expect(s.game.isSolved, isTrue);
    });

    test('recognition not available on the device', () async {
      final s = _Setup();
      s.engine.access = SpeechAccess.unavailable;

      await s.game.listen();

      expect(s.game.feedback, SpeakingFeedback.unavailable);
      expect(s.outcome, isNull);
    });

    test('the recogniser fails', () async {
      final s = _Setup();
      s.engine.failure = const SpeechException('failed');

      await s.game.listen();
      expect(s.game.feedback, SpeakingFeedback.failed);

      s.engine.failure = const SpeechException('unavailable');
      await s.game.listen();
      expect(s.game.feedback, SpeakingFeedback.unavailable);
      expect(s.outcome, isNull);
      expect(s.game.wrongAttempts, 0);
    });
  });

  group('help', () {
    test('shows the answer for a short while and counts as help', () async {
      final s = _Setup();

      s.game.requestHelp();

      expect(s.game.helpVisible, isTrue);
      expect(s.game.helpText, s.right);
      expect(s.outcome, WordOutcome.withHelp);

      s.scheduler.elapse(_help);
      expect(s.game.helpVisible, isFalse);
      expect(s.game.helpText, isNull);

      await s.say(s.right);
      expect(s.outcome, WordOutcome.withHelp);
    });

    test('asking again keeps it showing longer', () {
      final s = _Setup();

      s.game.requestHelp();
      s.scheduler.elapse(const Duration(seconds: 2));
      s.game.requestHelp();
      s.scheduler.elapse(const Duration(seconds: 2));

      expect(s.game.helpVisible, isTrue);
      expect(s.game.helpRevision, 2);

      s.scheduler.elapse(const Duration(seconds: 1));
      expect(s.game.helpVisible, isFalse);
    });

    test('after a wrong first answer it does not change the outcome', () async {
      final s = _Setup();

      await s.say('no');
      s.game.requestHelp();

      expect(s.outcome, WordOutcome.wrongFirst);
    });
  });

  group('next word', () {
    test('skips the word and counts it wrong', () {
      final s = _Setup();
      final first = s.word;

      s.game.skip();

      expect(s.word, isNot(first));
      expect(s.game.index, 1);
      expect(s.session.outcomeOf(first), WordOutcome.wrongFirst);
      expect(s.game.result.missedWords, [first]);
    });

    test('after help the word stays a help word', () {
      final s = _Setup();
      final first = s.word;

      s.game.requestHelp();
      s.game.skip();

      expect(s.session.outcomeOf(first), WordOutcome.withHelp);
      expect(s.game.index, 1);
      expect(s.game.helpVisible, isFalse);
    });

    test('skipping the last word finishes the round', () {
      final s = _Setup(count: 1);

      s.game.skip();

      expect(s.game.isFinished, isTrue);
    });

    test('does nothing after the word is solved', () async {
      final s = _Setup();
      await s.say(s.right);

      s.game.skip();

      expect(s.game.index, 0);
      expect(s.game.isSolved, isTrue);
    });
  });

  group('listening that is cut short', () {
    test('a skipped word ignores the late answer', () async {
      final slow = _SlowEngine();
      final s = _Setup(custom: slow);
      final first = s.word;
      final right = s.right;

      final listening = s.game.listen();
      await Future<void>.delayed(Duration.zero);
      expect(s.game.isListening, isTrue);

      s.game.skip();
      expect(s.game.isListening, isFalse);
      expect(slow.stops, 1);

      slow.say(right);
      await listening;

      expect(s.word, isNot(first));
      expect(s.game.isSolved, isFalse);
      expect(s.session.outcomeOf(s.word), isNull);
    });

    test('help closes the microphone', () async {
      final slow = _SlowEngine();
      final s = _Setup(custom: slow);

      final listening = s.game.listen();
      await Future<void>.delayed(Duration.zero);
      s.game.requestHelp();

      expect(s.game.isListening, isFalse);
      expect(slow.stops, 1);
      slow.say('anything');
      await listening;
      expect(s.game.wrongAttempts, 0);
    });

    test('leaving the game closes the microphone', () async {
      final slow = _SlowEngine();
      final s = _Setup(custom: slow);

      unawaited(s.game.listen());
      await Future<void>.delayed(Duration.zero);
      s.game.dispose();

      expect(slow.stops, 1);
    });

    test('a second listen while listening does nothing', () async {
      final slow = _SlowEngine();
      final s = _Setup(custom: slow);

      unawaited(s.game.listen());
      await Future<void>.delayed(Duration.zero);
      await s.game.listen();

      expect(s.game.isListening, isTrue);
    });
  });

  test('restart begins a new round', () async {
    final s = _Setup(count: 2);
    await s.say(s.right);
    s.game.next();

    s.game.restart();

    expect(s.game.index, 0);
    expect(s.game.result.firstTry, 0);
    expect(s.game.isSolved, isFalse);
  });

  test('says whether the audio may leave the phone', () async {
    final s = _Setup();
    expect(s.game.audioMayLeaveDevice, isTrue);

    await s.say(s.right);

    // The fake hearing is not on the device.
    expect(s.game.audioMayLeaveDevice, isTrue);
  });
}
