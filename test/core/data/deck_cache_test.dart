import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/data/deck_cache.dart';
import 'package:languagelearner/core/database/app_database.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';

final _fetchedAt = DateTime.utc(2026, 10, 19, 12);

Deck _deck(String id, List<WordPair> words) => Deck(
  id: id,
  name: 'Deck $id',
  updatedAt: DateTime.utc(2026, 10, 19, 8),
  words: words,
);

final _travel = _deck('travel', [
  WordPair.fromCells(
    id: 't1',
    english: 'ticket; fare',
    hungarian: 'jegy; menetjegy',
    example: 'One ticket, please.',
  ),
  WordPair.fromCells(id: 't2', english: 'luggage', hungarian: 'poggyász'),
  WordPair.fromCells(id: 't3', english: 'gate', hungarian: 'kapu'),
]);
final _food = _deck('food', [
  WordPair.fromCells(id: 'f1', english: 'bread', hungarian: 'kenyér'),
]);

void _tests(DeckCache Function() create) {
  late DeckCache cache;

  setUp(() => cache = create());

  test('is empty at first', () async {
    expect(await cache.read(), isNull);
  });

  test('gives back what was saved: order, variants, example, time', () async {
    await cache.replace([_travel, _food], _fetchedAt);

    final snapshot = await cache.read();

    expect(snapshot?.decks, [_travel, _food]);
    expect(snapshot?.fetchedAt, _fetchedAt);
    final first = snapshot!.decks.first.words.first;
    expect(first.acceptedEnglish, ['ticket', 'fare']);
    expect(first.acceptedHungarian, ['jegy', 'menetjegy']);
    expect(first.example, 'One ticket, please.');
    expect(snapshot.decks.first.words[1].example, isNull);
  });

  test('replace swaps everything, so removed decks and words go', () async {
    await cache.replace([_travel, _food], _fetchedAt);
    final shorter = _deck('travel', [_travel.words.first]);

    await cache.replace([shorter], _fetchedAt.add(const Duration(hours: 1)));

    final snapshot = await cache.read();
    expect(snapshot?.decks, [shorter]);
    expect(snapshot?.fetchedAt, _fetchedAt.add(const Duration(hours: 1)));
  });

  test('a deck without words is kept', () async {
    await cache.replace([_deck('empty', const [])], _fetchedAt);

    expect((await cache.read())?.decks.single.words, isEmpty);
  });

  test('clear forgets everything', () async {
    await cache.replace([_travel], _fetchedAt);

    await cache.clear();

    expect(await cache.read(), isNull);
  });

  test('no decks at all is saved as nothing', () async {
    await cache.replace([_travel], _fetchedAt);

    await cache.replace(const [], _fetchedAt);

    expect(await cache.read(), isNull);
  });
}

void main() {
  group('in memory', () => _tests(InMemoryDeckCache.new));

  group('with the SQLite database', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    _tests(() => DriftDeckCache(database));
  });
}
