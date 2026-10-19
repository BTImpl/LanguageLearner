import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/word_repository_wiring.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';
import 'package:languagelearner/features/auth/auth_state.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_http_adapter.dart';

const _decksJson = [
  {
    'id': 'travel',
    'name': 'Utazás',
    'updatedAt': '2026-10-07T07:12:00Z',
    'words': [
      {
        'id': 'w1',
        'english': 'luggage',
        'hungarian': 'poggyász',
        'acceptedEnglish': ['luggage'],
        'acceptedHungarian': ['poggyász'],
        'example': null,
      },
    ],
  },
];

void main() {
  late FakeAuthRepository auth;
  late FakeHttpAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository();
    adapter = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://backend.test'))
      ..httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        initialAuthStateProvider.overrideWithValue(const SignedIn(testAccount)),
        wordRepositoryProvider.overrideWith(
          (ref) => createApiWordRepository(ref, dio: dio),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'the decks come from the backend with the id token of the student',
    () async {
      adapter.answer(_decksJson);

      final decks = await container.read(decksProvider.future);

      expect(decks.single.name, 'Utazás');
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer id-token',
      );
      expect(container.read(authControllerProvider), isA<SignedIn>());
    },
  );

  test('a 403 signs the student out and explains it', () async {
    adapter.answer({'code': 'STUDENT_NOT_FOUND'}, status: 403);

    await expectLater(
      container.read(decksProvider.future),
      throwsA(isA<WordLoadException>()),
    );
    await pumpEventQueue();

    final state = container.read(authControllerProvider);
    expect(state, isA<SignedOut>());
    expect((state as SignedOut).studentNotFound, isTrue);
    expect(auth.signOutCalls, 1);
  });

  test('a 401 that a new token does not fix signs the student out', () async {
    adapter
      ..answer({'code': 'UNAUTHORIZED'}, status: 401)
      ..answer({'code': 'UNAUTHORIZED'}, status: 401);

    await expectLater(
      container.read(decksProvider.future),
      throwsA(isA<WordLoadException>()),
    );
    await pumpEventQueue();

    final state = container.read(authControllerProvider);
    expect(state, isA<SignedOut>());
    expect((state as SignedOut).studentNotFound, isFalse);
    expect(auth.idTokenCalls, [false, true]);
  });

  test('a token that cannot be renewed because of the network keeps the '
      'student signed in', () async {
    auth.idTokenError = const AuthException(AuthFailure.failed);

    await expectLater(
      container.read(decksProvider.future),
      throwsA(
        isA<WordLoadException>().having(
          (e) => e.failure,
          'failure',
          WordLoadFailure.noNetwork,
        ),
      ),
    );
    await pumpEventQueue();

    expect(container.read(authControllerProvider), isA<SignedIn>());
  });

  test('a token that is gone signs the student out', () async {
    auth.idTokenError = const AuthException(AuthFailure.notSignedIn);

    await expectLater(
      container.read(decksProvider.future),
      throwsA(isA<WordLoadException>()),
    );
    await pumpEventQueue();

    expect(container.read(authControllerProvider), isA<SignedOut>());
  });
}
