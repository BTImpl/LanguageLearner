import 'package:flutter/foundation.dart';
import 'package:languagelearner/features/photo_quiz/models/json_reader.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_option.dart';

/// The fewest and the most options a question can have.
const int minPhotoQuizOptions = 2;
const int maxPhotoQuizOptions = 5;

/// One question of a quiz read from a photo, with its answer options.
///
/// The shape matches `QuizQuestion` of the backend (card BE-14).
@immutable
class PhotoQuizQuestion {
  /// The [options] are copied into a list that cannot be changed.
  PhotoQuizQuestion({
    required this.number,
    required this.text,
    required List<PhotoQuizOption> options,
  }) : options = List.unmodifiable(options);

  /// Reads one question of the backend answer. Throws a [FormatException] when
  /// a field is missing or of the wrong type, the text is blank, or the
  /// question has fewer than [minPhotoQuizOptions] or more than
  /// [maxPhotoQuizOptions] options.
  ///
  /// [path] is where the question sits in the answer, for the error message.
  factory PhotoQuizQuestion.fromJson(Object? json, {String path = 'question'}) {
    final map = readObject(json, path);
    final rawOptions = readList(map, 'options', path);
    if (rawOptions.length < minPhotoQuizOptions ||
        rawOptions.length > maxPhotoQuizOptions) {
      throw FormatException(
        '$path.options: expected $minPhotoQuizOptions to '
        '$maxPhotoQuizOptions options, got ${rawOptions.length}',
      );
    }
    return PhotoQuizQuestion(
      number: readInt(map, 'number', path),
      text: readString(map, 'text', path),
      options: [
        for (final (index, option) in rawOptions.indexed)
          PhotoQuizOption.fromJson(option, path: '$path.options[$index]'),
      ],
    );
  }

  /// The number printed next to the question on the worksheet.
  final int number;

  /// The question as printed; a blank in it is written `___`.
  final String text;

  /// The answer options in the order of the worksheet.
  final List<PhotoQuizOption> options;

  /// The JSON that [PhotoQuizQuestion.fromJson] reads back.
  Map<String, Object?> toJson() => {
    'number': number,
    'text': text,
    'options': [for (final option in options) option.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is PhotoQuizQuestion &&
      other.number == number &&
      other.text == text &&
      listEquals(other.options, options);

  @override
  int get hashCode => Object.hash(number, text, Object.hashAll(options));

  @override
  String toString() => 'PhotoQuizQuestion($number: $text)';
}
