import 'dart:async';
import 'dart:io';

import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_engine.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_source.dart';

/// A photo file with a few bytes in [dir].
File makePhoto(Directory dir, [String name = 'photo.jpg']) =>
    File('${dir.path}/$name')..writeAsBytesSync([1, 2, 3]);

/// A [PhotoQuizRepository] whose calls end when the test says so.
class ScriptedPhotoQuizRepository implements PhotoQuizRepository {
  /// The photo of every call, in order.
  final requests = <File>[];
  final _pending = <Completer<PhotoQuiz>>[];

  @override
  Future<PhotoQuiz> createFromImage(File image) {
    requests.add(image);
    final completer = Completer<PhotoQuiz>();
    _pending.add(completer);
    return completer.future;
  }

  /// The oldest running call ends with a quiz.
  void succeed([PhotoQuiz? quiz]) =>
      _pending.removeAt(0).complete(quiz ?? samplePhotoQuiz());

  /// The oldest running call ends with [error].
  void fail(Object error) => _pending.removeAt(0).completeError(error);
}

/// A [PhotoSource] that gives the results the test lines up.
class FakePhotoSource implements PhotoSource {
  FakePhotoSource(Iterable<PhotoPickResult> results) : _results = [...results];

  final List<PhotoPickResult> _results;

  /// What the student was asked for, in order.
  final asked = <PhotoOrigin>[];

  @override
  Future<PhotoPickResult> pick(PhotoOrigin origin) async {
    asked.add(origin);
    return _results.removeAt(0);
  }
}
