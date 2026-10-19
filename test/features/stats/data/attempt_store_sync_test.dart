import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/database/app_database.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/stats/data/attempt_record.dart';
import 'package:languagelearner/features/stats/data/attempt_store.dart';

AttemptRecord _record(String id, int minute, {bool synced = false}) =>
    AttemptRecord(
      id: id,
      deckId: 'travel',
      wordId: 'w1',
      mode: PlayMode.quiz,
      outcome: WordOutcome.firstTry,
      answeredAt: DateTime.utc(2026, 10, 1, 8, minute),
      synced: synced,
    );

/// The sync part of the store, on both implementations.
void _tests(AttemptStore Function() createStore) {
  late AttemptStore store;

  setUp(() => store = createStore());

  Future<List<String>> pendingIds({int limit = 100}) async => [
    for (final record in await store.pending(limit: limit)) record.id,
  ];

  test('pending is the oldest first and honours the limit', () async {
    await store.insertAll([_record('c', 3), _record('a', 1), _record('b', 2)]);

    expect(await pendingIds(), ['a', 'b', 'c']);
    expect(await pendingIds(limit: 2), ['a', 'b']);
  });

  test('pending skips synced rows', () async {
    await store.insertAll([_record('a', 1, synced: true), _record('b', 2)]);

    expect(await pendingIds(), ['b']);
  });

  test('markSynced removes rows from pending and keeps them', () async {
    await store.insertAll([_record('a', 1), _record('b', 2)]);

    await store.markSynced(['a']);

    expect(await pendingIds(), ['b']);
    final records = await store.forDeck('travel');
    expect(records.map((r) => r.synced), [true, false]);
  });

  test('markRejected removes rows from pending and keeps them', () async {
    await store.insertAll([_record('a', 1), _record('b', 2)]);

    await store.markRejected(['a', 'b']);

    expect(await pendingIds(), isEmpty);
    expect(await store.forDeck('travel'), hasLength(2));
  });

  test('clear forgets every row', () async {
    await store.insertAll([_record('a', 1), _record('b', 2)]);
    await store.markRejected(['a']);

    await store.clear();

    expect(await store.forDeck('travel'), isEmpty);
    expect(await pendingIds(), isEmpty);
  });
}

void main() {
  group('with the in-memory store', () => _tests(InMemoryAttemptStore.new));

  group('with the SQLite database', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    _tests(() => DriftAttemptStore(database));
  });
}
