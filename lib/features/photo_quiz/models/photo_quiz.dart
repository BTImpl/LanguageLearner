import 'package:flutter/foundation.dart';
import 'package:languagelearner/features/photo_quiz/models/json_reader.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_question.dart';

/// A quiz made from the photo of a printed worksheet.
///
/// It only holds what is printed on the sheet. Which option is correct is not
/// known, so the model has no correct answer. The shape matches `Quiz` of the
/// backend (card BE-14).
@immutable
class PhotoQuiz {
  /// The [questions] are copied into a list that cannot be changed.
  PhotoQuiz({
    required List<PhotoQuizQuestion> questions,
    this.title,
    this.skippedQuestions = 0,
  }) : questions = List.unmodifiable(questions);

  /// Reads the answer of `POST /api/v1/quizzes/from-image`. Throws a
  /// [FormatException] that names the field when the answer is not a quiz: a
  /// required field is missing or of the wrong type, there is no question, or
  /// a question is not valid (see [PhotoQuizQuestion.fromJson]).
  ///
  /// `title` and `skippedQuestions` are optional: a missing or blank title is
  /// null, a missing `skippedQuestions` is 0.
  factory PhotoQuiz.fromJson(Object? json) {
    final map = readObject(json, 'quiz');
    final rawQuestions = readList(map, 'questions', '');
    if (rawQuestions.isEmpty) {
      throw const FormatException('questions: expected at least one question');
    }
    return PhotoQuiz(
      title: readOptionalString(map, 'title', ''),
      questions: [
        for (final (index, question) in rawQuestions.indexed)
          PhotoQuizQuestion.fromJson(question, path: 'questions[$index]'),
      ],
      skippedQuestions: readOptionalCount(
        map,
        'skippedQuestions',
        '',
        fallback: 0,
      ),
    );
  }

  /// The exercise heading of the worksheet, or null when it has none.
  final String? title;

  /// The questions in the order of the worksheet.
  final List<PhotoQuizQuestion> questions;

  /// How many questions could not be read completely and were left out.
  final int skippedQuestions;

  @override
  bool operator ==(Object other) =>
      other is PhotoQuiz &&
      other.title == title &&
      other.skippedQuestions == skippedQuestions &&
      listEquals(other.questions, questions);

  @override
  int get hashCode =>
      Object.hash(title, skippedQuestions, Object.hashAll(questions));

  @override
  String toString() => 'PhotoQuiz($title, ${questions.length} questions)';
}
