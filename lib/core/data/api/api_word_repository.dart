import 'dart:io';

import 'package:dio/dio.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';

/// Gives the Google ID token the backend expects as a bearer token.
///
/// With [forceRefresh] it must ask for a new token even if the current one
/// has not expired. Throws a [WordLoadException] when it cannot give one.
typedef IdTokenSource = Future<String> Function({bool forceRefresh});

/// The decks of the signed-in student from the backend (cards BE-05, BE-06).
///
/// - Every request carries `Authorization: Bearer <ID token>`.
/// - A 401 answer is retried once with a new token; a second 401 signs the
///   student out ([onUnauthorized]).
/// - A 403 answer means the backend does not know the account
///   ([onStudentNotFound]).
/// - Every other problem is a [WordLoadException] the screens can explain.
///
/// The callbacks are called before the exception is thrown.
class ApiWordRepository implements WordRepository {
  ApiWordRepository({
    required this._dio,
    required this._idToken,
    required this.onUnauthorized,
    required this.onStudentNotFound,
  });

  final Dio _dio;
  final IdTokenSource _idToken;
  final void Function() onUnauthorized;
  final void Function() onStudentNotFound;

  // The answer of the last refresh, handed out by the next [getDecks].
  List<Deck>? _refreshed;

  @override
  Future<List<Deck>> getDecks() async {
    final refreshed = _refreshed;
    if (refreshed != null) {
      _refreshed = null;
      return refreshed;
    }
    return _decks('GET', '/api/v1/decks');
  }

  @override
  Future<void> refresh() async {
    // The refresh answers with the same decks as the GET, so the next
    // [getDecks] does not ask again.
    _refreshed = await _decks('POST', '/api/v1/decks/refresh');
  }

  Future<List<Deck>> _decks(String method, String path) async {
    final response = await _send(method, path);
    try {
      return parseDecks(response.data);
    } on FormatException {
      throw const WordLoadException(WordLoadFailure.serverError);
    } on Error {
      // A missing field or a field of the wrong type (a `TypeError`).
      throw const WordLoadException(WordLoadFailure.serverError);
    }
  }

  Future<Response<Object?>> _send(String method, String path) async {
    var forceRefresh = false;
    while (true) {
      final token = await _token(forceRefresh: forceRefresh);
      try {
        return await _dio.request<Object?>(
          path,
          options: Options(
            method: method,
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      } on DioException catch (error) {
        final failure = _failureOf(error);
        if (failure == WordLoadFailure.unauthorized && !forceRefresh) {
          forceRefresh = true;
          continue;
        }
        throw _fail(failure);
      }
    }
  }

  Future<String> _token({required bool forceRefresh}) async {
    try {
      return await _idToken(forceRefresh: forceRefresh);
    } on WordLoadException catch (error) {
      throw _fail(error.failure);
    }
  }

  WordLoadException _fail(WordLoadFailure failure) {
    switch (failure) {
      case WordLoadFailure.unauthorized:
        onUnauthorized();
      case WordLoadFailure.studentNotFound:
        onStudentNotFound();
      case WordLoadFailure.noNetwork:
      case WordLoadFailure.timeout:
      case WordLoadFailure.sheetUnavailable:
      case WordLoadFailure.serverError:
        break;
    }
    return WordLoadException(failure);
  }

  WordLoadFailure _failureOf(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => WordLoadFailure.timeout,
    DioExceptionType.connectionError => WordLoadFailure.noNetwork,
    DioExceptionType.badResponse => switch (error.response?.statusCode) {
      401 => WordLoadFailure.unauthorized,
      403 => WordLoadFailure.studentNotFound,
      503 => WordLoadFailure.sheetUnavailable,
      _ => WordLoadFailure.serverError,
    },
    DioExceptionType.badCertificate ||
    DioExceptionType.cancel ||
    DioExceptionType.unknown =>
      error.error is IOException
          ? WordLoadFailure.noNetwork
          : WordLoadFailure.serverError,
  };
}

/// Reads the answer of `GET /api/v1/decks`. Throws a [FormatException] or a
/// [TypeError] when it does not have the expected shape.
List<Deck> parseDecks(Object? json) {
  return [
    for (final deck in json! as List<Object?>)
      _parseDeck(deck! as Map<Object?, Object?>),
  ];
}

Deck _parseDeck(Map<Object?, Object?> json) => Deck(
  id: json['id']! as String,
  name: json['name']! as String,
  updatedAt: DateTime.parse(json['updatedAt']! as String),
  words: [
    for (final word in json['words']! as List<Object?>)
      _parseWord(word! as Map<Object?, Object?>),
  ],
);

WordPair _parseWord(Map<Object?, Object?> json) => WordPair(
  id: json['id']! as String,
  english: json['english']! as String,
  hungarian: json['hungarian']! as String,
  acceptedEnglish: _strings(json['acceptedEnglish']),
  acceptedHungarian: _strings(json['acceptedHungarian']),
  example: json['example'] as String?,
);

List<String> _strings(Object? json) => [
  for (final item in json! as List<Object?>) item! as String,
];
