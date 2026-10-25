import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_option.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_question.dart';
import 'package:languagelearner/features/photo_quiz/saved/quiz_fingerprint.dart';

PhotoQuiz _quiz(
  String question,
  List<String> options, {
  String? title,
  int number = 1,
}) => PhotoQuiz(
  title: title,
  questions: [
    PhotoQuizQuestion(
      number: number,
      text: question,
      options: [
        for (final (i, text) in options.indexed)
          PhotoQuizOption(label: String.fromCharCode(97 + i), text: text),
      ],
    ),
  ],
);

void main() {
  group('quizFingerprint', () {
    test('is the same for the same quiz', () {
      expect(
        quizFingerprint(samplePhotoQuiz()),
        quizFingerprint(samplePhotoQuiz()),
      );
    });

    test('ignores case, extra spaces and punctuation', () {
      final a = _quiz('She is a teacher.', ['am', 'is', 'are']);
      final b = _quiz('  she  IS a teacher ', ['Am', 'is.', ' are ']);
      expect(quizFingerprint(a), quizFingerprint(b));
    });

    test('ignores the title and the printed number', () {
      final a = _quiz('Where is Tom?', ['here', 'there'], title: 'Test 1');
      final b = _quiz('Where is Tom?', ['here', 'there'], number: 7);
      expect(quizFingerprint(a), quizFingerprint(b));
    });

    test('differs when a word of the question differs', () {
      final a = _quiz('Where is Tom?', ['here', 'there']);
      final b = _quiz('Where is Tim?', ['here', 'there']);
      expect(quizFingerprint(a), isNot(quizFingerprint(b)));
    });

    test('differs when the options are in another order', () {
      final a = _quiz('Where is Tom?', ['here', 'there']);
      final b = _quiz('Where is Tom?', ['there', 'here']);
      expect(quizFingerprint(a), isNot(quizFingerprint(b)));
    });

    test('differs when a question is missing', () {
      final full = samplePhotoQuiz();
      expect(
        quizFingerprint(full),
        isNot(quizFingerprint(full.withoutQuestionAt(0))),
      );
    });

    test('keeps accented letters apart', () {
      final a = _quiz('Hol van a kút?', ['itt', 'ott']);
      final b = _quiz('Hol van a kut?', ['itt', 'ott']);
      expect(quizFingerprint(a), isNot(quizFingerprint(b)));
    });

    test('does not mix up where one text ends and the next starts', () {
      final a = _quiz('ab', ['c', 'd']);
      final b = _quiz('a', ['bc', 'd']);
      expect(quizFingerprint(a), isNot(quizFingerprint(b)));
    });
  });
}
