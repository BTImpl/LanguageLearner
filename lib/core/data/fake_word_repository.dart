import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';

/// Built-in decks, so the app works without the backend.
///
/// [refresh] only moves the `updatedAt` time of the decks to now, so the
/// "last updated" line of the settings screen can be tried out.
class FakeWordRepository implements WordRepository {
  FakeWordRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  DateTime _updatedAt = DateTime.utc(2026, 10, 7, 7, 12);

  @override
  Future<List<Deck>> getDecks() async => _buildDecks(_updatedAt);

  @override
  Future<void> refresh() async {
    _updatedAt = _now().toUtc();
  }

  @override
  Future<void> clearLocal() async {}
}

// A few words have a second accepted Hungarian text or an example sentence,
// to exercise those parts of the model.
List<Deck> _buildDecks(DateTime updatedAt) => [
  Deck(
    id: 'travel',
    name: 'Utazás',
    updatedAt: updatedAt,
    words: [
      WordPair.fromCells(
        id: 'travel-1',
        english: 'boarding pass',
        hungarian: 'beszállókártya',
      ),
      WordPair.fromCells(
        id: 'travel-2',
        english: 'luggage',
        hungarian: 'poggyász',
      ),
      WordPair.fromCells(
        id: 'travel-3',
        english: 'departure',
        hungarian: 'indulás',
      ),
      WordPair.fromCells(
        id: 'travel-4',
        english: 'arrival',
        hungarian: 'érkezés',
      ),
      WordPair.fromCells(
        id: 'travel-5',
        english: 'customs',
        hungarian: 'vámvizsgálat',
      ),
      WordPair.fromCells(
        id: 'travel-6',
        english: 'delay',
        hungarian: 'késés',
        example: 'The flight has a two-hour delay.',
      ),
      WordPair.fromCells(
        id: 'travel-7',
        english: 'ticket',
        hungarian: 'jegy; menetjegy',
      ),
      WordPair.fromCells(
        id: 'travel-8',
        english: 'passport',
        hungarian: 'útlevél',
      ),
      WordPair.fromCells(
        id: 'travel-9',
        english: 'suitcase',
        hungarian: 'bőrönd',
      ),
      WordPair.fromCells(
        id: 'travel-10',
        english: 'journey',
        hungarian: 'utazás',
      ),
      WordPair.fromCells(id: 'travel-11', english: 'gate', hungarian: 'kapu'),
      WordPair.fromCells(id: 'travel-12', english: 'seat', hungarian: 'ülés'),
    ],
  ),
  Deck(
    id: 'restaurant',
    name: 'Étterem',
    updatedAt: updatedAt,
    words: [
      WordPair.fromCells(
        id: 'restaurant-1',
        english: 'menu',
        hungarian: 'étlap',
      ),
      WordPair.fromCells(
        id: 'restaurant-2',
        english: 'waiter',
        hungarian: 'pincér',
      ),
      WordPair.fromCells(
        id: 'restaurant-3',
        english: 'bill',
        hungarian: 'számla',
      ),
      WordPair.fromCells(
        id: 'restaurant-4',
        english: 'table',
        hungarian: 'asztal',
      ),
      WordPair.fromCells(
        id: 'restaurant-5',
        english: 'tip',
        hungarian: 'borravaló',
      ),
    ],
  ),
];
