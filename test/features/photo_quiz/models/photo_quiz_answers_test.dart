import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_answers.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_option.dart';

void main() {
  // Four questions with 4, 2, 3 and 5 options.
  final quiz = samplePhotoQuiz();

  PhotoQuizAnswers empty() => PhotoQuizAnswers.empty(quiz);

  group('a new set of answers', () {
    test('has no question answered', () {
      final answers = empty();

      expect(answers.answeredCount, 0);
      expect(answers.isComplete, isFalse);
      expect(answers.unansweredQuestions, [0, 1, 2, 3]);
      for (var index = 0; index < 4; index++) {
        expect(answers.isAnswered(index), isFalse);
        expect(answers.selectedIndex(index), isNull);
        expect(answers.selectedOption(index), isNull);
      }
    });
  });

  group('select', () {
    test('chooses an option for a question', () {
      final answers = empty().select(0, 1);

      expect(answers.isAnswered(0), isTrue);
      expect(answers.selectedIndex(0), 1);
      expect(
        answers.selectedOption(0),
        const PhotoQuizOption(label: 'b', text: 'goes'),
      );
      expect(answers.answeredCount, 1);
      expect(answers.unansweredQuestions, [1, 2, 3]);
    });

    test('leaves the other questions as they were', () {
      final answers = empty().select(1, 0).select(3, 4);

      expect(answers.selectedIndex(0), isNull);
      expect(answers.selectedIndex(1), 0);
      expect(answers.selectedIndex(2), isNull);
      expect(answers.selectedIndex(3), 4);
    });

    test('a new choice replaces the earlier one', () {
      final answers = empty().select(0, 1).select(0, 3);

      expect(answers.selectedIndex(0), 3);
      expect(answers.answeredCount, 1);
    });

    test('choosing the chosen option again changes nothing', () {
      final answers = empty().select(0, 1);

      expect(answers.select(0, 1), same(answers));
      expect(answers.selectedIndex(0), 1);
    });

    test('does not change the object it is called on', () {
      final before = empty();

      before.select(0, 1);

      expect(before.answeredCount, 0);
      expect(before.selectedIndex(0), isNull);
    });

    test('is complete once every question has a choice', () {
      var answers = empty();
      for (var index = 0; index < 4; index++) {
        expect(answers.isComplete, isFalse);
        answers = answers.select(index, 0);
      }

      expect(answers.isComplete, isTrue);
      expect(answers.unansweredQuestions, isEmpty);
      expect(answers.answeredCount, 4);
    });

    test('rejects a question that does not exist', () {
      expect(() => empty().select(-1, 0), throwsRangeError);
      expect(() => empty().select(4, 0), throwsRangeError);
    });

    test('rejects an option that the question does not have', () {
      // The second question has two options.
      expect(() => empty().select(1, 2), throwsRangeError);
      expect(() => empty().select(0, -1), throwsRangeError);
      expect(empty().select(3, 4).selectedIndex(3), 4);
    });
  });

  group('clear', () {
    test('takes the choice back', () {
      final answers = empty().select(0, 1).select(2, 0).clear(0);

      expect(answers.isAnswered(0), isFalse);
      expect(answers.selectedOption(0), isNull);
      expect(answers.selectedIndex(2), 0);
      expect(answers.unansweredQuestions, [0, 1, 3]);
    });

    test('a question without a choice stays as it is', () {
      final answers = empty().select(0, 1);

      expect(answers.clear(2), same(answers));
    });

    test('rejects a question that does not exist', () {
      expect(() => empty().clear(4), throwsRangeError);
    });
  });

  group('reading', () {
    test('rejects a question that does not exist', () {
      expect(() => empty().selectedIndex(4), throwsRangeError);
      expect(() => empty().selectedOption(-1), throwsRangeError);
      expect(() => empty().isAnswered(9), throwsRangeError);
    });

    test('a quiz with one question is complete after one choice', () {
      final single = PhotoQuiz(questions: [quiz.questions.first]);
      final answers = PhotoQuizAnswers.empty(single);

      expect(answers.isComplete, isFalse);
      expect(answers.select(0, 0).isComplete, isTrue);
    });
  });

  group('equality', () {
    test('equal when the quiz and the choices are equal', () {
      final first = empty().select(0, 1).select(2, 2);
      final second = empty().select(2, 2).select(0, 1);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('different when a choice differs', () {
      expect(empty().select(0, 1), isNot(empty().select(0, 2)));
      expect(empty().select(0, 1), isNot(empty()));
      expect(empty().select(0, 1).clear(0), empty());
    });
  });
}
