import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_option.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_question.dart';

/// An answer of `POST /api/v1/quizzes/from-image`, as the backend sends it.
const _quizText = '''
{
  "title": "Unit 5 - Travel",
  "questions": [
    {
      "number": 1,
      "text": "She ___ to the airport.",
      "options": [
        {"label": "a", "text": "go"},
        {"label": "b", "text": "went"},
        {"label": "c", "text": "gone"}
      ]
    },
    {
      "number": 2,
      "text": "London is in England.",
      "options": [
        {"label": "a", "text": "True"},
        {"label": "b", "text": "False"}
      ]
    }
  ],
  "skippedQuestions": 1
}
''';

/// The decoded answer, a new copy on every call so a test can change it.
Map<String, Object?> quizJson() =>
    jsonDecode(_quizText) as Map<String, Object?>;

/// The quiz JSON with [change] applied to its first question.
Map<String, Object?> withFirstQuestion(
  void Function(Map<String, Object?> question) change,
) {
  final json = quizJson();
  final questions = json['questions']! as List<Object?>;
  change(questions.first! as Map<String, Object?>);
  return json;
}

void main() {
  group('PhotoQuiz.fromJson', () {
    test('reads the title, the questions and the skipped count', () {
      final quiz = PhotoQuiz.fromJson(quizJson());

      expect(quiz.title, 'Unit 5 - Travel');
      expect(quiz.skippedQuestions, 1);
      expect(quiz.questions, hasLength(2));
      expect(quiz.questions[0].number, 1);
      expect(quiz.questions[0].text, 'She ___ to the airport.');
      expect(quiz.questions[0].options, const [
        PhotoQuizOption(label: 'a', text: 'go'),
        PhotoQuizOption(label: 'b', text: 'went'),
        PhotoQuizOption(label: 'c', text: 'gone'),
      ]);
      expect(quiz.questions[1].options, hasLength(2));
    });

    test('keeps the order of the questions and the options', () {
      final quiz = PhotoQuiz.fromJson(quizJson());

      expect([for (final question in quiz.questions) question.number], [1, 2]);
      expect(
        [for (final option in quiz.questions[0].options) option.label],
        ['a', 'b', 'c'],
      );
    });

    test('a missing or null title is null', () {
      final missing = quizJson()..remove('title');
      final nullTitle = quizJson()..['title'] = null;

      expect(PhotoQuiz.fromJson(missing).title, isNull);
      expect(PhotoQuiz.fromJson(nullTitle).title, isNull);
    });

    test('a blank title is null and the whitespace around one is dropped', () {
      expect(PhotoQuiz.fromJson(quizJson()..['title'] = '  ').title, isNull);
      expect(
        PhotoQuiz.fromJson(quizJson()..['title'] = '  Unit 5  ').title,
        'Unit 5',
      );
    });

    test('a missing skippedQuestions is 0', () {
      final json = quizJson()..remove('skippedQuestions');

      expect(PhotoQuiz.fromJson(json).skippedQuestions, 0);
    });

    test('trims the texts', () {
      final json = withFirstQuestion((question) {
        question['text'] = '  She ___ to the airport.  ';
        (question['options']! as List<Object?>)[0] = {
          'label': ' a ',
          'text': ' go ',
        };
      });

      final question = PhotoQuiz.fromJson(json).questions.first;

      expect(question.text, 'She ___ to the airport.');
      expect(
        question.options.first,
        const PhotoQuizOption(label: 'a', text: 'go'),
      );
    });

    test('accepts from 2 to 5 options', () {
      for (var count = 2; count <= 5; count++) {
        final json = withFirstQuestion((question) {
          question['options'] = [
            for (var i = 0; i < count; i++)
              {'label': '$i', 'text': 'option $i'},
          ];
        });

        expect(
          PhotoQuiz.fromJson(json).questions.first.options,
          hasLength(count),
        );
      }
    });

    test('has no correct answer, only what is printed', () {
      final json = withFirstQuestion((question) {
        question['correct'] = 'b';
      });

      expect(PhotoQuiz.fromJson(json).questions.first.options, hasLength(3));
    });

    group('throws a FormatException', () {
      void expectRejected(Object? json, String message) {
        expect(
          () => PhotoQuiz.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains(message),
            ),
          ),
        );
      }

      test('for an answer that is not an object', () {
        expectRejected(null, 'quiz');
        expectRejected(<Object?>[], 'quiz');
        expectRejected('quiz', 'quiz');
      });

      test('for missing questions', () {
        expectRejected(quizJson()..remove('questions'), 'questions: missing');
        expectRejected(quizJson()..['questions'] = null, 'questions: missing');
      });

      test('for questions that are not a list', () {
        expectRejected(quizJson()..['questions'] = 'x', 'questions: expected');
      });

      test('for no question at all', () {
        expectRejected(
          quizJson()..['questions'] = <Object?>[],
          'at least one question',
        );
      });

      test('for a question that is not an object', () {
        expectRejected(quizJson()..['questions'] = [1], 'questions[0]');
      });

      test('for a missing number, text or options', () {
        expectRejected(
          withFirstQuestion((question) => question.remove('number')),
          'questions[0].number: missing',
        );
        expectRejected(
          withFirstQuestion((question) => question.remove('text')),
          'questions[0].text: missing',
        );
        expectRejected(
          withFirstQuestion((question) => question.remove('options')),
          'questions[0].options: missing',
        );
      });

      test('for a number that is not a whole number', () {
        expectRejected(
          withFirstQuestion((question) => question['number'] = '1'),
          'questions[0].number',
        );
        expectRejected(
          withFirstQuestion((question) => question['number'] = 1.5),
          'questions[0].number',
        );
      });

      test('for a blank question text', () {
        expectRejected(
          withFirstQuestion((question) => question['text'] = '   '),
          'questions[0].text',
        );
      });

      test('for fewer than 2 or more than 5 options', () {
        for (final count in [0, 1, 6]) {
          expectRejected(
            withFirstQuestion((question) {
              question['options'] = [
                for (var i = 0; i < count; i++)
                  {'label': '$i', 'text': 'option $i'},
              ];
            }),
            'questions[0].options: expected 2 to 5 options, got $count',
          );
        }
      });

      test('for an option without a label or a text', () {
        expectRejected(
          withFirstQuestion((question) {
            (question['options']! as List<Object?>)[1] = {'text': 'went'};
          }),
          'questions[0].options[1].label: missing',
        );
        expectRejected(
          withFirstQuestion((question) {
            (question['options']! as List<Object?>)[2] = {
              'label': 'c',
              'text': ' ',
            };
          }),
          'questions[0].options[2].text',
        );
      });

      test('for a title that is not a text', () {
        expectRejected(quizJson()..['title'] = 5, 'title');
      });

      test('for a skippedQuestions that is negative or not a number', () {
        expectRejected(
          quizJson()..['skippedQuestions'] = -1,
          'skippedQuestions',
        );
        expectRejected(
          quizJson()..['skippedQuestions'] = 'a',
          'skippedQuestions',
        );
      });

      test('names the question that is wrong', () {
        final json = quizJson();
        ((json['questions']! as List<Object?>)[1]! as Map<String, Object?>)
            .remove('text');

        expectRejected(json, 'questions[1].text: missing');
      });
    });
  });

  group('immutability and equality', () {
    test('the lists of a parsed quiz cannot be changed', () {
      final quiz = PhotoQuiz.fromJson(quizJson());

      expect(() => quiz.questions.removeLast(), throwsUnsupportedError);
      expect(
        () => quiz.questions.first.options.removeLast(),
        throwsUnsupportedError,
      );
    });

    test('a quiz does not change when the list it was built from does', () {
      final options = [
        const PhotoQuizOption(label: 'a', text: 'go'),
        const PhotoQuizOption(label: 'b', text: 'went'),
      ];
      final question = PhotoQuizQuestion(
        number: 1,
        text: 'x',
        options: options,
      );
      final questions = [question];
      final quiz = PhotoQuiz(questions: questions);

      options.clear();
      questions.clear();

      expect(quiz.questions, hasLength(1));
      expect(quiz.questions.first.options, hasLength(2));
    });

    test('two quizzes read from the same JSON are equal', () {
      final first = PhotoQuiz.fromJson(quizJson());
      final second = PhotoQuiz.fromJson(quizJson());

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('quizzes that differ anywhere are not equal', () {
      final quiz = PhotoQuiz.fromJson(quizJson());

      expect(PhotoQuiz.fromJson(quizJson()..['title'] = 'Other'), isNot(quiz));
      expect(
        PhotoQuiz.fromJson(quizJson()..['skippedQuestions'] = 2),
        isNot(quiz),
      );
      expect(
        PhotoQuiz.fromJson(
          withFirstQuestion((question) => question['text'] = 'Other'),
        ),
        isNot(quiz),
      );
    });
  });

  group('dropping and putting back a question', () {
    final quiz = samplePhotoQuiz(skippedQuestions: 2);

    test('withoutQuestionAt leaves the others, the title and the count', () {
      final shorter = quiz.withoutQuestionAt(1);

      expect(shorter.questions.map((q) => q.number), [1, 3, 4]);
      expect(shorter.title, quiz.title);
      expect(shorter.skippedQuestions, 2);
      expect(quiz.questions, hasLength(4)); // the quiz is not changed
    });

    test('withQuestionInserted undoes it', () {
      final question = quiz.questions[1];

      final back = quiz.withoutQuestionAt(1).withQuestionInserted(1, question);

      expect(back, quiz);
    });

    test('the first, the last and the only question can go and come back', () {
      for (final index in [0, quiz.questions.length - 1]) {
        final question = quiz.questions[index];
        expect(
          quiz.withoutQuestionAt(index).withQuestionInserted(index, question),
          quiz,
        );
      }
      var empty = quiz;
      while (empty.questions.isNotEmpty) {
        empty = empty.withoutQuestionAt(0);
      }
      expect(empty.questions, isEmpty);
      expect(empty.withQuestionInserted(0, quiz.questions.first).questions, [
        quiz.questions.first,
      ]);
    });

    test('a position that does not exist is refused', () {
      expect(() => quiz.withoutQuestionAt(4), throwsRangeError);
      expect(() => quiz.withoutQuestionAt(-1), throwsRangeError);
      expect(
        () => quiz.withQuestionInserted(5, quiz.questions.first),
        throwsRangeError,
      );
    });
  });
}
