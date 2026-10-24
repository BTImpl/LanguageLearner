import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_answers.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_question.dart';

/// Where the student stands while filling in a [PhotoQuiz]: the choices so
/// far and the question that is on the screen.
///
/// There is no right or wrong and no score: the worksheet does not say which
/// option is correct, the teacher marks the sent answers.
///
/// A question is named by its position in the quiz (`0` is the first one).
@immutable
class PhotoQuizFillState {
  const PhotoQuizFillState({required this.answers, this.currentIndex = 0});

  final PhotoQuizAnswers answers;

  /// The position of the question on the screen.
  final int currentIndex;

  PhotoQuiz get quiz => answers.quiz;

  /// How many questions the quiz has.
  int get questionCount => quiz.questions.length;

  /// The question on the screen.
  PhotoQuizQuestion get currentQuestion => quiz.questions[currentIndex];

  /// The position of the option chosen for the question on the screen, or
  /// null when it is not answered.
  int? get selectedOptionIndex => answers.selectedIndex(currentIndex);

  /// How many questions have a chosen option.
  int get answeredCount => answers.answeredCount;

  /// The positions of the questions that have no chosen option, in order.
  List<int> get unansweredQuestions => answers.unansweredQuestions;

  /// Whether every question has a chosen option. The quiz may be sent without
  /// it too: the unanswered questions are then sent as "no answer".
  bool get isComplete => answers.isComplete;

  /// Whether the question on the screen is the first one.
  bool get isFirst => currentIndex == 0;

  /// Whether the question on the screen is the last one.
  bool get isLast => currentIndex == questionCount - 1;

  @override
  bool operator ==(Object other) =>
      other is PhotoQuizFillState &&
      other.answers == answers &&
      other.currentIndex == currentIndex;

  @override
  int get hashCode => Object.hash(answers, currentIndex);

  @override
  String toString() =>
      'PhotoQuizFillState(question ${currentIndex + 1} of $questionCount, '
      '$answeredCount answered)';
}

/// The filling in of one quiz.
///
/// It lives only while the fill-in screen is open: nothing is saved, and it
/// starts again (no choice, first question) the next time. It does not use
/// the round engine of the practice modes: nothing is shuffled and no result
/// is collected.
final photoQuizFillProvider = NotifierProvider.autoDispose
    .family<PhotoQuizFill, PhotoQuizFillState, PhotoQuiz>(PhotoQuizFill.new);

/// Fills in [quiz]. It needs at least one question.
class PhotoQuizFill extends Notifier<PhotoQuizFillState> {
  PhotoQuizFill(this.quiz);

  final PhotoQuiz quiz;

  @override
  PhotoQuizFillState build() {
    if (quiz.questions.isEmpty) {
      throw ArgumentError.value(quiz, 'quiz', 'Has no question to fill in');
    }
    return PhotoQuizFillState(answers: PhotoQuizAnswers.empty(quiz));
  }

  /// Chooses the option at [optionIndex] for the question on the screen,
  /// replacing an earlier choice. Choosing the option that is already chosen
  /// takes the choice back. Throws a [RangeError] for an option the question
  /// does not have.
  void select(int optionIndex) {
    final current = state;
    final index = current.currentIndex;
    final answers = current.selectedOptionIndex == optionIndex
        ? current.answers.clear(index)
        : current.answers.select(index, optionIndex);
    state = PhotoQuizFillState(answers: answers, currentIndex: index);
  }

  /// Goes to the next question. At the last one nothing happens.
  void next() {
    if (!state.isLast) {
      goTo(state.currentIndex + 1);
    }
  }

  /// Goes to the previous question. At the first one nothing happens.
  void previous() {
    if (!state.isFirst) {
      goTo(state.currentIndex - 1);
    }
  }

  /// Goes to the question at [index]. Throws a [RangeError] for a position
  /// that is not a question of the quiz.
  void goTo(int index) {
    RangeError.checkValidIndex(index, quiz.questions, 'index');
    state = PhotoQuizFillState(answers: state.answers, currentIndex: index);
  }
}
