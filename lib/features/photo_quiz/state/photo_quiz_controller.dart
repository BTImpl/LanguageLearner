import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_exception.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_providers.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';

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
  const PhotoQuizReady(this.quiz);

  final PhotoQuiz quiz;
}

/// The quiz could not be made.
final class PhotoQuizFailed extends PhotoQuizState {
  const PhotoQuizFailed(this.failure);

  final PhotoQuizFailure failure;
}

/// The state of the photo quiz: `idle`, `loading`, `ready` (`success`) or
/// `failed` (`error`).
final photoQuizControllerProvider =
    NotifierProvider<PhotoQuizController, PhotoQuizState>(
      PhotoQuizController.new,
    );

/// Makes a quiz from a photo and holds the result for the screens after it.
///
/// The photo file is only needed while the request runs: it is deleted when
/// the request ends, whether it succeeded, failed or was given up.
class PhotoQuizController extends Notifier<PhotoQuizState> {
  // Tells the answer of an earlier, given-up request from the current one.
  var _generation = 0;
  File? _photo;

  @override
  PhotoQuizState build() => const PhotoQuizIdle();

  /// Starts making a quiz from [photo]; the controller owns the file from now
  /// on and deletes it. A request that is still running is given up.
  Future<void> start(File photo) async {
    _discardPhoto();
    final generation = ++_generation;
    _photo = photo;
    state = const PhotoQuizLoading();
    PhotoQuizState result;
    try {
      final quiz = await ref
          .read(photoQuizRepositoryProvider)
          .createFromImage(photo);
      result = PhotoQuizReady(quiz);
    } on PhotoQuizException catch (error) {
      result = PhotoQuizFailed(error.failure);
    } on Exception {
      result = const PhotoQuizFailed(PhotoQuizFailure.serverError);
    }
    _delete(photo);
    // A request that was given up (or replaced) must not show its answer.
    if (generation == _generation && ref.mounted) {
      _photo = null;
      state = result;
    }
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
