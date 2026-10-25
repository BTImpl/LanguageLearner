import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/photo_quiz/saved/saved_quiz.dart';
import 'package:languagelearner/features/photo_quiz/saved/saved_quiz_store.dart';

/// The saved quizzes of the signed-in student, the last used one first.
final savedQuizzesProvider =
    AsyncNotifierProvider.autoDispose<SavedQuizzes, List<SavedQuiz>>(
      SavedQuizzes.new,
    );

class SavedQuizzes extends AsyncNotifier<List<SavedQuiz>> {
  String? get _student => ref.read(accountProvider)?.email;

  @override
  Future<List<SavedQuiz>> build() async {
    final student = ref.watch(accountProvider)?.email;
    if (student == null) {
      return const [];
    }
    return ref.read(savedQuizStoreProvider).list(student);
  }

  /// Counts a start of [entry] and gives back the stored quiz, or null when it
  /// is not there any more.
  Future<SavedQuiz?> start(SavedQuiz entry) async {
    final student = _student;
    if (student == null) {
      return entry;
    }
    final now = ref.read(clockProvider)();
    return ref.read(savedQuizStoreProvider).markUsed(student, entry.id, now);
  }

  Future<void> delete(SavedQuiz entry) =>
      _change((store, student) => store.delete(student, entry.id));

  Future<void> restore(SavedQuiz entry) =>
      _change((store, student) => store.restore(student, entry));

  Future<void> _change(
    Future<void> Function(SavedQuizStore store, String student) change,
  ) async {
    final student = _student;
    if (student == null) {
      return;
    }
    final store = ref.read(savedQuizStoreProvider);
    await change(store, student);
    final entries = await store.list(student);
    if (ref.mounted) {
      state = AsyncData(entries);
    }
  }
}
