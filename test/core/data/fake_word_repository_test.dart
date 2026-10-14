import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/data/fake_word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';

void main() {
  final refreshTime = DateTime(2026, 10, 14, 15, 30);
  late FakeWordRepository repository;
  late List<Deck> decks;

  setUp(() async {
    repository = FakeWordRepository(now: () => refreshTime);
    decks = await repository.getDecks();
  });

  test('has the travel deck with 12 words and a second deck with 5', () {
    expect(decks.map((deck) => deck.name), ['Utazás', 'Étterem']);
    expect(decks[0].words, hasLength(12));
    expect(decks[1].words, hasLength(5));
  });

  test('the travel deck has the planned words in order', () {
    final pairs = [
      for (final word in decks[0].words) (word.english, word.hungarian),
    ];

    expect(pairs, [
      ('boarding pass', 'beszállókártya'),
      ('luggage', 'poggyász'),
      ('departure', 'indulás'),
      ('arrival', 'érkezés'),
      ('customs', 'vámvizsgálat'),
      ('delay', 'késés'),
      ('ticket', 'jegy'),
      ('passport', 'útlevél'),
      ('suitcase', 'bőrönd'),
      ('journey', 'utazás'),
      ('gate', 'kapu'),
      ('seat', 'ülés'),
    ]);
  });

  test('ids are unique across all decks', () {
    final ids = [
      for (final deck in decks) deck.id,
      for (final deck in decks)
        for (final word in deck.words) word.id,
    ];

    expect(ids.toSet(), hasLength(ids.length));
  });

  test('the shown texts are among the accepted ones', () {
    for (final deck in decks) {
      for (final word in deck.words) {
        expect(word.acceptedEnglish, contains(word.english), reason: word.id);
        expect(
          word.acceptedHungarian,
          contains(word.hungarian),
          reason: word.id,
        );
      }
    }
  });

  test('some words exercise a second accepted text and an example', () {
    final words = decks[0].words;

    expect(words.any((word) => word.acceptedHungarian.length > 1), isTrue);
    expect(words.any((word) => word.example != null), isTrue);
  });

  test('refresh moves the update time to now and keeps the words', () async {
    expect(decks.first.updatedAt, DateTime.utc(2026, 10, 7, 7, 12));

    await repository.refresh();

    final refreshed = await repository.getDecks();
    expect(refreshed.map((deck) => deck.updatedAt).toSet(), {
      refreshTime.toUtc(),
    });
    expect(
      [for (final deck in refreshed) deck.words],
      [for (final deck in decks) deck.words],
    );
  });
}
