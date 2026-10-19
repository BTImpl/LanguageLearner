import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/data/api/api_word_repository.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';

import '../../helpers/fake_http_adapter.dart';

const _decksJson = [
  {
    'id': 'travel',
    'name': 'Utazás',
    'updatedAt': '2026-10-07T07:12:00Z',
    'words': [
      {
        'id': 'w1',
        'english': 'boarding pass',
        'hungarian': 'beszállókártya',
        'acceptedEnglish': ['boarding pass'],
        'acceptedHungarian': ['beszállókártya'],
        'example': null,
      },
      {
        'id': 'w2',
        'english': 'ticket',
        'hungarian': 'jegy',
        'acceptedEnglish': ['ticket'],
        'acceptedHungarian': ['jegy', 'menetjegy'],
        'example': 'I lost my ticket.',
      },
    ],
  },
];

void main() {
  late FakeHttpAdapter adapter;
  late List<bool> tokenCalls;
  var unauthorized = 0;
  var notFound = 0;
  late ApiWordRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    tokenCalls = [];
    unauthorized = 0;
    notFound = 0;
    repository = _repository(
      adapter,
      idToken: ({bool forceRefresh = false}) async {
        tokenCalls.add(forceRefresh);
        return forceRefresh ? 'new-token' : 'old-token';
      },
      onUnauthorized: () => unauthorized++,
      onStudentNotFound: () => notFound++,
    );
  });

  Matcher failsWith(WordLoadFailure failure) => throwsA(
    isA<WordLoadException>().having((e) => e.failure, 'failure', failure),
  );

  group('getDecks', () {
    test('maps the answer to decks and words', () async {
      adapter.answer(_decksJson);

      final decks = await repository.getDecks();

      expect(decks, hasLength(1));
      expect(decks.single.id, 'travel');
      expect(decks.single.name, 'Utazás');
      expect(decks.single.updatedAt, DateTime.utc(2026, 10, 7, 7, 12));
      expect(decks.single.words, const [
        WordPair(
          id: 'w1',
          english: 'boarding pass',
          hungarian: 'beszállókártya',
          acceptedEnglish: ['boarding pass'],
          acceptedHungarian: ['beszállókártya'],
        ),
        WordPair(
          id: 'w2',
          english: 'ticket',
          hungarian: 'jegy',
          acceptedEnglish: ['ticket'],
          acceptedHungarian: ['jegy', 'menetjegy'],
          example: 'I lost my ticket.',
        ),
      ]);
    });

    test('an empty answer is no decks', () async {
      adapter.answer(<Object>[]);

      expect(await repository.getDecks(), <Deck>[]);
    });

    test('asks GET /api/v1/decks with the bearer token', () async {
      adapter.answer(_decksJson);

      await repository.getDecks();

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/api/v1/decks');
      expect(request.headers['Authorization'], 'Bearer old-token');
      expect(tokenCalls, [false]);
    });

    test('a 401 is retried once with a new token', () async {
      adapter
        ..answer({'code': 'UNAUTHORIZED'}, status: 401)
        ..answer(_decksJson);

      final decks = await repository.getDecks();

      expect(decks, hasLength(1));
      expect(tokenCalls, [false, true]);
      expect(adapter.requests, hasLength(2));
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer new-token',
      );
      expect(unauthorized, 0);
    });

    test('a second 401 signs the student out', () async {
      adapter
        ..answer({'code': 'UNAUTHORIZED'}, status: 401)
        ..answer({'code': 'UNAUTHORIZED'}, status: 401);

      await expectLater(
        repository.getDecks(),
        failsWith(WordLoadFailure.unauthorized),
      );

      expect(adapter.requests, hasLength(2));
      expect(unauthorized, 1);
    });

    test('a 403 means the student is not found', () async {
      adapter.answer({'code': 'STUDENT_NOT_FOUND'}, status: 403);

      await expectLater(
        repository.getDecks(),
        failsWith(WordLoadFailure.studentNotFound),
      );

      expect(notFound, 1);
      expect(unauthorized, 0);
      expect(adapter.requests, hasLength(1));
    });

    test('a 503 means the word list is unavailable', () async {
      adapter.answer({'code': 'SHEET_UNAVAILABLE'}, status: 503);

      await expectLater(
        repository.getDecks(),
        failsWith(WordLoadFailure.sheetUnavailable),
      );
      expect(unauthorized + notFound, 0);
    });

    test('any other status is a server error', () async {
      adapter.answer({'code': 'INTERNAL'}, status: 500);

      await expectLater(
        repository.getDecks(),
        failsWith(WordLoadFailure.serverError),
      );
    });

    test('an answer of the wrong shape is a server error', () async {
      adapter.answer({'not': 'a list'});
      await expectLater(
        repository.getDecks(),
        failsWith(WordLoadFailure.serverError),
      );

      adapter.answer([
        {'id': 'x'},
      ]);
      await expectLater(
        repository.getDecks(),
        failsWith(WordLoadFailure.serverError),
      );

      adapter.answer([
        {'id': 'x', 'name': 'X', 'updatedAt': 'yesterday', 'words': <Object>[]},
      ]);
      await expectLater(
        repository.getDecks(),
        failsWith(WordLoadFailure.serverError),
      );
    });

    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('$type is a timeout', () async {
        adapter.fail(type);

        await expectLater(
          repository.getDecks(),
          failsWith(WordLoadFailure.timeout),
        );
      });
    }

    test('a connection error means there is no network', () async {
      adapter.fail(DioExceptionType.connectionError);

      await expectLater(
        repository.getDecks(),
        failsWith(WordLoadFailure.noNetwork),
      );
    });

    test('a socket error means there is no network', () async {
      adapter.fail(
        DioExceptionType.unknown,
        const SocketException('Failed host lookup'),
      );

      await expectLater(
        repository.getDecks(),
        failsWith(WordLoadFailure.noNetwork),
      );
    });

    test('an unknown error is a server error', () async {
      adapter.fail(DioExceptionType.unknown, StateError('?'));

      await expectLater(
        repository.getDecks(),
        failsWith(WordLoadFailure.serverError),
      );
    });
  });

  group('the token', () {
    test('a token that cannot be given stops the request', () async {
      final failing = _repository(
        adapter,
        idToken: ({bool forceRefresh = false}) async =>
            throw const WordLoadException(WordLoadFailure.unauthorized),
        onUnauthorized: () => unauthorized++,
        onStudentNotFound: () => notFound++,
      );

      await expectLater(
        failing.getDecks(),
        failsWith(WordLoadFailure.unauthorized),
      );

      expect(adapter.requests, isEmpty);
      expect(unauthorized, 1);
    });

    test('a token that cannot be renewed because of the network', () async {
      final offline = _repository(
        adapter,
        idToken: ({bool forceRefresh = false}) async =>
            throw const WordLoadException(WordLoadFailure.noNetwork),
        onUnauthorized: () => unauthorized++,
        onStudentNotFound: () => notFound++,
      );

      await expectLater(
        offline.getDecks(),
        failsWith(WordLoadFailure.noNetwork),
      );
      expect(unauthorized, 0);
    });
  });

  group('refresh', () {
    test('asks POST /api/v1/decks/refresh', () async {
      adapter.answer(_decksJson);

      await repository.refresh();

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/v1/decks/refresh');
      expect(request.headers['Authorization'], 'Bearer old-token');
    });

    test(
      'the next getDecks gives the refreshed decks without asking',
      () async {
        adapter.answer(_decksJson);
        await repository.refresh();

        final decks = await repository.getDecks();

        expect(decks.single.name, 'Utazás');
        expect(adapter.requests, hasLength(1));
      },
    );

    test('only the next getDecks uses the refreshed decks', () async {
      adapter
        ..answer(_decksJson)
        ..answer(<Object>[]);
      await repository.refresh();
      await repository.getDecks();

      expect(await repository.getDecks(), isEmpty);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.method, 'GET');
    });

    test('a failed refresh throws and changes nothing', () async {
      adapter
        ..answer({'code': 'SHEET_UNAVAILABLE'}, status: 503)
        ..answer(_decksJson);

      await expectLater(
        repository.refresh(),
        failsWith(WordLoadFailure.sheetUnavailable),
      );

      expect(await repository.getDecks(), hasLength(1));
      expect(adapter.requests.last.method, 'GET');
    });
  });
}

ApiWordRepository _repository(
  FakeHttpAdapter adapter, {
  required IdTokenSource idToken,
  required void Function() onUnauthorized,
  required void Function() onStudentNotFound,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://backend.test'))
    ..httpClientAdapter = adapter;
  return ApiWordRepository(
    dio: dio,
    idToken: idToken,
    onUnauthorized: onUnauthorized,
    onStudentNotFound: onStudentNotFound,
  );
}
