import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_exception.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_providers.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_question.dart';

/// Where the making of a quiz from a photo stands.
sealed class PhotoQuizState {
  const PhotoQuizState();
}

/// Nothing is going on: no photo is being read and there is no quiz.
final class PhotoQuizIdle extends PhotoQuizState {
  const PhotoQuizIdle();
}

/// The photo is being sent and read.
final class PhotoQuizLoading extends PhotoQuizState {
  const PhotoQuizLoading();
}

/// The quiz is made.
final class PhotoQuizReady extends PhotoQuizState {
  const PhotoQuizReady(this.quiz, {this.fromSaved = false});

  final PhotoQuiz quiz;

  /// The quiz was taken from the saved quizzes, not read from a photo just
  /// now: leaving the fill-in screen goes back to that list.
  final bool fromSaved;
}

/// The quiz could not be made.
final class PhotoQuizFailed extends PhotoQuizState {
  const PhotoQuizFailed(
    this.failure, {
    this.resetsAt,
    this.limit,
    this.canRetry = false,
  });

  final PhotoQuizFailure failure;

  /// For [PhotoQuizFailure.dailyLimit]: when the count starts again (UTC), if
  /// the backend said.
  final DateTime? resetsAt;

  /// For [PhotoQuizFailure.dailyLimit]: how many quizzes a day are allowed, if
  /// the backend said.
  final int? limit;

  /// Whether the same photo can be sent again with [PhotoQuizController.retry].
  final bool canRetry;
}

/// The failures that can go away by themselves, so the photo is kept for
/// another try.
bool _isRetryable(PhotoQuizFailure failure) => switch (failure) {
  PhotoQuizFailure.noNetwork ||
  PhotoQuizFailure.timeout ||
  PhotoQuizFailure.serviceUnavailable => true,
  _ => false,
};

/// The state of the photo quiz: `idle`, `loading`, `ready` (`success`) or
/// `failed` (`error`).
final photoQuizControllerProvider =
    NotifierProvider<PhotoQuizController, PhotoQuizState>(
      PhotoQuizController.new,
    );

/// Makes a quiz from a photo and holds the result for the screens after it.
///
/// The photo file is only needed while the request runs: it is deleted when
/// the request ends, whether it succeeded, failed or was given up. The one
/// exception is a failure that may pass (no network, no answer in time, a
/// service that is not available): the photo stays so that [retry] can send
/// it again, and goes with the next [start], [reset] or the end of the app.
class PhotoQuizController extends Notifier<PhotoQuizState> {
  // Tells the answer of an earlier, given-up request from the current one.
  var _generation = 0;
  File? _photo;

  @override
  PhotoQuizState build() {
    ref.onDispose(_discardPhoto);
    return const PhotoQuizIdle();
  }

  /// Starts making a quiz from [photo]; the controller owns the file from now
  /// on and deletes it. A request that is still running is given up.
  Future<void> start(File photo) {
    _discardPhoto();
    return _run(photo);
  }

  /// Sends the kept photo again, a new request, after a failure that
  /// [PhotoQuizFailed.canRetry]. Does nothing otherwise.
  Future<void> retry() {
    final photo = _photo;
    final current = state;
    if (photo == null || current is! PhotoQuizFailed || !current.canRetry) {
      return Future.value();
    }
    return _run(photo);
  }

  Future<void> _run(File photo) async {
    final generation = ++_generation;
    _photo = photo;
    state = const PhotoQuizLoading();
    PhotoQuizState result;
    var retryable = false;
    try {
      final quiz = await ref
          .read(photoQuizRepositoryProvider)
          .createFromImage(photo);
      result = PhotoQuizReady(quiz);
    } on PhotoQuizException catch (error) {
      retryable = _isRetryable(error.failure);
      result = PhotoQuizFailed(
        error.failure,
        resetsAt: error.resetsAt,
        limit: error.limit,
        canRetry: retryable,
      );
    } on Exception {
      result = const PhotoQuizFailed(PhotoQuizFailure.serverError);
    }
    // A request that was given up (or replaced) must not show its answer; its
    // photo is already gone, taken by whoever gave it up.
    if (generation != _generation || !ref.mounted) {
      _delete(photo);
      return;
    }
    if (retryable) {
      _photo = photo;
    } else {
      _photo = null;
      _delete(photo);
    }
    state = result;
  }

  /// Drops the question at [index] from the ready quiz (a position in its
  /// questions). Does nothing while there is no ready quiz.
  void removeQuestion(int index) {
    final current = state;
    if (current is PhotoQuizReady) {
      state = PhotoQuizReady(
        current.quiz.withoutQuestionAt(index),
        fromSaved: current.fromSaved,
      );
    }
  }

  /// Puts [question] back at [index], the undo of [removeQuestion]. Does
  /// nothing while there is no ready quiz.
  void restoreQuestion(int index, PhotoQuizQuestion question) {
    final current = state;
    if (current is PhotoQuizReady) {
      state = PhotoQuizReady(
        current.quiz.withQuestionInserted(index, question),
        fromSaved: current.fromSaved,
      );
    }
  }

  /// Makes [quiz], one of the saved quizzes, the ready quiz, so that the
  /// fill-in screen can start with it. A running request is given up.
  void loadSaved(PhotoQuiz quiz) {
    _generation++;
    _discardPhoto();
    state = PhotoQuizReady(quiz, fromSaved: true);
  }

  /// Back to [PhotoQuizIdle]: gives up a running request (its answer is
  /// ignored; the server may still count it) and forgets the quiz or the
  /// failure. The photo file is deleted.
  void reset() {
    _generation++;
    _discardPhoto();
    state = const PhotoQuizIdle();
  }

  void _discardPhoto() {
    final photo = _photo;
    _photo = null;
    if (photo != null) {
      _delete(photo);
    }
  }
}

// Synchronous: the file is small and it keeps the controller free of real
// file IO that a widget test (with its fake clock) could never finish.
void _delete(File file) {
  try {
    if (file.existsSync()) {
      file.deleteSync();
    }
  } on FileSystemException {
    // A temporary file that stays is cleaned up by the system.
  }
}
