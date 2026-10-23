import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_repository.dart';

/// Where the quizzes made from photos come from. `main` swaps it for the
/// backend; tests override it with a fake.
final photoQuizRepositoryProvider = Provider<PhotoQuizRepository>(
  (ref) => FakePhotoQuizRepository(),
);
