import 'dart:io';

import 'package:dio/dio.dart';
import 'package:languagelearner/core/data/api/api_word_repository.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_exception.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';

/// Makes the quizzes with `POST /api/v1/quizzes/from-image` (cards BE-13,
/// BE-14), signed in with the Google ID token of the student.
///
/// - The photo goes in the `image` field of a `multipart/form-data` request.
/// - A model call takes 10 to 20 seconds, so this request waits up to
///   [receiveTimeout] for the answer (the other requests wait less).
/// - A request is never repeated after a timeout or a server error: every
///   call that reaches the model is paid for and counts for the daily limit.
///   Only a 401 answer is repeated, once, with a new token; the backend
///   refuses it before it does any work.
/// - Every problem is a [PhotoQuizException] the screens can explain. A second
///   401 signs the student out ([onUnauthorized]); a 403 means the backend
///   does not know the account ([onStudentNotFound]). The callbacks are
///   called before the exception is thrown.
class ApiPhotoQuizRepository implements PhotoQuizRepository {
  ApiPhotoQuizRepository({
    required this._dio,
    required this._idToken,
    required this.onUnauthorized,
    required this.onStudentNotFound,
  });

  /// How long the answer may take.
  static const receiveTimeout = Duration(seconds: 60);

  /// How long sending the photo may take.
  static const sendTimeout = Duration(seconds: 30);

  final Dio _dio;
  final IdTokenSource _idToken;
  final void Function() onUnauthorized;
  final void Function() onStudentNotFound;

  @override
  Future<PhotoQuiz> createFromImage(File image) async {
    var forceRefresh = false;
    while (true) {
      final token = await _token(forceRefresh: forceRefresh);
      // A form can be sent only once, so every try makes its own.
      final form = await _form(image);
      try {
        final response = await _dio.post<Object?>(
          '/api/v1/quizzes/from-image',
          data: form,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            receiveTimeout: receiveTimeout,
            sendTimeout: sendTimeout,
          ),
        );
        return _parse(response.data);
      } on DioException catch (error) {
        final exception = _exceptionOf(error);
        if (exception.failure == PhotoQuizFailure.unauthorized &&
            !forceRefresh) {
          forceRefresh = true;
          continue;
        }
        throw _report(exception);
      }
    }
  }

  Future<FormData> _form(File image) async {
    try {
      final isPng = image.path.toLowerCase().endsWith('.png');
      return FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.uri.pathSegments.last,
          contentType: DioMediaType('image', isPng ? 'png' : 'jpeg'),
        ),
      });
    } on FileSystemException {
      throw const PhotoQuizException(PhotoQuizFailure.serverError);
    }
  }

  Future<String> _token({required bool forceRefresh}) async {
    try {
      return await _idToken(forceRefresh: forceRefresh);
    } on WordLoadException catch (error) {
      throw _report(
        PhotoQuizException(switch (error.failure) {
          WordLoadFailure.noNetwork => PhotoQuizFailure.noNetwork,
          WordLoadFailure.timeout => PhotoQuizFailure.timeout,
          WordLoadFailure.unauthorized => PhotoQuizFailure.unauthorized,
          WordLoadFailure.studentNotFound ||
          WordLoadFailure.sheetUnavailable ||
          WordLoadFailure.serverError => PhotoQuizFailure.serverError,
        }),
      );
    }
  }

  PhotoQuiz _parse(Object? json) {
    try {
      return PhotoQuiz.fromJson(json);
    } on FormatException {
      throw const PhotoQuizException(PhotoQuizFailure.serverError);
    } on Error {
      throw const PhotoQuizException(PhotoQuizFailure.serverError);
    }
  }

  PhotoQuizException _report(PhotoQuizException exception) {
    switch (exception.failure) {
      case PhotoQuizFailure.unauthorized:
        onUnauthorized();
      case PhotoQuizFailure.studentNotFound:
        onStudentNotFound();
      case PhotoQuizFailure.noQuestions:
      case PhotoQuizFailure.imageTooLarge:
      case PhotoQuizFailure.imageUnsupported:
      case PhotoQuizFailure.dailyLimit:
      case PhotoQuizFailure.serviceUnavailable:
      case PhotoQuizFailure.noNetwork:
      case PhotoQuizFailure.timeout:
      case PhotoQuizFailure.serverError:
        break;
    }
    return exception;
  }

  PhotoQuizException _exceptionOf(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const PhotoQuizException(
      PhotoQuizFailure.timeout,
    ),
    DioExceptionType.connectionError => const PhotoQuizException(
      PhotoQuizFailure.noNetwork,
    ),
    DioExceptionType.badResponse => _fromResponse(error.response),
    DioExceptionType.badCertificate ||
    DioExceptionType.cancel ||
    DioExceptionType.unknown => PhotoQuizException(
      error.error is IOException
          ? PhotoQuizFailure.noNetwork
          : PhotoQuizFailure.serverError,
    ),
  };

  PhotoQuizException _fromResponse(Response<Object?>? response) {
    final body = response?.data;
    return switch (response?.statusCode) {
      401 => const PhotoQuizException(PhotoQuizFailure.unauthorized),
      403 => const PhotoQuizException(PhotoQuizFailure.studentNotFound),
      413 => const PhotoQuizException(PhotoQuizFailure.imageTooLarge),
      415 => const PhotoQuizException(PhotoQuizFailure.imageUnsupported),
      422 => const PhotoQuizException(PhotoQuizFailure.noQuestions),
      429 => PhotoQuizException(
        PhotoQuizFailure.dailyLimit,
        resetsAt: _time(body),
        limit: _limit(body),
      ),
      503 => const PhotoQuizException(PhotoQuizFailure.serviceUnavailable),
      _ => const PhotoQuizException(PhotoQuizFailure.serverError),
    };
  }

  DateTime? _time(Object? body) {
    final value = body is Map<Object?, Object?> ? body['resetsAt'] : null;
    return value is String ? DateTime.tryParse(value)?.toUtc() : null;
  }

  int? _limit(Object? body) {
    final value = body is Map<Object?, Object?> ? body['limit'] : null;
    return value is int ? value : null;
  }
}
