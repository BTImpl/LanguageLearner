import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/stats/data/attempt_record.dart';
import 'package:languagelearner/features/stats/data/attempt_store.dart';
import 'package:languagelearner/features/stats/data/attempt_sync_providers.dart';

class _MemoryKeys implements KeyValueStore {
  final values = <String, Object>{};

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<int?> getInt(String key) async => values[key] as int?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> setInt(String key, int value) async => values[key] = value;
}

class _BrokenKeys extends _MemoryKeys {
  @override
  Future<String?> getString(String key) => throw StateError('no storage');
}

final _record = AttemptRecord(
  id: 'a1',
  deckId: 'travel',
  wordId: 'w1',
  mode: PlayMode.quiz,
  outcome: WordOutcome.firstTry,
  answeredAt: DateTime.utc(2026, 10, 1),
);

void main() {
  late _MemoryKeys keys;
  late InMemoryAttemptStore store;

  setUp(() async {
    keys = _MemoryKeys();
    store = InMemoryAttemptStore();
    await store.insertAll([_record]);
  });

  test('the first student keeps the rows already on the phone', () async {
    final ok = await claimAttempts(
      keys: () => keys,
      store: store,
      email: 'a@x.hu',
    );

    expect(ok, isTrue);
    expect(await store.forDeck('travel'), hasLength(1));
    expect(keys.values[attemptOwnerKey], 'a@x.hu');
  });

  test('the same student signing in again keeps the rows', () async {
    await claimAttempts(keys: () => keys, store: store, email: 'a@x.hu');

    await claimAttempts(keys: () => keys, store: store, email: 'a@x.hu');

    expect(await store.forDeck('travel'), hasLength(1));
  });

  test(
    'another student signing in does not get, or upload, the rows',
    () async {
      await claimAttempts(keys: () => keys, store: store, email: 'a@x.hu');

      final ok = await claimAttempts(
        keys: () => keys,
        store: store,
        email: 'b@x.hu',
      );

      expect(ok, isTrue);
      expect(await store.forDeck('travel'), isEmpty);
      expect(keys.values[attemptOwnerKey], 'b@x.hu');
    },
  );

  test('says no when the owner cannot be checked', () async {
    final ok = await claimAttempts(
      keys: _BrokenKeys.new,
      store: store,
      email: 'a@x.hu',
    );

    expect(ok, isFalse);
    expect(await store.forDeck('travel'), hasLength(1));
  });
}
