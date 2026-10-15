import 'package:flutter/foundation.dart';
import 'package:languagelearner/core/models/word_pair.dart';

/// What an answer option looks like and whether it can be chosen.
enum QuizOptionState {
  /// Not chosen yet; can be chosen.
  idle,

  /// A wrong choice. It stays so for the rest of the question.
  wrong,

  /// The right choice; the next question follows after a short while.
  correct,
}

/// One of the answers of a question.
@immutable
class QuizOption {
  const QuizOption({
    required this.word,
    required this.text,
    required this.isCorrect,
    this.state = QuizOptionState.idle,
  });

  /// The word the answer text comes from. For the correct option this is the
  /// word that is asked.
  final WordPair word;

  /// The answer text shown on the option.
  final String text;

  final bool isCorrect;
  final QuizOptionState state;

  QuizOption withState(QuizOptionState state) =>
      QuizOption(word: word, text: text, isCorrect: isCorrect, state: state);
}
