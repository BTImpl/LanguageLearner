import 'dart:io';

import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';

/// Where the quizzes made from photos come from.
///
/// The screens only know this interface. The app will use the backend
/// (`POST /api/v1/quizzes/from-image`, card BE-14); the
/// `FakePhotoQuizRepository` has built-in data, so the screens can be built
/// and tried without the backend.
abstract interface class PhotoQuizRepository {
  /// Makes a quiz from the photo of a worksheet.
  ///
  /// The image is a JPEG or PNG of at most 8 MB. The call can take 10 to 20
  /// seconds.
  Future<PhotoQuiz> createFromImage(File image);
}
