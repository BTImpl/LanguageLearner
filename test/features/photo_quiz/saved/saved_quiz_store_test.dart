import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_option.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_question.dart';
import 'package:languagelearner/features/photo_quiz/saved/quiz_fingerprint.dart';
import 'package:languagelearner/features/photo_quiz/saved/saved_quiz_store.dart';

import '../../../helpers/in_memory_key_value_store.dart';

const _anna = 'kiss.anna@example.com';
const _bela = 'nagy.bela@example.com';

PhotoQuiz _numbered(int n) => PhotoQuiz(
  title: 'Quiz $n',
  questions: [
    PhotoQuizQuestion(
      number: 1,
      text: 'Question $n',
      options: const [
        PhotoQuizOption(label: 'a', text: 'yes'),
        PhotoQuizOption(label: 'b', text: 'no'),
      ],
    ),
  ],
);

void main() {
  late InMemoryKeyValueStore storage;
  late KeyValueSavedQuizStore store;
  final t0 = DateTime.utc(2026, 10, 1, 10);

  setUp(() {
    storage = InMemoryKeyValueStore();
    store = KeyValueSavedQuizStore(storage);
  });

  test('a recorded quiz is read back with its content', () async {
    final recorded = await store.record(_anna, samplePhotoQuiz(), t0);

    expect(recorded.duplicate, isFalse);
    final entries = await store.list(_anna);
    expect(entries, hasLength(1));
    expect(entries.single.quiz, samplePhotoQuiz());
    expect(entries.single.id, quizFingerprint(samplePhotoQuiz()));
    expect(entries.single.createdAt, t0);
    expect(entries.single.lastUsedAt, t0);
    expect(entries.single.fillCount, 1);
  });

  test('survives a restart: a new store reads the same list', () async {
    await store.record(_anna, samplePhotoQuiz(), t0);

    final again = KeyValueSavedQuizStore(storage);

    expect(await again.list(_anna), hasLength(1));
  });

  test('the same content is not added twice, only the use changes', () async {
    await store.record(_anna, samplePhotoQuiz(), t0);
    final later = t0.add(const Duration(days: 2));

    final recorded = await store.record(_anna, samplePhotoQuiz(), later);

    expect(recorded.duplicate, isTrue);
    final entries = await store.list(_anna);
    expect(entries, hasLength(1));
    expect(entries.single.createdAt, t0);
    expect(entries.single.lastUsedAt, later);
    expect(entries.single.fillCount, 2);
  });

  test('a quiz that differs slightly is a new entry', () async {
    await store.record(_anna, samplePhotoQuiz(), t0);

    final recorded = await store.record(
      _anna,
      samplePhotoQuiz().withoutQuestionAt(0),
      t0,
    );

    expect(recorded.duplicate, isFalse);
    expect(await store.list(_anna), hasLength(2));
  });

  test('students do not see each other\'s quizzes', () async {
    await store.record(_anna, samplePhotoQuiz(), t0);

    expect(await store.list(_bela), isEmpty);
    final recorded = await store.record(_bela, samplePhotoQuiz(), t0);
    expect(recorded.duplicate, isFalse);
    expect(await store.list(_anna), hasLength(1));
    expect(await store.list(_bela), hasLength(1));
  });

  test('the e-mail address is compared without case', () async {
    await store.record('Kiss.Anna@Example.com', samplePhotoQuiz(), t0);

    expect(await store.list(_anna), hasLength(1));
  });

  test('the list is sorted by the last use, latest first', () async {
    await store.record(_anna, _numbered(1), t0);
    await store.record(_anna, _numbered(2), t0.add(const Duration(hours: 1)));
    await store.record(_anna, _numbered(3), t0.add(const Duration(hours: 2)));
    await store.markUsed(
      _anna,
      quizFingerprint(_numbered(1)),
      t0.add(const Duration(hours: 3)),
    );

    final titles = [
      for (final entry in await store.list(_anna)) entry.quiz.title,
    ];

    expect(titles, ['Quiz 1', 'Quiz 3', 'Quiz 2']);
  });

  test('markUsed counts the start; an unknown id gives null', () async {
    final recorded = await store.record(_anna, samplePhotoQuiz(), t0);
    final later = t0.add(const Duration(days: 1));

    final used = await store.markUsed(_anna, recorded.entry.id, later);

    expect(used?.fillCount, 2);
    expect(used?.lastUsedAt, later);
    expect(await store.markUsed(_anna, 'missing', later), isNull);
  });

  test('keeps 50 quizzes: the 51st pushes out the longest unused', () async {
    for (var i = 0; i < maxSavedQuizzes; i++) {
      await store.record(_anna, _numbered(i), t0.add(Duration(minutes: i)));
    }
    expect(await store.list(_anna), hasLength(maxSavedQuizzes));

    await store.record(_anna, _numbered(99), t0.add(const Duration(days: 1)));

    final entries = await store.list(_anna);
    expect(entries, hasLength(maxSavedQuizzes));
    expect(entries.first.quiz.title, 'Quiz 99');
    expect(entries.any((e) => e.quiz.title == 'Quiz 0'), isFalse);
    expect(entries.any((e) => e.quiz.title == 'Quiz 1'), isTrue);
  });

  test('delete removes one quiz, restore puts it back as it was', () async {
    final recorded = await store.record(_anna, samplePhotoQuiz(), t0);
    await store.record(_anna, _numbered(2), t0.add(const Duration(hours: 1)));

    await store.delete(_anna, recorded.entry.id);
    expect(await store.list(_anna), hasLength(1));

    await store.restore(_anna, recorded.entry);
    final entries = await store.list(_anna);
    expect(entries, hasLength(2));
    expect(entries.last, recorded.entry);
  });

  test('damaged storage gives an empty list, not an error', () async {
    storage.values['savedQuizzes.v1.$_anna'] = 'not json';
    expect(await store.list(_anna), isEmpty);

    storage.values['savedQuizzes.v1.$_anna'] = '{"a": 1}';
    expect(await store.list(_anna), isEmpty);
  });

  test('a damaged entry is left out, the others stay', () async {
    await store.record(_anna, samplePhotoQuiz(), t0);
    final text = storage.values['savedQuizzes.v1.$_anna']! as String;
    storage.values['savedQuizzes.v1.$_anna'] =
        '${text.substring(0, text.length - 1)},{"id":"x"}]';

    expect(await store.list(_anna), hasLength(1));
  });

  test('only the quiz and its use are stored, no photo or answers', () async {
    await store.record(_anna, samplePhotoQuiz(), t0);

    final stored = jsonDecode(
      storage.values['savedQuizzes.v1.$_anna']! as String,
    ) as List<Object?>;
    final entry = stored.single! as Map<String, Object?>;

    expect(
      entry.keys,
      unorderedEquals(['id', 'quiz', 'createdAt', 'lastUsedAt', 'fillCount']),
    );
    expect(
      (entry['quiz']! as Map<String, Object?>).keys,
      unorderedEquals(['title', 'questions', 'skippedQuestions']),
    );
  });
}
