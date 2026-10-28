import 'package:dio/dio.dart';
import 'package:languagelearner/core/data/api/api_word_repository.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/stats/data/attempt_record.dart';
import 'package:languagelearner/features/stats/data/attempt_uploader.dart';

/// Uploads answers with `POST /api/v1/attempts` (card BE-08). The endpoint is
/// idempotent by the id of the answer, so a batch can be sent again safely.
///
/// A 400 answer is [AttemptUploadFailure.rejected]; everything else that goes
/// wrong is [AttemptUploadFailure.retryLater]. A 401 answer is retried once
/// with a new token; a second one signs the student out ([onUnauthorized]).
class ApiAttemptUploader implements AttemptUploader {
  ApiAttemptUploader({
    required this._dio,
    required this._idToken,
    required this.onUnauthorized,
  });

  final Dio _dio;
  final IdTokenSource _idToken;
  final void Function() onUnauthorized;

  @override
  Future<void> upload(List<AttemptRecord> records) async {
    final body = {
      'attempts': [for (final record in records) attemptToJson(record)],
    };
    var forceRefresh = false;
    while (true) {
      final String token;
      try {
        token = await _idToken(forceRefresh: forceRefresh);
      } on WordLoadException {
        throw const AttemptUploadException(AttemptUploadFailure.retryLater);
      }
      try {
        await _dio.post<Object?>(
          '/api/v1/attempts',
          data: body,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        return;
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status == 401) {
          if (!forceRefresh) {
            forceRefresh = true;
            continue;
          }
          onUnauthorized();
        }
        throw AttemptUploadException(
          status == 400
              ? AttemptUploadFailure.rejected
              : AttemptUploadFailure.retryLater,
        );
      }
    }
  }
}

/// The JSON of one answer as `POST /api/v1/attempts` expects it.
Map<String, Object?> attemptToJson(AttemptRecord record) => {
  'id': record.id,
  'deckId': record.deckId,
  'wordId': record.wordId,
  'mode': _mode(record.mode),
  'outcome': _outcome(record.outcome),
  'answeredAt': record.answeredAt.toUtc().toIso8601String(),
};

String _mode(PlayMode mode) => switch (mode) {
  PlayMode.flashcards => 'FLASHCARDS',
  PlayMode.matching => 'MATCHING',
  PlayMode.quiz => 'QUIZ',
  PlayMode.typing => 'TYPING',
  // The backend does not know SPEAKING yet (card BE-20), so a speaking answer
  // is sent as TYPING: it is the same kind of task (an exact written or
  // spoken answer). Switch to 'SPEAKING' when BE-20 is deployed.
  PlayMode.speaking => 'TYPING',
  PlayMode.mix => 'MIX',
};

String _outcome(WordOutcome outcome) => switch (outcome) {
  WordOutcome.firstTry => 'FIRST_TRY',
  WordOutcome.withHelp => 'WITH_HELP',
  WordOutcome.wrongFirst => 'WRONG_FIRST',
};
