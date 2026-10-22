import 'package:flutter/foundation.dart';
import 'package:languagelearner/features/photo_quiz/models/json_reader.dart';

/// One answer option of a question, as it is printed on the worksheet.
///
/// It does not say whether the option is the correct one: the worksheet does
/// not mark it. The shape matches `QuizOption` of the backend (card BE-14).
@immutable
class PhotoQuizOption {
  const PhotoQuizOption({required this.label, required this.text});

  /// Reads one option of the backend answer. Throws a [FormatException] when
  /// the label or the text is missing or blank.
  ///
  /// [path] is where the option sits in the answer, for the error message.
  factory PhotoQuizOption.fromJson(Object? json, {String path = 'option'}) {
    final map = readObject(json, path);
    return PhotoQuizOption(
      label: readString(map, 'label', path),
      text: readString(map, 'text', path),
    );
  }

  /// The label as printed: `a`, `b`, ... or `1`, `2`, ...
  final String label;

  /// The option as printed.
  final String text;

  @override
  bool operator ==(Object other) =>
      other is PhotoQuizOption && other.label == label && other.text == text;

  @override
  int get hashCode => Object.hash(label, text);

  @override
  String toString() => 'PhotoQuizOption($label: $text)';
}
