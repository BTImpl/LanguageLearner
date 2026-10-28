import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/schedule.dart';
import 'package:languagelearner/features/play/speaking/speech_engine.dart';
import 'package:languagelearner/features/play/speaking/spoken_answer_matcher.dart';

/// What the screen shows under the microphone button.
enum SpeakingFeedback {
  none,

  /// The answer was said right.
  correct,

  /// Something was said, but it was not the word.
  wrong,

  /// Nothing was heard. This is not an attempt.
  nothing,

  /// The student did not allow the microphone or the speech recognition.
  denied,

  /// The device cannot recognise speech.
  unavailable,

  /// The recogniser failed for another reason. This is not an attempt.
  failed,
}

/// The rules of the speaking game, independent of any screen.
///
/// The words of the [session] are asked one by one in Hungarian (the
/// recogniser knows English only); the student says the English word and
/// [decideSpokenAnswer] judges what the [engine] heard against every accepted
/// answer of the word. It follows the rules of the typing game:
///
/// - a wrong answer can be repeated, but only [maxAttempts] wrong answers are
///   allowed: after the last one the right answer shows for [helpDuration]
///   and the game moves on by itself;
/// - silence and technical failures are no attempts;
/// - [requestHelp] shows the right answer for [helpDuration], and counts as
///   help if it is the first thing that happens to the word;
/// - [skip] goes to the next word at once; a word that was skipped without
///   being solved counts as wrong at the first attempt;
/// - after the right answer the student moves on with [next].
///
/// The first thing that happens to a word decides its outcome, like in every
/// other mode.
class SpeakingGame {
  SpeakingGame({
    required this.session,
    required this.engine,
    this.hints = const [],
    Schedule? schedule,
    this.helpDuration = const Duration(seconds: 3),
    this.maxAttempts = defaultMaxAttempts,
  }) : assert(maxAttempts >= 1, 'At least one attempt is needed.'),
       _schedule = schedule ?? timerSchedule;

  /// How many wrong answers a word accepts by default.
  static const defaultMaxAttempts = 3;

  final RoundSession session;
  final SpeechEngine engine;

  /// The words the recogniser is told to expect; empty to tell it nothing.
  final List<String> hints;

  /// How many wrong answers the current word accepts before the game shows
  /// the right one and moves on.
  final int maxAttempts;

  /// How long the help shows the right answer.
  final Duration helpDuration;

  final Schedule _schedule;
  final _listeners = <void Function()>[];
  Cancel? _cancelHelp;
  SpeechAccess? _access;
  var _listening = false;
  var _listenId = 0;
  var _partial = '';
  var _heard = '';
  var _onDevice = false;
  var _solved = false;
  var _helpVisible = false;
  var _helpRevision = 0;
  var _feedback = SpeakingFeedback.none;
  var _wrongAttempts = 0;
  var _givenUp = false;
  var _disposed = false;

  /// The word that is asked, `null` when the round is finished.
  WordPair? get current => session.current;

  int get total => session.total;

  /// The number of words that are done, i.e. the position of the question.
  int get index => session.index;

  bool get isFinished => session.isFinished;

  /// Whether the current word has been said right.
  bool get isSolved => _solved;

  /// Whether the microphone is open now.
  bool get isListening => _listening;

  /// What the recogniser understands so far, while listening.
  String get partial => _partial;

  /// What the recogniser heard in the last answer (its best reading), empty
  /// when nothing was heard.
  String get heard => _heard;

  /// What to show under the microphone button.
  SpeakingFeedback get feedback => _feedback;

  /// How many wrong answers the current word has had.
  int get wrongAttempts => _wrongAttempts;

  /// How many wrong answers the current word still accepts.
  int get attemptsLeft => maxAttempts - _wrongAttempts;

  /// Whether the next wrong answer is the last one (only if there is more
  /// than one attempt, so the student has already been warned by a miss).
  bool get isLastAttempt =>
      !_solved && !_givenUp && maxAttempts > 1 && attemptsLeft == 1;

  /// Whether the attempts of the current word are used up: the right answer
  /// shows and the game moves on by itself when the help runs out.
  bool get isGivenUp => _givenUp;

  /// Whether the help is showing the right answer now.
  bool get helpVisible => _helpVisible;

  /// Grows with every [requestHelp], so a screen can tell a new request from
  /// the one it is already showing.
  int get helpRevision => _helpRevision;

  /// The right answer while the help is showing, otherwise `null`.
  String? get helpText {
    final word = current;
    return _helpVisible && word != null ? session.answerText(word) : null;
  }

  /// Whether the audio may leave the phone for recognition: it may until the
  /// recogniser has reported that it works on the device.
  bool get audioMayLeaveDevice => !_onDevice;

  /// The outcome so far, see [RoundSession.result].
  RoundResult get result => session.result;

