import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/features/photo_quiz/data/api_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_exception.dart';

import '../../../helpers/fake_http_adapter.dart';

const _quizJson = {
  'title': 'Unit 5 - Travel',
  'questions': [
    {
      'number': 1,
      'text': 'She ___ to the airport yesterday.',
      'options': [
        {'label': 'a', 'text': 'go'},
        {'label': 'b', 'text': 'went'},
      ],
    },
  ],
  'skippedQuestions': 1,
};

void main() {
  late Directory dir;
  late File photo;
  late FakeHttpAdapter adapter;
  late List<bool> tokenCalls;
  late int unauthorized;
  late int studentNotFound;
  late ApiPhotoQuizRepository repository;
  Object? tokenError;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('api_photo_quiz_');
    addTearDown(() => dir.deleteSync(recursive: true));
    photo = File('${dir.path}/sheet.jpg')..writeAsBytesSync([1, 2, 3, 4]);
    adapter = FakeHttpAdapter();
    tokenCalls = [];
    unauthorized = 0;
    studentNotFound = 0;
    tokenError = null;
    repository = ApiPhotoQuizRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
      idToken: ({bool forceRefresh = false}) async {
        tokenCalls.add(forceRefresh);
        final error = tokenError;
        if (error != null) {
          throw error;
        }
        return forceRefresh ? 'fresh' : 'token';
      },
      onUnauthorized: () => unauthorized++,
      onStudentNotFound: () => studentNotFound++,
    );
  });

  Future<PhotoQuizException> failure([File? image]) async {
    try {
      await repository.createFromImage(image ?? photo);
    } on PhotoQuizException catch (error) {
      return error;
    }
    fail('expected a PhotoQuizException');
  }

  group('a good answer', () {
    test('is turned into a quiz', () async {
      adapter.answer(_quizJson);

      final quiz = await repository.createFromImage(photo);

      expect(quiz.title, 'Unit 5 - Travel');
      expect(quiz.skippedQuestions, 1);
      expect(quiz.questions.single.number, 1);
      expect(quiz.questions.single.options.map((o) => o.text), ['go', 'went']);
    });

    test('is asked with the photo in the image field of a form', () async {
      adapter.answer(_quizJson);

      await repository.createFromImage(photo);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/v1/quizzes/from-image');
      expect(request.headers['Authorization'], 'Bearer token');
      final form = request.data as FormData;
      expect(form.fields, isEmpty);
      final file = form.files.single;
      expect(file.key, 'image');
      expect(file.value.filename, 'sheet.jpg');
      expect(file.value.contentType.toString(), 'image/jpeg');
      expect(file.value.length, 4);
      expect(tokenCalls, [false]);
    });

    test('a PNG is sent as a PNG', () async {
      adapter.answer(_quizJson);
      final png = File('${dir.path}/sheet.PNG')..writeAsBytesSync([1, 2]);

      await repository.createFromImage(png);

      final form = adapter.requests.single.data as FormData;
      expect(form.files.single.value.contentType.toString(), 'image/png');
    });

    test('is waited for longer than the other requests', () async {
      adapter.answer(_quizJson);

      await repository.createFromImage(photo);

      final request = adapter.requests.single;
      expect(request.receiveTimeout, const Duration(seconds: 60));
      expect(request.sendTimeout, const Duration(seconds: 30));
    });
  });

  group('the answers of the backend', () {
    test('every one is its own kind of failure', () async {
      const expected = {
        413: PhotoQuizFailure.imageTooLarge,
        415: PhotoQuizFailure.imageUnsupported,
        422: PhotoQuizFailure.noQuestions,
        503: PhotoQuizFailure.serviceUnavailable,
        400: PhotoQuizFailure.serverError,
        500: PhotoQuizFailure.serverError,
      };
      for (final entry in expected.entries) {
        adapter.answer({'code': 'X', 'message': 'm'}, status: entry.key);

        final error = await failure();

        expect(error.failure, entry.value, reason: '${entry.key}');
      }
      expect(unauthorized, 0);
      expect(studentNotFound, 0);
    });

    test('the daily limit says when it starts again', () async {
      adapter.answer({
        'code': 'DAILY_LIMIT_REACHED',
        'message': 'm',
        'limit': 20,
        'resetsAt': '2026-10-24T00:00:00Z',
      }, status: 429);

      final error = await failure();

      expect(error.failure, PhotoQuizFailure.dailyLimit);
      expect(error.limit, 20);
      expect(error.resetsAt, DateTime.utc(2026, 10, 24));
    });

    test('a daily limit without details is still a daily limit', () async {
      adapter.answer({'code': 'DAILY_LIMIT_REACHED'}, status: 429);

      final error = await failure();

      expect(error.failure, PhotoQuizFailure.dailyLimit);
      expect(error.limit, isNull);
      expect(error.resetsAt, isNull);
    });

    test('a 403 means the account is unknown and is reported', () async {
      adapter.answer({'code': 'STUDENT_NOT_FOUND'}, status: 403);

      final error = await failure();

      expect(error.failure, PhotoQuizFailure.studentNotFound);
      expect(studentNotFound, 1);
      expect(unauthorized, 0);
    });

    test('an answer that is not a quiz is a server error', () async {
      for (final body in <Object?>[
        {'title': 'x', 'questions': <Object?>[]},
        {'title': 'x'},
        ['not', 'a', 'quiz'],
        null,
      ]) {
        adapter.answer(body);

        final error = await failure();

        expect(error.failure, PhotoQuizFailure.serverError, reason: '$body');
      }
    });
  });

  group('the token', () {
    test('a 401 is asked again once with a new token', () async {
      adapter
        ..answer({'code': 'UNAUTHORIZED'}, status: 401)
        ..answer(_quizJson);

      final quiz = await repository.createFromImage(photo);

      expect(quiz.questions, hasLength(1));
      expect(tokenCalls, [false, true]);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.headers['Authorization'], 'Bearer fresh');
      // The second try has a form of its own.
      expect(
        adapter.requests.last.data,
        isNot(same(adapter.requests.first.data)),
      );
      expect(unauthorized, 0);
    });

    test('a second 401 signs the student out', () async {
      adapter
        ..answer({'code': 'UNAUTHORIZED'}, status: 401)
        ..answer({'code': 'UNAUTHORIZED'}, status: 401);

      final error = await failure();

      expect(error.failure, PhotoQuizFailure.unauthorized);
      expect(unauthorized, 1);
      expect(adapter.requests, hasLength(2));
    });

    test('a token that is gone signs the student out', () async {
      tokenError = const WordLoadException(WordLoadFailure.unauthorized);

      final error = await failure();

      expect(error.failure, PhotoQuizFailure.unauthorized);
      expect(unauthorized, 1);
      expect(adapter.requests, isEmpty);
    });

    test(
      'a token that cannot be renewed for lack of network is no sign-out',
      () async {
        tokenError = const WordLoadException(WordLoadFailure.noNetwork);

        final error = await failure();

        expect(error.failure, PhotoQuizFailure.noNetwork);
        expect(unauthorized, 0);
      },
    );
  });

  group('problems on the way', () {
    test('a lost connection is no network', () async {
      adapter.fail(DioExceptionType.connectionError);

      expect((await failure()).failure, PhotoQuizFailure.noNetwork);
    });

    test('an IO error is no network', () async {
      adapter.fail(
        DioExceptionType.unknown,
        const SocketException('unreachable'),
      );

      expect((await failure()).failure, PhotoQuizFailure.noNetwork);
    });

    test('a slow server is a timeout', () async {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        adapter.fail(type);

        expect((await failure()).failure, PhotoQuizFailure.timeout);
      }
    });

    test('something unexpected is a server error', () async {
      adapter.fail(DioExceptionType.unknown, StateError('boom'));

      expect((await failure()).failure, PhotoQuizFailure.serverError);
    });

    test('a timeout is not tried again: a call is paid for', () async {
      adapter.fail(DioExceptionType.receiveTimeout);

      await failure();

      expect(adapter.requests, hasLength(1));
      expect(tokenCalls, [false]);
    });

    test(
      'a photo file that is gone is a server error, nothing is sent',
      () async {
        final error = await failure(File('${dir.path}/missing.jpg'));

        expect(error.failure, PhotoQuizFailure.serverError);
        expect(adapter.requests, isEmpty);
      },
    );
  });
}
