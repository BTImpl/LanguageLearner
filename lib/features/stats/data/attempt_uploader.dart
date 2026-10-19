import 'package:languagelearner/features/stats/data/attempt_record.dart';

/// Why a batch did not reach the backend.
enum AttemptUploadFailure {
  /// Network, timeout, 5xx, sign-in problem: nothing is wrong with the rows,
  /// the next sync tries them again.
  retryLater,

  /// The backend refused the batch as invalid (HTTP 400): sending it again
  /// would fail the same way.
  rejected,
}

/// Thrown by [AttemptUploader.upload].
class AttemptUploadException implements Exception {
  const AttemptUploadException(this.failure);

  final AttemptUploadFailure failure;

  @override
  String toString() => 'AttemptUploadException($failure)';
}

/// Sends answers to the backend (card LL-30).
abstract interface class AttemptUploader {
  /// Uploads [records] in one request. Returns when the backend has all of
  /// them (new or already known); throws an [AttemptUploadException]
  /// otherwise.
  Future<void> upload(List<AttemptRecord> records);
}

/// The [AttemptUploader] of the offline mode and of the tests: it never has a
/// backend, so every upload has to wait.
class NoopAttemptUploader implements AttemptUploader {
  const NoopAttemptUploader();

  @override
  Future<void> upload(List<AttemptRecord> records) {
    throw const AttemptUploadException(AttemptUploadFailure.retryLater);
  }
}
