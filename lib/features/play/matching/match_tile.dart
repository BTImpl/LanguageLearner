import 'package:flutter/foundation.dart';
import 'package:languagelearner/core/models/word_pair.dart';

/// The two columns of a matching page.
enum MatchSide { english, hungarian }

/// What a tile looks like and whether it can be tapped.
enum TileState {
  /// Not touched; can be tapped.
  idle,

  /// Picked by the student, waiting for a tile in the other column.
  selected,

  /// Part of a correct pair; disappears after a short while. Cannot be tapped.
  matched,

  /// Part of a wrong pair; goes back to [idle] after a while. Cannot be
  /// tapped.
  wrong,
}

/// One tile of a matching page: the [side] of [word] shown in its column.
@immutable
class MatchTile {
  const MatchTile({
    required this.word,
    required this.side,
    this.state = TileState.idle,
  });

  final WordPair word;
  final MatchSide side;
  final TileState state;

  /// The text of the tile: the word in the language of its column.
  String get text => switch (side) {
    MatchSide.english => word.english,
    MatchSide.hungarian => word.hungarian,
  };

  MatchTile withState(TileState state) =>
      MatchTile(word: word, side: side, state: state);

  @override
  bool operator ==(Object other) =>
      other is MatchTile &&
      other.word == word &&
      other.side == side &&
      other.state == state;

  @override
  int get hashCode => Object.hash(word, side, state);

  @override
  String toString() => 'MatchTile(${word.id}, ${side.name}, ${state.name})';
}
