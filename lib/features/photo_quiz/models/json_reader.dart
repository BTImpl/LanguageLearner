/// Helpers that read the JSON of the backend (cards BE-13, BE-14) and fail with
/// a [FormatException] that names the field, e.g.
/// `questions[2].options: expected 2 to 5 options, got 1`.
///
/// A `path` is where the object being read sits in the answer; it is empty for
/// the top level.
String _at(String path, String key) => path.isEmpty ? key : '$path.$key';

/// [json] as an object, or a [FormatException] when it is something else.
Map<Object?, Object?> readObject(Object? json, String path) {
  if (json is Map<Object?, Object?>) {
    return json;
  }
  throw FormatException('$path: expected an object');
}

/// The required, non-blank text under [key], without the whitespace around it.
String readString(Map<Object?, Object?> json, String key, String path) {
  final value = json[key];
  if (value == null) {
    throw FormatException('${_at(path, key)}: missing');
  }
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('${_at(path, key)}: expected a non-empty text');
  }
  return value.trim();
}

/// The text under [key], or null when it is missing, null or blank.
String? readOptionalString(
  Map<Object?, Object?> json,
  String key,
  String path,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('${_at(path, key)}: expected a text');
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// The required whole number under [key].
int readInt(Map<Object?, Object?> json, String key, String path) {
  final value = json[key];
  if (value == null) {
    throw FormatException('${_at(path, key)}: missing');
  }
  if (value is! int) {
    throw FormatException('${_at(path, key)}: expected a whole number');
  }
  return value;
}

/// The whole number under [key] that is 0 or more, or [fallback] when it is
/// missing or null.
int readOptionalCount(
  Map<Object?, Object?> json,
  String key,
  String path, {
  required int fallback,
}) {
  final value = json[key];
  if (value == null) {
    return fallback;
  }
  if (value is! int || value < 0) {
    throw FormatException(
      '${_at(path, key)}: expected a whole number, 0 or more',
    );
  }
  return value;
}

/// The required list under [key].
List<Object?> readList(Map<Object?, Object?> json, String key, String path) {
  final value = json[key];
  if (value == null) {
    throw FormatException('${_at(path, key)}: missing');
  }
  if (value is! List<Object?>) {
    throw FormatException('${_at(path, key)}: expected a list');
  }
  return value;
}
