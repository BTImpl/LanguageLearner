import 'dart:io';

import 'package:languagelearner/features/photo_quiz/data/photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_option.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_question.dart';

/// A built-in quiz, so the photo-quiz screens work without the backend.
///
/// The image is not read: every photo gives [samplePhotoQuiz]. [delay] makes
/// the call take that long, to try the "processing" screen.
class FakePhotoQuizRepository implements PhotoQuizRepository {
  FakePhotoQuizRepository({this.delay = Duration.zero});

  final Duration delay;

  @override
  Future<PhotoQuiz> createFromImage(File image) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return samplePhotoQuiz();
  }
}

/// A quiz with four questions that have two, three, four and five options,
/// one of them with a long text, like a real worksheet.
///
/// [skippedQuestions] is how many questions the quiz says were left out.
PhotoQuiz samplePhotoQuiz({int skippedQuestions = 0}) => PhotoQuiz(
  title: 'Grammar – Worksheet 3',
  skippedQuestions: skippedQuestions,
  questions: [
    PhotoQuizQuestion(
      number: 1,
      text: 'She ___ to school every day.',
      options: const [
        PhotoQuizOption(label: 'a', text: 'go'),
        PhotoQuizOption(label: 'b', text: 'goes'),
        PhotoQuizOption(label: 'c', text: 'going'),
        PhotoQuizOption(label: 'd', text: 'gone'),
      ],
    ),
    PhotoQuizQuestion(
      number: 2,
      text: 'London is the capital of England.',
      options: const [
        PhotoQuizOption(label: 'a', text: 'True'),
        PhotoQuizOption(label: 'b', text: 'False'),
      ],
    ),
    PhotoQuizQuestion(
      number: 3,
      text:
          'After the meeting had finished, the manager asked everyone to '
          'stay behind because she wanted to talk about the new schedule '
          'for the following month. Which sentence is true?',
      options: const [
        PhotoQuizOption(
          label: 'a',
          text: 'The manager wanted to talk to everyone after the meeting.',
        ),
        PhotoQuizOption(
          label: 'b',
          text: 'Everyone left before the meeting had finished.',
        ),
        PhotoQuizOption(label: 'c', text: 'The schedule was for last month.'),
      ],
    ),
    PhotoQuizQuestion(
      number: 4,
      text: 'I ___ my homework right now.',
      options: const [
        PhotoQuizOption(label: 'a', text: 'do'),
        PhotoQuizOption(label: 'b', text: 'am doing'),
        PhotoQuizOption(label: 'c', text: 'does'),
        PhotoQuizOption(label: 'd', text: 'did'),
        PhotoQuizOption(label: 'e', text: 'have done'),
      ],
    ),
  ],
);
