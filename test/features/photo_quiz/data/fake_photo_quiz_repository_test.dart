import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_question.dart';

void main() {
  // The file does not exist: the fake never reads the image.
  final image = File('no-such-photo.jpg');

  late PhotoQuiz quiz;

  setUp(() async {
    quiz = await FakePhotoQuizRepository().createFromImage(image);
  });

  test('is a PhotoQuizRepository', () {
    expect(FakePhotoQuizRepository(), isA<PhotoQuizRepository>());
  });

  test('gives a quiz with a title and 3 to 4 questions', () {
    expect(quiz.title, isNotEmpty);
    expect(quiz.questions.length, inInclusiveRange(3, 4));
    expect(quiz.skippedQuestions, 0);
  });

  test('the questions have different numbers of options, from 2 to 5', () {
    final counts = {
      for (final question in quiz.questions) question.options.length,
    };

    expect(counts.length, greaterThan(1));
    for (final count in counts) {
      expect(count, inInclusiveRange(minPhotoQuizOptions, maxPhotoQuizOptions));
    }
  });

  test('one question has a long text', () {
    expect(
      quiz.questions.any((question) => question.text.length > 120),
      isTrue,
    );
  });

  test('the questions are numbered in order and have printed labels', () {
    expect(
      [for (final question in quiz.questions) question.number],
      [for (var i = 1; i <= quiz.questions.length; i++) i],
    );
    for (final question in quiz.questions) {
      expect(question.text, isNotEmpty);
      expect([
        for (final option in question.options) option.label,
      ], ['a', 'b', 'c', 'd', 'e'].take(question.options.length));
    }
  });

  test('gives the same quiz for every photo', () async {
    final again = await FakePhotoQuizRepository().createFromImage(
      File('another.jpg'),
    );

    expect(again, quiz);
  });

  test('takes as long as the delay says', () async {
    const delay = Duration(milliseconds: 30);
    final stopwatch = Stopwatch()..start();

    await FakePhotoQuizRepository(delay: delay).createFromImage(image);

    // A little less than the delay: timers are only exact to a millisecond.
    expect(
      stopwatch.elapsed,
      greaterThanOrEqualTo(delay - const Duration(milliseconds: 5)),
    );
  });

  test('samplePhotoQuiz can say that questions were skipped', () {
    expect(samplePhotoQuiz(skippedQuestions: 2).skippedQuestions, 2);
  });
}
