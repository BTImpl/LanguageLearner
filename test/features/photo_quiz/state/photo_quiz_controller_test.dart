import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_exception.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_providers.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';

import '../../../helpers/photo_quiz_fakes.dart';

void main() {
  late Directory dir;
  late ScriptedPhotoQuizRepository repository;
  late ProviderContainer container;

  PhotoQuizState state() => container.read(photoQuizControllerProvider);
  PhotoQuizController controller() =>
      container.read(photoQuizControllerProvider.notifier);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('photo_quiz_controller_');
    repository = ScriptedPhotoQuizRepository();
    container = ProviderContainer(
      overrides: [photoQuizRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() {
      container.dispose();
      dir.deleteSync(recursive: true);
    });
  });

  test('starts idle', () {
    expect(state(), isA<PhotoQuizIdle>());
  });

  test('loads, then holds the quiz', () async {
    final photo = makePhoto(dir);

    final done = controller().start(photo);

    expect(state(), isA<PhotoQuizLoading>());
    expect(repository.requests, [photo]);
    repository.succeed();
    await done;
    expect(state(), isA<PhotoQuizReady>());
    expect((state() as PhotoQuizReady).quiz, samplePhotoQuiz());
  });

  test('a failure is held with its kind', () async {
    final done = controller().start(makePhoto(dir));

    repository.fail(const PhotoQuizException(PhotoQuizFailure.noQuestions));
    await done;

    expect(state(), isA<PhotoQuizFailed>());
    expect((state() as PhotoQuizFailed).failure, PhotoQuizFailure.noQuestions);
  });

  test('an unexpected exception is a server error', () async {
    final done = controller().start(makePhoto(dir));

    repository.fail(const FileSystemException('boom'));
    await done;

    expect((state() as PhotoQuizFailed).failure, PhotoQuizFailure.serverError);
  });

  test('the photo is deleted after a success', () async {
    final photo = makePhoto(dir);

    final done = controller().start(photo);
    expect(photo.existsSync(), isTrue);
    repository.succeed();
    await done;

    expect(photo.existsSync(), isFalse);
  });

  test('the photo is deleted after a failure', () async {
    final photo = makePhoto(dir);

    final done = controller().start(photo);
    repository.fail(const PhotoQuizException(PhotoQuizFailure.timeout));
    await done;

    expect(photo.existsSync(), isFalse);
  });

  test(
    'giving up goes idle, deletes the photo and ignores the answer',
    () async {
      final photo = makePhoto(dir);
      final done = controller().start(photo);

      controller().reset();

      expect(state(), isA<PhotoQuizIdle>());
      await pumpEventQueue();
      expect(photo.existsSync(), isFalse);
      repository.succeed();
      await done;
      expect(state(), isA<PhotoQuizIdle>());
    },
  );

  test('an answer that came late does not touch a newer request', () async {
    final first = controller().start(makePhoto(dir, 'first.jpg'));
    controller().reset();
    final second = controller().start(makePhoto(dir, 'second.jpg'));

    repository.succeed(); // the answer of the first one
    await first;
    expect(state(), isA<PhotoQuizLoading>());
    repository.fail(const PhotoQuizException(PhotoQuizFailure.noNetwork));
    await second;

    expect((state() as PhotoQuizFailed).failure, PhotoQuizFailure.noNetwork);
  });

  test('reset forgets a failure and a quiz', () async {
    var done = controller().start(makePhoto(dir));
    repository.fail(const PhotoQuizException(PhotoQuizFailure.timeout));
    await done;
    controller().reset();
    expect(state(), isA<PhotoQuizIdle>());

    done = controller().start(makePhoto(dir, 'again.jpg'));
    repository.succeed();
    await done;
    controller().reset();

    expect(state(), isA<PhotoQuizIdle>());
  });

  group('the questions of a ready quiz', () {
    Future<void> ready() async {
      final done = controller().start(makePhoto(dir));
      repository.succeed();
      await done;
    }

    PhotoQuizReady current() => state() as PhotoQuizReady;

    test('a question is removed and put back at its place', () async {
      await ready();
      final original = current().quiz;
      final question = original.questions[2];

      controller().removeQuestion(2);
      expect(current().quiz.questions, hasLength(3));
      expect(current().quiz.questions.map((q) => q.number), [1, 2, 4]);

      controller().restoreQuestion(2, question);
      expect(current().quiz, original);
    });

    test('all the questions can be removed', () async {
      await ready();

      for (var i = 0; i < 4; i++) {
        controller().removeQuestion(0);
      }

      expect(current().quiz.questions, isEmpty);
    });

    test('without a ready quiz they do nothing', () {
      controller().removeQuestion(0);
      controller().restoreQuestion(0, samplePhotoQuiz().questions.first);

      expect(state(), isA<PhotoQuizIdle>());
    });
  });
}
