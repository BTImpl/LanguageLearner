import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_answers.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_option.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_question.dart';
import 'package:languagelearner/features/photo_quiz/submit/quiz_email.dart';
import 'package:languagelearner/i18n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final hu = lookupAppLocalizations(const Locale('hu'));
  final date = DateTime(2026, 10, 4, 18, 30);
  final quiz = samplePhotoQuiz();

  QuizEmail build({
    AppLocalizations? l10n,
    PhotoQuiz? withQuiz,
    PhotoQuizAnswers Function(PhotoQuizAnswers)? answer,
    String name = 'Kiss Anna',
  }) {
    final q = withQuiz ?? quiz;
    var answers = PhotoQuizAnswers.empty(q);
    if (answer != null) {
      answers = answer(answers);
    }
    return buildQuizEmail(
      l10n: l10n ?? en,
      quiz: q,
      answers: answers,
      studentName: name,
      studentEmail: 'kiss.anna@example.com',
      date: date,
    );
  }

  group('the subject', () {
    test('is the title of the worksheet and the name of the student', () {
      expect(build().subject, 'Grammar – Worksheet 3 – Kiss Anna');
    });

    test('uses the generic title when the worksheet has none', () {
      final untitled = PhotoQuiz(questions: quiz.questions);

      expect(
        build(withQuiz: untitled).subject,
        'Quiz from a photo – Kiss Anna',
      );
      expect(
        build(withQuiz: untitled, l10n: hu).subject,
        'Kvíz fotóból – Kiss Anna',
      );
    });

    test('is only the title without a name', () {
      expect(build(name: '').subject, 'Grammar – Worksheet 3');
    });
  });

  group('the body', () {
    test('starts with the student, the day and the progress', () {
      final lines = build().body.split('\n');

      expect(lines[0], 'Student: Kiss Anna (kiss.anna@example.com)');
      expect(lines[1], 'Date: 2026-10-04');
      expect(lines[2], '0 / 4 answered');
    });

    test('lists every question with all its options and the choice', () {
      final body = build(answer: (a) => a.select(0, 1).select(1, 0)).body;

      expect(body, contains('1. She ___ to school every day.'));
      expect(body, contains('   [ ] a) go\n   [x] b) goes\n   [ ] c) going'));
      expect(body, contains('   [x] a) True\n   [ ] b) False'));
      expect(body, contains('2 / 4 answered'));
    });

    test('puts a divider before every question', () {
      final body = build().body;

      expect('\n----------\n'.allMatches(body), hasLength(4));
      expect(body, contains('----------\n\n1. She ___ to school every day.'));
    });

    test('says "no answer" for a question without a choice', () {
      final body = build(answer: (a) => a.select(0, 1)).body;

      expect('no answer'.allMatches(body), hasLength(3));
      expect(
        body,
        contains(
          '   [ ] d) gone\n\n----------\n\n2. London is the capital of England.',
        ),
      );
    });

    test('has no choice mark and one "no answer" per open question', () {
      final body = build().body;

      expect('[x]'.allMatches(body), isEmpty);
      expect('no answer'.allMatches(body), hasLength(4));
    });

    test('numbers the questions by position, not by the printed number', () {
      final renumbered = PhotoQuiz(
        questions: [
          PhotoQuizQuestion(
            number: 7,
            text: 'Seventh on the sheet',
            options: const [
              PhotoQuizOption(label: 'a', text: 'x'),
              PhotoQuizOption(label: 'b', text: 'y'),
            ],
          ),
        ],
      );

      final body = build(withQuiz: renumbered).body;

      expect(body, contains('1. Seventh on the sheet'));
      expect(body, isNot(contains('7.')));
    });

    test('keeps a long question and a long option whole', () {
      final body = build().body;

      expect(
        body,
        contains(
          '3. After the meeting had finished, the manager asked everyone '
          'to stay behind because she wanted to talk about the new schedule '
          'for the following month. Which sentence is true?',
        ),
      );
      expect(
        body,
        contains(
          'a) The manager wanted to talk to everyone after the meeting.',
        ),
      );
    });

    test('handles two and five options', () {
      final body = build().body;

      expect(body, contains('   [ ] e) have done'));
      expect(body, isNot(contains('c) True')));
    });

    test('is in Hungarian when the app is', () {
      final body = build(l10n: hu, answer: (a) => a.select(1, 1)).body;

      expect(body, contains('Diák: Kiss Anna (kiss.anna@example.com)'));
      expect(body, contains('Dátum: 2026-10-04'));
      expect(body, contains('1 / 4 megválaszolva'));
      expect(body, contains('   [x] b) False'));
      expect('nincs válasz'.allMatches(body), hasLength(3));
    });

    test('pads a short day and month', () {
      final early = buildQuizEmail(
        l10n: en,
        quiz: quiz,
        answers: PhotoQuizAnswers.empty(quiz),
        studentName: 'A',
        studentEmail: 'a@example.com',
        date: DateTime(2026, 3, 5),
      );

      expect(early.body, contains('Date: 2026-03-05'));
    });
  });

  group('the HTML', () {
    test('has the header, every question and the chosen option marked', () {
      final html = build(answer: (a) => a.select(0, 1)).html;

      expect(html, contains('Student: Kiss Anna (kiss.anna@example.com)'));
      expect(html, contains('Date: 2026-10-04'));
      expect(html, contains('1 / 4 answered'));
      expect(html, contains('1. She ___ to school every day.'));
      expect(html, contains('\u2714 b) goes'));
      expect(html, contains('\u25CB a) go'));
      expect('\u2714'.allMatches(html), hasLength(1));
    });

    test('lists every option of every question', () {
      final html = build().html;

      for (final text in ['a) go', 'd) gone', 'a) True', 'b) False']) {
        expect(html, contains(text));
      }
      expect(html, contains('e) have done'));
    });

    test('marks the questions without an answer', () {
      final html = build(answer: (a) => a.select(0, 1)).html;

      expect('no answer'.allMatches(html), hasLength(3));
    });

    test('puts each question in its own block, not in one line', () {
      final html = build().html;

      expect('<div style="margin:0 0 20px">'.allMatches(html), hasLength(4));
      expect(html, startsWith('<div style="font-family'));
      expect(html, endsWith('</div>'));
    });

    test('escapes what would be taken for markup', () {
      final tricky = PhotoQuiz(
        title: 'A <b> & B',
        questions: [
          PhotoQuizQuestion(
            number: 1,
            text: 'Is 1 < 2 & 3 > 2?',
            options: const [
              PhotoQuizOption(label: 'a', text: '<script>x</script>'),
              PhotoQuizOption(label: 'b', text: 'a "quote"'),
            ],
          ),
        ],
      );

      final html = build(withQuiz: tricky, name: 'A <i>nna').html;

      expect(html, isNot(contains('<script>')));
      expect(html, isNot(contains('<i>')));
      expect(html, contains('Is 1 &lt; 2 &amp; 3 &gt; 2?'));
      expect(html, contains('&lt;script&gt;x&lt;/script&gt;'));
      expect(html, contains('&lt;i&gt;nna'));
    });

    test('is in Hungarian when the app is', () {
      final html = build(l10n: hu, answer: (a) => a.select(1, 1)).html;

      expect(html, contains('Diák: Kiss Anna'));
      expect(html, contains('1 / 4 megválaszolva'));
      expect(html, contains('nincs válasz'));
    });

    test('says the same as the plain text', () {
      final email = build(answer: (a) => a.select(0, 2).select(3, 4));

      for (final text in [
        'She ___ to school every day.',
        'c) going',
        'e) have done',
        'I ___ my homework right now.',
      ]) {
        expect(email.body, contains(text));
        expect(email.html, contains(text));
      }
    });
  });
}
