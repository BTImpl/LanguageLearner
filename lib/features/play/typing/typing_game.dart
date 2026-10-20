import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/schedule.dart';
import 'package:languagelearner/features/play/typing/answer_matcher.dart';

/// What a [TypingGame.submit] did.
enum SubmitResult {
  /// The answer was right; the student can go on with [TypingGame.next].
  correct,

  /// The answer was wrong; the student can try again. It was the last
  /// allowed attempt when [TypingGame.isGivenUp] is true: the game shows the
  /// right answer and moves on by itself.
  wrong,

  /// Nothing happened: the text was empty, the word is already solved or the
  /// round is over.
  ignored,
}

/// The feedback the screen shows under the input.
enum TypingFeedback { none, wrong, correct }

/// The rules of the exact-match (typing) game, independent of any screen.
///
/// The words of the [session] are asked one by one; the answer is typed and
/// compared with [AnswerMatcher] to every accepted answer of the word. A wrong
/// answer can be corrected, but only [maxAttempts] wrong answers are allowed
/// for a word: after the last one the game shows the right answer for
/// [helpDuration] and then moves on to the next word by itself, so a word that
/// cannot be typed (for example because of a hidden character) never blocks
/// the round. After the right answer the student moves on with [next].
///
/// [requestHelp] shows the right answer for [helpDuration] and can be used
/// again and again. The first thing that happens to a word decides its
/// outcome: `firstTry` if it was answered right without help, `withHelp` if
/// help was asked for before anything else, `wrongFirst` if the first
/// submitted answer was wrong.
class TypingGame {
  TypingGame({
    required this.session,
    Schedule? schedule,
    this.helpDuration = const Duration(seconds: 3),
    this.maxAttempts = defaultMaxAttempts,
  }) : assert(maxAttempts >= 1, 'At least one attempt is needed.'),
       _schedule = schedule ?? timerSchedule;

  /// How many wrong answers a word accepts by default.
  static const defaultMaxAttempts = 3;

  final RoundSession session;

  /// How many wrong answers the current word accepts before the game shows
  /// the right one and moves on.
  final int maxAttempts;

  /// How long the help shows the right answer.
  final Duration helpDuration;

  final Schedule _schedule;
  final _listeners = <void Function()>[];
  Cancel? _cancelHelp;
  var _solved = false;
  var _helpVisible = false;
  var _helpRevision = 0;
  var _feedback = TypingFeedback.none;
  var _wrongAttempts = 0;
  var _givenUp = false;
  var _disposed = false;

  /// The word that is asked, `null` when the round is finished.
  WordPair? get current => session.current;

  int get total => session.total;

  /// The number of words that are done, i.e. the position of the question.
  int get index => session.index;

  bool get isFinished => session.isFinished;

  /// Whether the current word has been answered right.
  bool get isSolved => _solved;

  /// What to show under the input.
  TypingFeedback get feedback => _feedback;

  /// How many wrong answers the current word has had.
  int get wrongAttempts => _wrongAttempts;

  /// How many wrong answers the current word still accepts.
  int get attemptsLeft => maxAttempts - _wrongAttempts;

  /// Whether the next wrong answer is the last one (and only if there is more
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

  /// The outcome so far, see [RoundSession.result].
  RoundResult get result => session.result;

  /// Calls [listener] after every change.
  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// The student sent [input] as the answer.
  SubmitResult submit(String input) {
    final word = current;
    if (_disposed ||
        _solved ||
        _givenUp ||
        word == null ||
        AnswerMatcher.normalize(input).isEmpty) {
      return SubmitResult.ignored;
    }
    final correct = AnswerMatcher.matches(input, session.acceptedAnswers(word));
    session.recordAttempt(word, correct: correct);
    if (correct) {
      _solved = true;
      _hideHelp();
      _feedback = TypingFeedback.correct;
    } else {
      _feedback = TypingFeedback.wrong;
      _wrongAttempts++;
      if (_wrongAttempts >= maxAttempts) {
        _giveUp();
      }
    }
    _notify();
    return correct ? SubmitResult.correct : SubmitResult.wrong;
  }

  /// The student asked for help: the right answer shows for [helpDuration].
  /// Asking again keeps it showing for another [helpDuration].
  void requestHelp() {
    final word = current;
    if (_disposed || _solved || _givenUp || word == null) {
      return;
    }
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

  /// Goes on to the next word. Does nothing until the current one is solved.
  void next() {
    if (_disposed || !_solved) {
      return;
    }
    _reset();
    session.advance();
    _notify();
  }

  /// Starts over with a new random order of the words.
  void restart() {
    _reset();
    session.restart();
    _notify();
  }

  /// Cancels everything scheduled; the game ignores everything afterwards.
  void dispose() {
    _disposed = true;
    _hideHelp();
    _listeners.clear();
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
      _reset();
      session.advance();
      _notify();
    });
  }

  void _reset() {
    _hideHelp();
    _solved = false;
    _givenUp = false;
    _wrongAttempts = 0;
    _feedback = TypingFeedback.none;
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
