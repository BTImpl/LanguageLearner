import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';

/// A [WordRepository] for tests whose answers the test scripts: [onGet]
/// decides what every [getDecks] call gives (it gets the number of the call,
/// from 1), [onRefresh] what [refresh] does.
class ScriptedWordRepository implements WordRepository {
  ScriptedWordRepository(this.onGet, {this.onRefresh});

  /// A repository that always gives [decks].
  ScriptedWordRepository.always(List<Deck> decks) : this((_) async => decks);

  final Future<List<Deck>> Function(int call) onGet;
  final Future<void> Function()? onRefresh;

  var gets = 0;
  var refreshes = 0;

  @override
  Future<List<Deck>> getDecks() => onGet(++gets);

  @override
  Future<void> refresh() async {
    refreshes++;
    await onRefresh?.call();
  }

  @override
  Future<void> clearLocal() async {}
}

/// A deck with [wordCount] words (`a1` = `b1`, `a2` = `b2`, ...).
Deck testDeck(int wordCount, {String id = 'deck', String name = 'Deck'}) =>
    Deck(
      id: id,
      name: name,
      updatedAt: DateTime.utc(2026, 10, 19, 8),
      words: [
        for (var i = 1; i <= wordCount; i++)
          WordPair.fromCells(id: '$id-$i', english: 'a$i', hungarian: 'b$i'),
      ],
    );
