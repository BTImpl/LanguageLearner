/// Why the decks could not be loaded from the backend.
enum WordLoadFailure {
  /// The device is offline or the server cannot be reached.
  noNetwork,

  /// The server did not answer in time.
  timeout,

  /// The backend does not accept the student's token (HTTP 401), even after a
  /// new one was asked for. The student is signed out.
  unauthorized,

  /// The backend does not know the signed-in Google account (HTTP 403
  /// `STUDENT_NOT_FOUND`). The student is signed out with an explanation.
  studentNotFound,

  /// The word list is temporarily unavailable (HTTP 503, e.g. the
  /// spreadsheet cannot be read).
  sheetUnavailable,

  /// Any other server error or an answer that cannot be read.
  serverError,
}

/// Thrown by a `WordRepository` that cannot load the decks.
class WordLoadException implements Exception {
  const WordLoadException(this.failure);

  final WordLoadFailure failure;

  @override
  String toString() => 'WordLoadException($failure)';
}
