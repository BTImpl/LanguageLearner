import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/word_repository_wiring.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_state.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_exception.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_providers.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_http_adapter.dart';

const _quizJson = {
  'title': null,
  'questions': [
    {
      'number': 1,
      'text': 'Pick one.',
      'options': [
        {'label': 'a', 'text': 'x'},
        {'label': 'b', 'text': 'y'},
      ],
    },
  ],
  'skippedQuestions': 0,
};

void main() {
  late FakeAuthRepository auth;
  late FakeHttpAdapter adapter;
  late ProviderContainer container;
  late File photo;

  setUp(() {
    final dir = Directory.systemTemp.createTempSync('photo_quiz_wiring_');
    addTearDown(() => dir.deleteSync(recursive: true));
    photo = File('${dir.path}/sheet.jpg')..writeAsBytesSync([1, 2, 3]);
    auth = FakeAuthRepository();
    adapter = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://backend.test'))
      ..httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        initialAuthStateProvider.overrideWithValue(const SignedIn(testAccount)),
        photoQuizRepositoryProvider.overrideWith(
          (ref) => createApiPhotoQuizRepository(ref, dio: dio),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test('the sample quiz is the default, without a backend', () async {
    final plain = ProviderContainer();
    addTearDown(plain.dispose);

    expect(
      plain.read(photoQuizRepositoryProvider),
      isA<FakePhotoQuizRepository>(),
    );
  });

  test('the quiz is asked with the id token of the student', () async {
    adapter.answer(_quizJson);

    final quiz = await container
        .read(photoQuizRepositoryProvider)
        .createFromImage(photo);

    expect(quiz.questions, hasLength(1));
    expect(adapter.requests.single.headers['Authorization'], 'Bearer id-token');
    expect(container.read(authControllerProvider), isA<SignedIn>());
  });

  test('a 403 signs the student out and explains it', () async {
    adapter.answer({'code': 'STUDENT_NOT_FOUND'}, status: 403);

    await expectLater(
      container.read(photoQuizRepositoryProvider).createFromImage(photo),
      throwsA(isA<PhotoQuizException>()),
    );
    await pumpEventQueue();

    final state = container.read(authControllerProvider);
    expect(state, isA<SignedOut>());
    expect((state as SignedOut).studentNotFound, isTrue);
  });

  test('a 401 that a new token does not fix signs the student out', () async {
    adapter
      ..answer({'code': 'UNAUTHORIZED'}, status: 401)
      ..answer({'code': 'UNAUTHORIZED'}, status: 401);

    await expectLater(
      container.read(photoQuizRepositoryProvider).createFromImage(photo),
      throwsA(isA<PhotoQuizException>()),
    );
    await pumpEventQueue();

    final state = container.read(authControllerProvider);
    expect(state, isA<SignedOut>());
    expect((state as SignedOut).studentNotFound, isFalse);
    expect(auth.idTokenCalls, [false, true]);
  });
}
