import 'package:flutter/foundation.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_option.dart';

/// The option the student chose for each question of a [PhotoQuiz], or none.
///
/// A question and an option are named by their position in the quiz, not by
/// the printed number or label, which can repeat on a worksheet. The object
/// cannot be changed: [select] and [clear] give a new one.
///
/// There is no right or wrong here; the worksheet does not say which option is
/// correct, the teacher marks the sent answers.
@immutable
class PhotoQuizAnswers {
  /// No question is answered yet.
  PhotoQuizAnswers.empty(PhotoQuiz quiz)
    : this._(quiz, List<int?>.filled(quiz.questions.length, null));

  PhotoQuizAnswers._(this.quiz, List<int?> selected)
    : _selected = List.unmodifiable(selected);

  final PhotoQuiz quiz;

  // The position of the chosen option of each question, null when none.
  final List<int?> _selected;

  /// The position of the option chosen for the question at [questionIndex], or
  /// null when it is not answered. Throws a [RangeError] for a position that
  /// is not a question of the quiz.
  int? selectedIndex(int questionIndex) {
    RangeError.checkValidIndex(questionIndex, _selected, 'questionIndex');
    return _selected[questionIndex];
  }

  /// The option chosen for the question at [questionIndex], or null.
  PhotoQuizOption? selectedOption(int questionIndex) {
    final index = selectedIndex(questionIndex);
    return index == null ? null : quiz.questions[questionIndex].options[index];
  }

  /// Whether the question at [questionIndex] has a chosen option.
  bool isAnswered(int questionIndex) => selectedIndex(questionIndex) != null;

  /// How many questions have a chosen option.
  int get answeredCount => _selected.where((index) => index != null).length;

  /// The positions of the questions that have no chosen option, in order.
  List<int> get unansweredQuestions => [
    for (final (index, selected) in _selected.indexed)
      if (selected == null) index,
  ];

  /// Whether every question has a chosen option.
  bool get isComplete => answeredCount == _selected.length;

  /// Chooses the option at [optionIndex] for the question at [questionIndex],
  /// replacing an earlier choice. Choosing the option that is already chosen
  /// changes nothing; use [clear] to take a choice back.
  ///
  /// Throws a [RangeError] for a question or an option that does not exist.
  PhotoQuizAnswers select(int questionIndex, int optionIndex) {
    RangeError.checkValidIndex(questionIndex, _selected, 'questionIndex');
    RangeError.checkValidIndex(
      optionIndex,
      quiz.questions[questionIndex].options,
      'optionIndex',
    );
    if (_selected[questionIndex] == optionIndex) {
      return this;
    }
    return PhotoQuizAnswers._(
      quiz,
      [..._selected]..[questionIndex] = optionIndex,
    );
  }

  /// Takes back the choice for the question at [questionIndex].
  PhotoQuizAnswers clear(int questionIndex) {
    if (selectedIndex(questionIndex) == null) {
      return this;
    }
    return PhotoQuizAnswers._(quiz, [..._selected]..[questionIndex] = null);
  }

  @override
  bool operator ==(Object other) =>
      other is PhotoQuizAnswers &&
      other.quiz == quiz &&
      listEquals(other._selected, _selected);

  @override
  int get hashCode => Object.hash(quiz, Object.hashAll(_selected));

  @override
  String toString() =>
      'PhotoQuizAnswers($answeredCount of ${_selected.length})';
}
