import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/schedule.dart';
import 'package:languagelearner/features/play/typing/answer_matcher.dart';

/// What a [TypingGame.submit] did.
enum SubmitResult {
  /// The answer was right; the student can go on with [TypingGame.next].
  correct,

  /// The answer was wrong; the student can try again.
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
/// answer can be corrected as often as needed; after the right one the
/// student moves on with [next].
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
  }) : _schedule = schedule ?? timerSchedule;

  final RoundSession session;

  /// How long the help shows the right answer.
  final Duration helpDuration;

  final Schedule _schedule;
  final _listeners = <void Function()>[];
  Cancel? _cancelHelp;
  var _solved = false;
  var _helpVisible = false;
  var _feedback = TypingFeedback.none;
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

  /// Whether the help is showing the right answer now.
  bool get helpVisible => _helpVisible;

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
    }
    _notify();
    return correct ? SubmitResult.correct : SubmitResult.wrong;
  }

  /// The student asked for help: the right answer shows for [helpDuration].
  /// Asking again keeps it showing for another [helpDuration].
  void requestHelp() {
    final word = current;
    if (_disposed || _solved || word == null) {
      return;
    }
    session.recordHelp(word);
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

  void _reset() {
    _hideHelp();
    _solved = false;
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