  /// Calls [listener] after every change.
  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Opens the microphone and judges what is said. Does nothing while it is
  /// already listening, after the word is solved or the attempts are used up.
  Future<void> listen() async {
    final word = current;
    if (_disposed || _listening || _solved || _givenUp || word == null) {
      return;
    }
    final id = ++_listenId;
    _listening = true;
    _partial = '';
    _heard = '';
    _feedback = SpeakingFeedback.none;
    _notify();

    final access = _access ??= await engine.requestAccess();
    if (!_isCurrent(id)) {
      return;
    }
    if (access != SpeechAccess.granted) {
      // Ask again next time: the student may have allowed it in the settings.
      _access = null;
      _finishListening(
        access == SpeechAccess.denied
            ? SpeakingFeedback.denied
            : SpeakingFeedback.unavailable,
      );
      return;
    }

    final SpeechHearing hearing;
    try {
      hearing = await engine.listen(
        hints: hints,
        onPartial: (text) {
          if (_isCurrent(id)) {
            _partial = text;
            _notify();
          }
        },
      );
    } on SpeechException catch (e) {
      if (_isCurrent(id)) {
        _finishListening(
          e.code == 'unavailable'
              ? SpeakingFeedback.unavailable
              : SpeakingFeedback.failed,
        );
      }
      return;
    }
    if (!_isCurrent(id)) {
      return;
    }
    _onDevice = hearing.onDevice;
    _judge(word, hearing);
  }

  /// Ends the listening early; what has been heard so far is judged.
  Future<void> stopListening() async {
    if (_listening) {
      await engine.stop();
    }
  }

  /// The student asked for help: the right answer shows for [helpDuration].
  /// Asking again keeps it showing for another [helpDuration].
  void requestHelp() {
    final word = current;
    if (_disposed || _solved || _givenUp || word == null) {
      return;
    }
    _abandonListening();
    session.recordHelp(word);
    _helpRevision++;
    _cancelHelp?.call();
    _helpVisible = true;
    _cancelHelp = _schedule(helpDuration, () {
      _cancelHelp = null;
      if (_disposed) {
        return;
      }
      _helpVisible = false;
      _notify();
    });
    _notify();
  }

  /// Goes on to the next word without solving this one. The word counts as
  /// wrong at the first attempt unless it already has an outcome (help).
  void skip() {
    final word = current;
    if (_disposed || _solved || _givenUp || word == null) {
      return;
    }
    _abandonListening();
    session.recordAttempt(word, correct: false);
    _moveOn();
  }

  /// Goes on to the next word. Does nothing until the current one is solved.
  void next() {
    if (_disposed || !_solved) {
      return;
    }
    _moveOn();
  }

  /// Starts over with a new random order of the words.
  void restart() {
    _abandonListening();
    _reset();
    session.restart();
    _notify();
  }

  /// Cancels everything scheduled and closes the microphone; the game ignores
  /// everything afterwards.
  void dispose() {
    _abandonListening();
    _disposed = true;
    _hideHelp();
    _listeners.clear();
  }

  bool _isCurrent(int id) => !_disposed && id == _listenId;

  void _judge(WordPair word, SpeechHearing hearing) {
    _heard = hearing.alternatives.isEmpty ? '' : hearing.alternatives.first;
    final decision = decideSpokenAnswer(
      expected: session.acceptedAnswers(word),
      heard: hearing.alternatives,
    );
    if (decision.kind == MatchKind.nothing) {
      _finishListening(SpeakingFeedback.nothing);
      return;
    }
    session.recordAttempt(word, correct: decision.accepted);
    if (decision.accepted) {
      _solved = true;
      _hideHelp();
      _finishListening(SpeakingFeedback.correct);
      return;
    }
    _wrongAttempts++;
    if (_wrongAttempts >= maxAttempts) {
      _giveUp();
    }
    _finishListening(SpeakingFeedback.wrong);
  }

  void _finishListening(SpeakingFeedback feedback) {
    _listening = false;
    _partial = '';
    _feedback = feedback;
    _notify();
  }

  /// Forgets a running listening: its result is ignored when it arrives and
  /// the microphone is closed.
  void _abandonListening() {
    if (_listening) {
      _listenId++;
      _listening = false;
      _partial = '';
      engine.stop().ignore();
    }
  }

  void _moveOn() {
    _reset();
    session.advance();
    _notify();
  }

  /// The attempts are used up: shows the right answer like the help does,
  /// and moves on when it has been shown for [helpDuration]. The outcome of
  /// the word stays what the first thing that happened to it made it.
  void _giveUp() {
    _givenUp = true;
    _helpRevision++;
    _cancelHelp?.call();
    _helpVisible = true;
    _cancelHelp = _schedule(helpDuration, () {
      _cancelHelp = null;
      if (_disposed) {
        return;
      }
      _moveOn();
    });
  }

  void _reset() {
    _hideHelp();
    _solved = false;
    _givenUp = false;
    _wrongAttempts = 0;
    _heard = '';
    _partial = '';
    _feedback = SpeakingFeedback.none;
  }

  void _hideHelp() {
    _cancelHelp?.call();
    _cancelHelp = null;
    _helpVisible = false;
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}

/// The English words of [deck] that the recogniser is told to expect.
List<String> speakingHintsOf(Deck deck) => [
  for (final word in deck.words) ...word.acceptedEnglish,
];
