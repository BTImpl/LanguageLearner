import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/data/cached_word_repository.dart';
import 'package:languagelearner/core/data/deck_cache.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';

class _FakeRemote implements WordRepository {
  _FakeRemote(this.decks);

  List<Deck> decks;

  /// What [refresh] changes the decks to.
  List<Deck>? refreshedDecks;

  /// When set, both calls throw it.
  Exception? error;

  /// When set, [getDecks] waits for it.
  Completer<void>? gate;

  var getCalls = 0;
  var refreshCalls = 0;

  @override
  Future<List<Deck>> getDecks() async {
    getCalls++;
    await gate?.future;
    if (error case final error?) {
      throw error;
    }
    return decks;
  }

  @override
  Future<void> refresh() async {
    refreshCalls++;
    if (error case final error?) {
      throw error;
    }
    decks = refreshedDecks ?? decks;
  }

  @override
  Future<void> clearLocal() async {}
}

class _BrokenCache implements DeckCache {
  @override
  Future<DeckSnapshot?> read() => throw Exception('disk');

  @override
  Future<void> replace(List<Deck> decks, DateTime fetchedAt) =>
      throw Exception('disk');

  @override
  Future<void> clear() async {}
}

Deck _deck(String id, {int words = 1}) => Deck(
  id: id,
  name: 'Deck $id',
  updatedAt: DateTime.utc(2026, 10, 19, 8),
  words: [
    for (var i = 0; i < words; i++)
      WordPair.fromCells(id: '$id-$i', english: 'a$i', hungarian: 'b$i'),
  ],
);

const _noNetwork = WordLoadException(WordLoadFailure.noNetwork);

void main() {
  final start = DateTime.utc(2026, 10, 19, 12);
  late DateTime now;
  late InMemoryDeckCache cache;
  late _FakeRemote remote;
  late int updates;
  late CachedWordRepository repository;

  setUp(() {
    now = start;
    cache = InMemoryDeckCache();
    remote = _FakeRemote([_deck('new')]);
    updates = 0;
    repository = CachedWordRepository(
      remote: remote,
      cache: cache,
      now: () => now,
      onBackgroundUpdate: () => updates++,
    );
  });

  void saveFetchedMinutesAgo(int minutes, List<Deck> decks) {
    cache.snapshot = DeckSnapshot(
      decks: decks,
      fetchedAt: start.subtract(Duration(minutes: minutes)),
    );
  }

  group('nothing saved yet', () {
    test('downloads the decks, saves them and gives them back', () async {
      final decks = await repository.getDecks();

      expect(decks, [_deck('new')]);
      expect(remote.getCalls, 1);
      expect(cache.snapshot?.decks, [_deck('new')]);
      expect(cache.snapshot?.fetchedAt, start);
    });

    test('a failed download throws and saves nothing', () async {
      remote.error = _noNetwork;

      await expectLater(repository.getDecks(), throwsA(_noNetwork));

      expect(cache.snapshot, isNull);
    });

    test('a broken local database counts as nothing saved', () async {
      final broken = CachedWordRepository(
        remote: remote,
        cache: _BrokenCache(),
        now: () => now,
        onBackgroundUpdate: () {},
      );

      expect(await broken.getDecks(), [_deck('new')]);
    });
  });

  group('saved decks', () {
    test('fresh decks are given back without asking the backend', () async {
      saveFetchedMinutesAgo(14, [_deck('old')]);

      final decks = await repository.getDecks();
      await pumpEventQueue();

      expect(decks, [_deck('old')]);
      expect(remote.getCalls, 0);
      expect(updates, 0);
    });

    test(
      'stale decks come first, the update follows in the background',
      () async {
        saveFetchedMinutesAgo(16, [_deck('old')]);

        final decks = await repository.getDecks();

        expect(decks, [
          _deck('old'),
        ], reason: 'the saved decks are not awaited');
        await pumpEventQueue();
        expect(remote.getCalls, 1);
        expect(cache.snapshot?.decks, [_deck('new')]);
        expect(cache.snapshot?.fetchedAt, start);
        expect(updates, 1);
        // The next read is fresh again.
        expect(await repository.getDecks(), [_deck('new')]);
        expect(remote.getCalls, 1);
      },
    );

    test('a background update with the same decks tells nobody', () async {
      saveFetchedMinutesAgo(30, [_deck('new')]);

      await repository.getDecks();
      await pumpEventQueue();

      expect(remote.getCalls, 1);
      expect(updates, 0);
      expect(cache.snapshot?.fetchedAt, start);
    });

    test('a failed background update keeps the saved decks', () async {
      saveFetchedMinutesAgo(30, [_deck('old')]);
      remote.error = _noNetwork;

      final decks = await repository.getDecks();
      await pumpEventQueue();

      expect(decks, [_deck('old')]);
      expect(cache.snapshot?.decks, [_deck('old')]);
      expect(updates, 0);
    });

    test('decks saved "in the future" count as stale', () async {
      saveFetchedMinutesAgo(-5, [_deck('old')]);

      await repository.getDecks();
      await pumpEventQueue();

      expect(remote.getCalls, 1);
    });

    test('only one background update runs at a time', () async {
      saveFetchedMinutesAgo(30, [_deck('old')]);
      remote.gate = Completer<void>();

      await repository.getDecks();
      await repository.getDecks();
      remote.gate!.complete();
      await pumpEventQueue();

      expect(remote.getCalls, 1);
      expect(updates, 1);
    });
  });

  group('refresh', () {
    test('asks the backend and replaces the saved decks', () async {
      saveFetchedMinutesAgo(1, [_deck('old')]);
      remote.refreshedDecks = [_deck('fresh', words: 2)];

      await repository.refresh();

      expect(remote.refreshCalls, 1);
      expect(cache.snapshot?.decks, [_deck('fresh', words: 2)]);
      expect(cache.snapshot?.fetchedAt, start);
      expect(await repository.getDecks(), [_deck('fresh', words: 2)]);
    });

    test('a failed refresh throws and keeps the saved decks', () async {
      saveFetchedMinutesAgo(1, [_deck('old')]);
      remote.error = _noNetwork;

      await expectLater(repository.refresh(), throwsA(_noNetwork));

      expect(cache.snapshot?.decks, [_deck('old')]);
      expect(await repository.getDecks(), [_deck('old')]);
    });

    test('a deck the teacher removed is gone after the refresh', () async {
      saveFetchedMinutesAgo(1, [_deck('a'), _deck('b')]);
      remote.refreshedDecks = [_deck('b')];

      await repository.refresh();

      expect((await repository.getDecks()).map((deck) => deck.id), ['b']);
    });
  });

  group('clearLocal', () {
    test('forgets the saved decks', () async {
      saveFetchedMinutesAgo(1, [_deck('old')]);

      await repository.clearLocal();

      expect(cache.snapshot, isNull);
    });

    test('a download that started before it does not save its decks', () async {
      remote.gate = Completer<void>();
      final loading = repository.getDecks();
      await pumpEventQueue();

      await repository.clearLocal();
      remote.gate!.complete();
      await loading;

      expect(cache.snapshot, isNull);
    });

    test('a background update that started before it saves nothing', () async {
      saveFetchedMinutesAgo(30, [_deck('old')]);
      remote.gate = Completer<void>();
      await repository.getDecks();

      await repository.clearLocal();
      remote.gate!.complete();
      await pumpEventQueue();

      expect(cache.snapshot, isNull);
      expect(updates, 0);
    });
  });
}
