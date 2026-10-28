import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/data/api/api_attempt_uploader.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/stats/data/attempt_record.dart';
import 'package:languagelearner/features/stats/data/attempt_uploader.dart';

import '../../helpers/fake_http_adapter.dart';

final _record = AttemptRecord(
  id: '3f2b8c1e-0000-4000-8000-000000000001',
  deckId: 'travel',
  wordId: 'w1',
  mode: PlayMode.typing,
  outcome: WordOutcome.wrongFirst,
  answeredAt: DateTime.utc(2026, 10, 7, 8, 30),
);

void main() {
  late FakeHttpAdapter adapter;
  late List<bool> tokenCalls;
  late int unauthorized;
  late ApiAttemptUploader uploader;

  setUp(() {
    adapter = FakeHttpAdapter();
    tokenCalls = [];
    unauthorized = 0;
    uploader = ApiAttemptUploader(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
      idToken: ({bool forceRefresh = false}) async {
        tokenCalls.add(forceRefresh);
        return forceRefresh ? 'fresh' : 'token';
      },
      onUnauthorized: () => unauthorized++,
    );
  });

  Future<AttemptUploadFailure?> failureOf() async {
    try {
      await uploader.upload([_record]);
      return null;
    } on AttemptUploadException catch (error) {
      return error.failure;
    }
  }

  test('posts the rows in the shape of the backend', () async {
    adapter.answer({'accepted': 1, 'duplicates': 0});

    await uploader.upload([_record]);

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/api/v1/attempts');
    expect(request.headers['Authorization'], 'Bearer token');
    expect(request.data, {
      'attempts': [
        {
          'id': '3f2b8c1e-0000-4000-8000-000000000001',
          'deckId': 'travel',
          'wordId': 'w1',
          'mode': 'TYPING',
          'outcome': 'WRONG_FIRST',
          'answeredAt': '2026-10-07T08:30:00.000Z',
        },
      ],
    });
  });

  test('maps every mode and outcome to the names of the backend', () {
    final modes = {
      for (final mode in PlayMode.values)
        mode: attemptToJson(
          AttemptRecord(
            id: 'x',
            deckId: 'd',
            wordId: 'w',
            mode: mode,
            outcome: WordOutcome.firstTry,
            answeredAt: DateTime.utc(2026),
          ),
        )['mode'],
    };
    expect(modes.values, [
      'FLASHCARDS',
      'MATCHING',
      'QUIZ',
      'TYPING',
      'TYPING',
      'MIX',
    ]);
    expect(
      [
        for (final outcome in WordOutcome.values)
          attemptToJson(
            AttemptRecord(
              id: 'x',
              deckId: 'd',
              wordId: 'w',
              mode: PlayMode.quiz,
              outcome: outcome,
              answeredAt: DateTime.utc(2026),
            ),
          )['outcome'],
      ],
      ['FIRST_TRY', 'WITH_HELP', 'WRONG_FIRST'],
    );
  });

  test('a 400 answer is a rejection', () async {
    adapter.answer({'error': 'bad'}, status: 400);

    expect(await failureOf(), AttemptUploadFailure.rejected);
  });

  test('5xx, timeout and no network are retried later', () async {
    adapter
      ..answer({}, status: 500)
      ..answer({}, status: 503)
      ..fail(DioExceptionType.receiveTimeout)
      ..fail(DioExceptionType.connectionError);

    for (var i = 0; i < 4; i++) {
      expect(await failureOf(), AttemptUploadFailure.retryLater);
    }
    expect(unauthorized, 0);
  });

  test('a token problem is retried later, without a request', () async {
    uploader = ApiAttemptUploader(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
      idToken: ({bool forceRefresh = false}) async =>
          throw const WordLoadException(WordLoadFailure.noNetwork),
      onUnauthorized: () => unauthorized++,
    );

    expect(await failureOf(), AttemptUploadFailure.retryLater);
    expect(adapter.requests, isEmpty);
  });

  test('a 401 answer is retried once with a new token', () async {
    adapter
      ..answer({}, status: 401)
      ..answer({'accepted': 1, 'duplicates': 0});

    await uploader.upload([_record]);

    expect(tokenCalls, [false, true]);
    expect(adapter.requests.last.headers['Authorization'], 'Bearer fresh');
    expect(unauthorized, 0);
  });

  test('a second 401 answer signs the student out and retries later', () async {
    adapter
      ..answer({}, status: 401)
      ..answer({}, status: 401);

    expect(await failureOf(), AttemptUploadFailure.retryLater);
    expect(unauthorized, 1);
  });
}
