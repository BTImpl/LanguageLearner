import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_fill.dart';

void main() {
  // Four questions with 4, 2, 3 and 5 options.
  final quiz = samplePhotoQuiz();
  late ProviderContainer container;

  PhotoQuizFillState state() => container.read(photoQuizFillProvider(quiz));
  PhotoQuizFill fill() => container.read(photoQuizFillProvider(quiz).notifier);

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('the start', () {
    test('is the first question with nothing chosen', () {
      expect(state().currentIndex, 0);
      expect(state().currentQuestion, quiz.questions.first);
      expect(state().selectedOptionIndex, isNull);
      expect(state().answeredCount, 0);
      expect(state().isComplete, isFalse);
      expect(state().isFirst, isTrue);
      expect(state().isLast, isFalse);
      expect(state().questionCount, 4);
      expect(state().quiz, quiz);
    });

    test('a quiz without questions cannot be filled in', () {
      final empty = PhotoQuiz(questions: const []);

      expect(
        () => container.read(photoQuizFillProvider(empty)),
        throwsA(anything),
      );
    });
  });

  group('choosing', () {
    test('an option is chosen for the question on the screen', () {
      fill().select(2);

      expect(state().selectedOptionIndex, 2);
      expect(state().answeredCount, 1);
      expect(state().answers.selectedOption(0), quiz.questions[0].options[2]);
      expect(state().currentIndex, 0);
    });

    test('the choice can be changed', () {
      fill()
        ..select(0)
        ..select(3);

      expect(state().selectedOptionIndex, 3);
      expect(state().answeredCount, 1);
    });

    test('choosing the chosen option again takes the choice back', () {
      fill()
        ..select(1)
        ..select(1);

      expect(state().selectedOptionIndex, isNull);
      expect(state().answeredCount, 0);
    });

    test('a choice is kept while moving on and back', () {
      fill()
        ..select(2)
        ..next()
        ..select(1)
        ..previous();

      expect(state().selectedOptionIndex, 2);
      fill().next();
      expect(state().selectedOptionIndex, 1);
    });

    test('a choice can be changed after coming back to the question', () {
      fill()
        ..select(2)
        ..next()
        ..previous()
        ..select(0);

      expect(state().selectedOptionIndex, 0);
      expect(state().answeredCount, 1);
    });

    test('an option the question does not have is refused', () {
      fill().goTo(1); // two options

      expect(() => fill().select(2), throwsRangeError);
      expect(() => fill().select(-1), throwsRangeError);
      expect(state().answeredCount, 0);
    });

    test('nothing says whether a choice is right', () {
      fill().select(0);

      // The state has choices only: no score, no correctness.
      expect(state().toString(), contains('1 answered'));
    });
  });

  group('moving', () {
    test('next and previous step one question', () {
      fill().next();
      expect(state().currentIndex, 1);
      expect(state().currentQuestion, quiz.questions[1]);

      fill().next();
      expect(state().currentIndex, 2);

      fill().previous();
      expect(state().currentIndex, 1);
    });

    test('previous stops at the first question', () {
      fill().previous();

      expect(state().currentIndex, 0);
      expect(state().isFirst, isTrue);
    });

    test('next stops at the last question', () {
      fill()
        ..next()
        ..next()
        ..next()
        ..next()
        ..next();

      expect(state().currentIndex, 3);
      expect(state().isLast, isTrue);
      expect(state().currentQuestion, quiz.questions.last);
    });

    test('goTo jumps to a question', () {
      fill().goTo(3);
      expect(state().currentIndex, 3);

      fill().goTo(0);
      expect(state().currentIndex, 0);
    });

    test('goTo refuses a position that is not a question', () {
      expect(() => fill().goTo(4), throwsRangeError);
      expect(() => fill().goTo(-1), throwsRangeError);
      expect(state().currentIndex, 0);
    });

    test('a quiz with one question is first and last at once', () {
      final single = PhotoQuiz(questions: [quiz.questions.first]);
      final one = container.read(photoQuizFillProvider(single));

      expect(one.isFirst, isTrue);
      expect(one.isLast, isTrue);
      container.read(photoQuizFillProvider(single).notifier)
        ..next()
        ..previous();
      expect(container.read(photoQuizFillProvider(single)).currentIndex, 0);
    });
  });

  group('what is left', () {
    test('lists the unanswered questions in order', () {
      expect(state().unansweredQuestions, [0, 1, 2, 3]);

      fill()
        ..select(0)
        ..goTo(2)
        ..select(1);

      expect(state().unansweredQuestions, [1, 3]);
      expect(state().answeredCount, 2);
      expect(state().isComplete, isFalse);
    });

    test('is complete when every question has a choice', () {
      for (var i = 0; i < 4; i++) {
        fill()
          ..goTo(i)
          ..select(0);
      }

      expect(state().isComplete, isTrue);
      expect(state().unansweredQuestions, isEmpty);
      expect(state().answeredCount, 4);
    });

    test('taking a choice back makes it unanswered again', () {
      for (var i = 0; i < 4; i++) {
        fill()
          ..goTo(i)
          ..select(0);
      }

      fill().select(0); // the same option again, on the last question

      expect(state().isComplete, isFalse);
      expect(state().unansweredQuestions, [3]);
    });

    test('the quiz can be sent with questions unanswered', () {
      fill().select(0);

      // Nothing in the state stops it: the screen only warns (card LL-55).
      expect(state().unansweredQuestions, [1, 2, 3]);
      expect(state().answers.isAnswered(0), isTrue);
      expect(state().answers.isAnswered(1), isFalse);
    });
  });

  group('the life of the state', () {
    test('it is not kept: the next time it starts again', () async {
      final keep = container.listen(photoQuizFillProvider(quiz), (_, _) {});
      fill()
        ..select(1)
        ..next();
      expect(state().answeredCount, 1);

      keep.close();
      await container.pump();

      expect(state().answeredCount, 0);
      expect(state().currentIndex, 0);
    });

    test('every quiz has its own state', () {
      final other = PhotoQuiz(questions: [quiz.questions.first]);
      fill().select(0);

      expect(container.read(photoQuizFillProvider(other)).answeredCount, 0);
      expect(state().answeredCount, 1);
    });
  });

  group('equality', () {
    test('states with the same choices and position are equal', () {
      final first = state();
      fill().select(0);
      fill().select(0); // taken back

      expect(state(), first);
      expect(state().hashCode, first.hashCode);

      fill().next();
      expect(state(), isNot(first));
    });
  });
}
