import 'package:flutter/foundation.dart';
import 'package:languagelearner/features/photo_quiz/models/json_reader.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';

/// A quiz that was read from a photo and kept on the phone, to be filled in
/// again.
///
/// Neither the photo nor the answers are kept: a quiz always starts empty.
@immutable
class SavedQuiz {
  const SavedQuiz({
    required this.id,
    required this.quiz,
    required this.createdAt,
    required this.lastUsedAt,
    required this.fillCount,
  });

  /// Reads what [toJson] wrote. Throws a [FormatException] when a field is
  /// missing or wrong, or the quiz is not valid.
  factory SavedQuiz.fromJson(Object? json) {
    final map = readObject(json, 'savedQuiz');
    return SavedQuiz(
      id: readString(map, 'id', 'savedQuiz'),
      quiz: PhotoQuiz.fromJson(map['quiz']),
      createdAt: _readTime(map, 'createdAt'),
      lastUsedAt: _readTime(map, 'lastUsedAt'),
      fillCount: readInt(map, 'fillCount', 'savedQuiz'),
    );
  }

  /// The fingerprint of the content (see `quizFingerprint`): the same worksheet
  /// has the same id.
  final String id;
  final PhotoQuiz quiz;
  final DateTime createdAt;

  /// When the quiz was last started, from a photo or from the list.
  final DateTime lastUsedAt;

  /// How many times the quiz was started.
  final int fillCount;

  /// A copy that was started once more at [now].
  SavedQuiz usedAt(DateTime now) => SavedQuiz(
    id: id,
    quiz: quiz,
    createdAt: createdAt,
    lastUsedAt: now,
    fillCount: fillCount + 1,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'quiz': quiz.toJson(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'lastUsedAt': lastUsedAt.toUtc().toIso8601String(),
    'fillCount': fillCount,
  };

  @override
  bool operator ==(Object other) =>
      other is SavedQuiz &&
      other.id == id &&
      other.quiz == quiz &&
      other.createdAt == createdAt &&
      other.lastUsedAt == lastUsedAt &&
      other.fillCount == fillCount;

  @override
  int get hashCode => Object.hash(id, quiz, createdAt, lastUsedAt, fillCount);

  @override
  String toString() => 'SavedQuiz($id, ${quiz.title}, x$fillCount)';
}

DateTime _readTime(Map<Object?, Object?> map, String key) {
  final text = readString(map, key, 'savedQuiz');
  final time = DateTime.tryParse(text);
  if (time == null) {
    throw FormatException('savedQuiz.$key: not a time: $text');
  }
  return time;
}
