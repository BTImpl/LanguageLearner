import 'dart:math';

import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/quiz/quiz_option.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/schedule.dart';

/// The rules of the multiple-choice game, independent of any screen.
///
/// The words of the [session] are asked one by one. Every question has
/// [optionCount] answers: the right one and three wrong ones taken at random
/// from the [pool] (the whole deck), in random order. No two answers have the
/// same text, so a word with the same translation as the asked one never
/// appears as a wrong answer.
///
/// A wrong choice turns [QuizOptionState.wrong] and stays so, the student
/// tries again. The right choice turns [QuizOptionState.correct] and the next
/// question follows after [correctDelay]. Only the first choice of a word
/// counts: `firstTry` if it was right, `wrongFirst` otherwise.
///
/// A deck that cannot give three wrong answers to every word is not
/// [isPlayable]; the game then has no question and ignores everything.
class QuizGame {
  QuizGame({
    required this.session,
    Iterable<WordPair>? pool,
    Random? random,
    Schedule? schedule,
    this.correctDelay = const Duration(milliseconds: 400),
  }) : _pool = List.unmodifiable(pool ?? session.words),
       _random = random ?? Random(),
       _schedule = schedule ?? timerSchedule {
    _isPlayable = session.words.every(
      (word) => _candidates(word).length >= optionCount - 1,
    );
    if (_isPlayable) {
      _buildOptions();
    }
  }

  /// The number of answers of a question.
  static const optionCount = 4;

  final RoundSession session;
  final Duration correctDelay;

  final List<WordPair> _pool;
  final Random _random;
  final Schedule _schedule;
  final _listeners = <void Function()>[];
  final _pending = <Cancel>[];
  late final bool _isPlayable;
  var _options = <QuizOption>[];
  var _locked = false;
  var _disposed = false;

  /// Whether the deck has enough different words for the game. When it does
  /// not, the screen should say so instead of starting.
  bool get isPlayable => _isPlayable;

  /// The word that is asked, `null` when the round is finished or the game is
  /// not playable.
  WordPair? get current => _isPlayable ? session.current : null;

  /// The answers of the current question, empty when there is none.
  List<QuizOption> get options => List.unmodifiable(_options);

  /// The number of words in the round.
  int get total => session.total;

  /// The number of words that are done, i.e. the position of the question.
  int get index => session.index;

  bool get isFinished => session.isFinished;

  /// The outcome so far, see [RoundSession.result].
  RoundResult get result => session.result;

  /// How many words were answered right at the first choice so far.
  int get firstTryCount => session.result.firstTry;

  /// How many words were answered wrong at the first choice so far.
  int get wrongFirstCount => session.result.wrongFirst;

  /// Calls [listener] after every change.
  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// The student chose the answer that comes from [word].
  ///
  /// Chosen options and every choice while the right answer is shown are
  /// ignored.
  void choose(WordPair word) {
    final asked = current;
    if (_disposed || _locked || asked == null) {
      return;
    }
    final position = _options.indexWhere((option) => option.word.id == word.id);
    if (position < 0 || _options[position].state != QuizOptionState.idle) {
      return;
    }
    final option = _options[position];
    if (option.isCorrect) {
      _locked = true;
      _setState(position, QuizOptionState.correct);
      session.recordAttempt(asked, correct: true);
      _after(correctDelay, _next);
    } else {
      _setState(position, QuizOptionState.wrong);
      session.recordAttempt(asked, correct: false);
    }
    _notify();
  }

  /// Starts over with a new random order of the words.
  void restart() {
    _cancelPending();
    _locked = false;
    session.restart();
    _options = [];
    if (_isPlayable) {
      _buildOptions();
    }
    _notify();
  }

  /// Cancels everything scheduled; the game ignores choices afterwards.
  void dispose() {
    _disposed = true;
    _cancelPending();
    _listeners.clear();
  }

  void _next() {
    _locked = false;
    session.advance();
    _buildOptions();
  }

  void _buildOptions() {
    final asked = session.current;
    if (asked == null) {
      _options = [];
      return;
    }
    final wrong = RoundSession.shuffled(
      _candidates(asked),
      _random,
    ).take(optionCount - 1);
    _options = [
      for (final word in RoundSession.shuffled([asked, ...wrong], _random))
        QuizOption(
          word: word,
          text: session.answerText(word),
          isCorrect: word.id == asked.id,
        ),
    ];
  }

  /// The words that can be a wrong answer to [asked]: not the word itself, no
  /// answer text equal to an accepted answer of it, and every text only once.
  List<WordPair> _candidates(WordPair asked) {
    final blocked = {
      _key(session.answerText(asked)),
      for (final text in session.acceptedAnswers(asked)) _key(text),
    };
    final seen = <String>{};
    final result = <WordPair>[];
    for (final other in _pool) {
      if (other.id == asked.id) {
        continue;
      }
      final accepted = session.acceptedAnswers(other);
      if (accepted.any((text) => blocked.contains(_key(text)))) {
        continue;
      }
      final key = _key(session.answerText(other));
      if (blocked.contains(key) || !seen.add(key)) {
        continue;
      }
      result.add(other);
    }
    return result;
  }

  /// Texts that differ only in case or spacing are the same answer.
  String _key(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  void _setState(int position, QuizOptionState state) {
    _options = [
      for (var i = 0; i < _options.length; i++)
        if (i == position) _options[i].withState(state) else _options[i],
    ];
  }

  void _after(Duration delay, void Function() action) {
    late final Cancel cancel;
    cancel = _schedule(delay, () {
      _pending.remove(cancel);
      if (_disposed) {
        return;
      }
      action();
      _notify();
    });
    _pending.add(cancel);
  }

  void _cancelPending() {
    for (final cancel in List.of(_pending)) {
      cancel();
    }
    _pending.clear();
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}
