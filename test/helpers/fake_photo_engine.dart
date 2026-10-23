import 'package:languagelearner/features/photo_quiz/photo/photo_engine.dart';

/// A [PhotoEngine] that gives what the test says: a path, `null` (cancelled)
/// or an exception.
class FakePhotoEngine implements PhotoEngine {
  FakePhotoEngine({this.path, this.error});

  final String? path;
  final Object? error;
  final List<PhotoOrigin> asked = [];

  @override
  Future<String?> pick(PhotoOrigin origin) async {
    asked.add(origin);
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return path;
  }
}
