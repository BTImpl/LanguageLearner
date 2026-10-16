import 'dart:math';

import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/features/play/matching/matching_game.dart';
import 'package:languagelearner/features/play/quiz/quiz_game.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/schedule.dart';
import 'package:languagelearner/features/play/typing/typing_game.dart';

/// The kinds of task the Mix mode draws from.
enum MixStepType { typing, quiz, matching }

/// A finished step: its kind and how many words it used up.
typedef MixStepRecord = ({MixStepType type, int words});

/// The scheduler of the Mix mode, independent of any screen.
///
/// The student does not pick a format. Going through the words of the
/// [session] in their random order, every step draws a task at random:
///
/// - typing ([TypingGame]) and quiz ([QuizGame]) use up one word;
/// - matching ([MatchingGame], one page) uses up as many words as it shows
///   pairs: [pairsPerPage], or all that are left if there are fewer.
///
/// Rules of the draw:
///
/// - matching only if at least 2 words are left;
/// - quiz only if the deck can give every word three wrong answers in both
///   directions (see [QuizGame.isPlayableIn]); the wrong answers come from
///   the whole deck, not only from the words that are left;
/// - never two matching steps in a row.
///
/// A typing or quiz step also draws its own direction, English to Hungarian
/// or the other way round with equal chance, and gives it to the word with
/// [RoundSession.setPromptLanguage]. The direction belongs to the step, not
/// to the round, and the [RoundSession.promptLanguage] of the session (the
/// setting of the student) plays no part in it: with the same random source
/// the draw is the same for any setting. Matching shows both languages and
/// has no direction.
///
/// The step games work on the shared [session], so their outcomes end up in
/// one [result]. The game finishes after the last word.
class MixGame {
  MixGame({
    required this.session,
    required this.pairsPerPage,
    Random? random,
    Schedule? schedule,
  }) : assert(pairsPerPage >= 2, 'A matching step needs at least two pairs.'),
       _random = random ?? Random(),
       _schedule = schedule ?? timerSchedule {
    _quizAllowed = _canPlayQuiz();
    _startStep();
  }

  final RoundSession session;
  final int pairsPerPage;

  final Random _random;
  final Schedule _schedule;
  final _listeners = <void Function()>[];
  final _history = <MixStepRecord>[];
  late final bool _quizAllowed;
  MixStepType? _type;
  MixStepType? _lastType;
  TypingGame? _typing;
  QuizGame? _quiz;
  MatchingGame? _matching;
  var _stepStart = 0;
  var _stepNumber = 0;
  var _disposed = false;

  /// The kind of the current step, `null` when the round is finished.
  MixStepType? get stepType => _type;

  /// The game of the current step when it is typing, otherwise `null`.
  TypingGame? get typing => _typing;

  /// The game of the current step when it is a quiz, otherwise `null`.
  QuizGame? get quiz => _quiz;

  /// The game of the current step when it is matching, otherwise `null`.
  MatchingGame? get matching => _matching;

  /// The direction the current typing or quiz step asks in, `null` for
  /// matching and when the round is finished.
  PromptLanguage? get stepPromptLanguage {
    final word = switch (_type) {
      MixStepType.typing || MixStepType.quiz => session.current,
      MixStepType.matching || null => null,
    };
    return word == null ? null : session.promptLanguageOf(word);
  }

  /// Counts the steps started so far, from 1. A screen can tell a new step
  /// from a change inside the step by it.
  int get stepNumber => _stepNumber;

  /// The steps that are over, in order.
  List<MixStepRecord> get completedSteps => List.unmodifiable(_history);

  int get total => session.total;

  /// The number of words used up by finished steps.
  int get index => session.index;

  bool get isFinished => session.isFinished;

  /// The outcome so far, of all kinds of step together.
  RoundResult get result => session.result;

  /// Calls [listener] after every change, in the current step or of the step.
  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Starts over with a new random order of the words.
  void restart() {
    _disposeStep();
    _history.clear();
    _lastType = null;
    session.restart();
    _startStep();
    _notify();
  }

  /// Cancels everything scheduled; the game ignores everything afterwards.
  void dispose() {
    _disposed = true;
    _disposeStep();
    _listeners.clear();
  }

  /// Whether the quiz can be played with this deck: whichever direction a
  /// step draws, every word has enough wrong answers.
  bool _canPlayQuiz() => PromptLanguage.values.every(
    (language) => QuizGame.isPlayableIn(session, language),
  );

  void _startStep() {
    if (session.isFinished) {
      return;
    }
    final remaining = session.total - session.index;
    final allowed = [
      MixStepType.typing,
      if (_quizAllowed) MixStepType.quiz,
      if (remaining >= 2 && _lastType != MixStepType.matching)
        MixStepType.matching,
    ];
    final type = allowed[_random.nextInt(allowed.length)];
    _type = type;
    _stepStart = session.index;
    _stepNumber++;
    if (type != MixStepType.matching) {
      final direction = _random.nextBool()
          ? PromptLanguage.english
          : PromptLanguage.hungarian;
      session.setPromptLanguage(session.current!, direction);
    }
    switch (type) {
      case MixStepType.typing:
        _typing = TypingGame(session: session, schedule: _schedule)
          ..addListener(_onStepChanged);
      case MixStepType.quiz:
        _quiz = QuizGame(session: session, random: _random, schedule: _schedule)
          ..addListener(_onStepChanged);
      case MixStepType.matching:
        _matching = MatchingGame(
          session: session,
          pairsPerPage: pairsPerPage,
          singlePage: true,
          random: _random,
          schedule: _schedule,
        )..addListener(_onStepChanged);
    }
  }

  /// Every kind of step moves the session forward when it is over.
  void _onStepChanged() {
    if (_disposed) {
      return;
    }
    if (session.index > _stepStart) {
      _history.add((type: _type!, words: session.index - _stepStart));
      _lastType = _type;
      _disposeStep();
      _startStep();
    }
    _notify();
  }

  void _disposeStep() {
    _typing?.dispose();
    _quiz?.dispose();
    _matching?.dispose();
    _typing = null;
    _quiz = null;
    _matching = null;
    _type = null;
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}
