import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/saved/quiz_fingerprint.dart';
import 'package:languagelearner/features/photo_quiz/saved/saved_quiz.dart';

/// How many quizzes a student keeps; the one used longest ago makes room for
/// the 51st.
const int maxSavedQuizzes = 50;

/// What [SavedQuizStore.record] did.
class RecordedQuiz {
  const RecordedQuiz({required this.entry, required this.duplicate});

  /// The saved quiz that the student starts now.
  final SavedQuiz entry;

  /// The same content was already saved: nothing new was added, only the
  /// time of the last use changed.
  final bool duplicate;
}

/// The quizzes read from photos that stay on the phone, for each student
/// separately.
///
/// An interface, so that the screens can be tested without a real storage; the
/// app uses [KeyValueSavedQuizStore].
abstract interface class SavedQuizStore {
  /// The quizzes of [studentId], the last used one first.
  Future<List<SavedQuiz>> list(String studentId);

  /// Keeps [quiz] for a start at [now]; a quiz with the same content is not
  /// added again, it counts as used again.
  Future<RecordedQuiz> record(String studentId, PhotoQuiz quiz, DateTime now);

  /// Counts a start of the saved quiz [id] at [now]. Null when it is gone.
  Future<SavedQuiz?> markUsed(String studentId, String id, DateTime now);

  /// Removes the saved quiz [id].
  Future<void> delete(String studentId, String id);

  /// Puts [entry] back as it was (the undo of [delete]).
  Future<void> restore(String studentId, SavedQuiz entry);
}

/// Where the app keeps the saved quizzes.
final savedQuizStoreProvider = Provider<SavedQuizStore>(
  (ref) => KeyValueSavedQuizStore(ref.watch(keyValueStoreProvider)),
);

/// [SavedQuizStore] that keeps one JSON text per student in a [KeyValueStore].
///
/// An entry that cannot be read any more is left out instead of failing the
/// whole list.
class KeyValueSavedQuizStore implements SavedQuizStore {
  KeyValueSavedQuizStore(this._store);

  final KeyValueStore _store;

  static String _key(String studentId) =>
      'savedQuizzes.v1.${studentId.trim().toLowerCase()}';

  @override
  Future<List<SavedQuiz>> list(String studentId) async {
    final text = await _store.getString(_key(studentId));
    if (text == null) {
      return <SavedQuiz>[];
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      return <SavedQuiz>[];
    }
    if (decoded is! List<Object?>) {
      return <SavedQuiz>[];
    }
    final entries = <SavedQuiz>[];
    for (final item in decoded) {
      try {
        entries.add(SavedQuiz.fromJson(item));
      } on FormatException {
        // A damaged entry is dropped.
      }
    }
    return _sorted(entries);
  }

  Future<void> _write(String studentId, List<SavedQuiz> entries) {
    final kept = _sorted(entries).take(maxSavedQuizzes).toList();
    return _store.setString(
      _key(studentId),
      jsonEncode([for (final entry in kept) entry.toJson()]),
    );
  }

  @override
  Future<RecordedQuiz> record(
    String studentId,
    PhotoQuiz quiz,
    DateTime now,
  ) async {
    final id = quizFingerprint(quiz);
    final entries = await list(studentId);
    final index = entries.indexWhere((entry) => entry.id == id);
    final SavedQuiz entry;
    final bool duplicate;
    if (index >= 0) {
      entry = entries[index].usedAt(now);
      entries[index] = entry;
      duplicate = true;
    } else {
      entry = SavedQuiz(
        id: id,
        quiz: quiz,
        createdAt: now,
        lastUsedAt: now,
        fillCount: 1,
      );
      entries.add(entry);
      duplicate = false;
    }
    await _write(studentId, entries);
    return RecordedQuiz(entry: entry, duplicate: duplicate);
  }

  @override
  Future<SavedQuiz?> markUsed(String studentId, String id, DateTime now) async {
    final entries = await list(studentId);
    final index = entries.indexWhere((entry) => entry.id == id);
    if (index < 0) {
      return null;
    }
    final entry = entries[index].usedAt(now);
    entries[index] = entry;
    await _write(studentId, entries);
    return entry;
  }

  @override
  Future<void> delete(String studentId, String id) async {
    final entries = await list(studentId);
    entries.removeWhere((entry) => entry.id == id);
    await _write(studentId, entries);
  }

  @override
  Future<void> restore(String studentId, SavedQuiz entry) async {
    final entries = await list(studentId)
      ..removeWhere((e) => e.id == entry.id)
      ..add(entry);
    await _write(studentId, entries);
  }

  static List<SavedQuiz> _sorted(List<SavedQuiz> entries) =>
      [...entries]..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
}
