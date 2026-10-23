/// Why a quiz could not be made from the photo.
enum PhotoQuizFailure {
  /// Not a single question could be read completely from the photo (HTTP 422
  /// `NO_QUESTIONS_FOUND`). A better photo may help.
  noQuestions,

  /// The photo is larger than the backend accepts, 8 MB (HTTP 413).
  imageTooLarge,

  /// The photo is neither a JPEG nor a PNG (HTTP 415).
  imageUnsupported,

  /// The student has made all the quizzes allowed for today (HTTP 429
  /// `DAILY_LIMIT_REACHED`). [PhotoQuizException.resetsAt] tells when the
  /// count starts again.
  dailyLimit,

  /// The service that reads the photo cannot be used now (HTTP 503, e.g. it is
  /// busy, or the word list cannot be read). Trying again later may work.
  serviceUnavailable,

  /// The device is offline or the server cannot be reached.
  noNetwork,

  /// The server did not answer in time.
  timeout,

  /// The backend does not accept the student's token (HTTP 401), even after a
  /// new one was asked for. The student is signed out.
  unauthorized,

  /// The backend does not know the signed-in Google account (HTTP 403). The
  /// student is signed out with an explanation.
  studentNotFound,

  /// Any other server error, an answer that cannot be read, or a photo file
  /// that cannot be read.
  serverError,
}

/// Thrown by a `PhotoQuizRepository` that cannot make the quiz.
class PhotoQuizException implements Exception {
  const PhotoQuizException(this.failure, {this.resetsAt, this.limit});

  final PhotoQuizFailure failure;

  /// For [PhotoQuizFailure.dailyLimit]: when the count starts again (UTC),
  /// `null` if the backend did not say.
  final DateTime? resetsAt;

  /// For [PhotoQuizFailure.dailyLimit]: how many quizzes a day are allowed,
  /// `null` if the backend did not say.
  final int? limit;

  @override
  String toString() => 'PhotoQuizException($failure)';
}
