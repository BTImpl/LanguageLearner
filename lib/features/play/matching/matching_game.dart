import 'dart:math';

import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/matching/match_tile.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/round/schedule.dart';

/// The rules of the matching game, independent of any screen.
///
/// The words of the [session] are cut into pages of [pairsPerPage] words (the
/// last page may be smaller). A page has two columns, English and Hungarian,
/// each shuffled on its own. Pages follow each other until every word has
/// been on one.
///
/// Tapping a tile selects it (see [tap]); when both columns have a selected
/// tile they form a pair: a correct pair is [TileState.matched] and
/// disappears after [matchedDelay], a wrong one is [TileState.wrong] and
/// returns to normal after [wrongDelay]. Other tiles stay tappable meanwhile.
///
/// The outcome goes to the [session]: a word is `firstTry` unless it was in a
/// wrong pair.
class MatchingGame {
  MatchingGame({
    required this.session,
    required this.pairsPerPage,
    this.singlePage = false,
    Random? random,
    Schedule? schedule,
    this.matchedDelay = const Duration(milliseconds: 400),
    this.wrongDelay = const Duration(seconds: 1),
  }) : assert(pairsPerPage >= 1, 'A page needs at least one pair.'),
       _random = random ?? Random(),
       _schedule = schedule ?? timerSchedule {
    if (!session.isFinished) {
      _startPage();
    }
  }

  final RoundSession session;
  final int pairsPerPage;

  /// With `true` the game is just one page: when its pairs are all found
  /// [pageDone] turns `true` and no further page starts. The Mix mode plays
  /// the matching game like this, one page per step.
  final bool singlePage;
  final Duration matchedDelay;
  final Duration wrongDelay;

  final Random _random;
  final Schedule _schedule;
  final _listeners = <void Function()>[];
  final _pending = <Cancel>[];
  var _disposed = false;

  var _english = <MatchTile>[];
  var _hungarian = <MatchTile>[];
  var _pageSize = 0;
  var _pageDone = false;

  /// The English column of the current page, without the pairs that are gone.
  List<MatchTile> get englishTiles => List.unmodifiable(_english);

  /// The Hungarian column of the current page, without the pairs that are
  /// gone.
  List<MatchTile> get hungarianTiles => List.unmodifiable(_hungarian);

  /// Whether the pairs of the page are all found and the page is over. With
  /// pages following each other it is only `true` until the next page starts.
  bool get pageDone => _pageDone;

  /// The number of pages the round has.
  int get pageCount => (session.total / pairsPerPage).ceil();

  /// The current page, from 0.
  int get pageIndex => session.index ~/ pairsPerPage;

  /// Whether every word has been paired.
  bool get isFinished => session.isFinished;

  /// The outcome so far, see [RoundSession.result]. The number of wrong pairs
  /// and pages are in its extras ([RoundCounters.wrongPairs],
  /// [RoundCounters.pages]).
  RoundResult get result => session.result;

  /// Calls [listener] after every change.
  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// The tile of [word] in the column [side] of the current page, `null` if
  /// it is not there (any more).
  MatchTile? tile(WordPair word, MatchSide side) {
    for (final tile in _column(side)) {
      if (tile.word.id == word.id) {
        return tile;
      }
    }
    return null;
  }

  /// The student tapped the tile of [word] in the column [side].
  ///
  /// - An idle tile becomes selected; a selected tile of the same column is
  ///   deselected, so the selection moves.
  /// - A selected tile becomes idle again.
  /// - Matched and wrong tiles ignore the tap.
  /// - If the other column has a selected tile too, they form a pair.
  void tap(WordPair word, MatchSide side) {
    final tapped = tile(word, side);
    if (_disposed || isFinished || tapped == null) {
      return;
    }
    switch (tapped.state) {
      case TileState.matched || TileState.wrong:
        return;
      case TileState.selected:
        _setState(word.id, side, TileState.idle);
      case TileState.idle:
        for (final other in _column(side)) {
          if (other.state == TileState.selected) {
            _setState(other.word.id, side, TileState.idle);
          }
        }
        _setState(word.id, side, TileState.selected);
        final partner = _selectedIn(_opposite(side));
        if (partner != null) {
          _pair(
            side == MatchSide.english ? word : partner.word,
            side == MatchSide.english ? partner.word : word,
          );
        }
    }
    _notify();
  }

  /// Cancels everything scheduled; the game ignores taps afterwards.
  void dispose() {
    _disposed = true;
    for (final cancel in _pending) {
      cancel();
    }
    _pending.clear();
    _listeners.clear();
  }

  void _pair(WordPair english, WordPair hungarian) {
    if (english.id == hungarian.id) {
      _setState(english.id, MatchSide.english, TileState.matched);
      _setState(english.id, MatchSide.hungarian, TileState.matched);
      // Ignored by the session if the word already had a wrong pair.
      session.recordAttempt(english, correct: true);
      _after(matchedDelay, () => _remove(english.id));
    } else {
      _setState(english.id, MatchSide.english, TileState.wrong);
      _setState(hungarian.id, MatchSide.hungarian, TileState.wrong);
      session
        ..count(RoundCounters.wrongPairs)
        ..recordAttempt(english, correct: false)
        ..recordAttempt(hungarian, correct: false);
      _after(wrongDelay, () {
        _resetWrong(english.id, MatchSide.english);
        _resetWrong(hungarian.id, MatchSide.hungarian);
      });
    }
  }

  void _resetWrong(String id, MatchSide side) {
    final current = _column(side).where((tile) => tile.word.id == id);
    if (current.isNotEmpty && current.first.state == TileState.wrong) {
      _setState(id, side, TileState.idle);
    }
  }

  void _remove(String id) {
    _english = [
      for (final tile in _english)
        if (tile.word.id != id) tile,
    ];
    _hungarian = [
      for (final tile in _hungarian)
        if (tile.word.id != id) tile,
    ];
    if (_english.isEmpty) {
      session.advance(_pageSize);
      _pageDone = true;
      if (!singlePage && !session.isFinished) {
        _startPage();
      }
    }
  }

  void _startPage() {
    final end = min(session.index + pairsPerPage, session.total);
    final words = session.words.sublist(session.index, end);
    _pageSize = words.length;
    _pageDone = false;
    final english = RoundSession.shuffled(words, _random);
    var hungarian = RoundSession.shuffled(words, _random);
    // Two columns in the same order would give the answers away.
    for (var tries = 0; words.length > 1 && tries < 10; tries++) {
      if (!_sameOrder(english, hungarian)) {
        break;
      }
      hungarian = RoundSession.shuffled(words, _random);
    }
    _english = [
      for (final word in english)
        MatchTile(word: word, side: MatchSide.english),
    ];
    _hungarian = [
      for (final word in hungarian)
        MatchTile(word: word, side: MatchSide.hungarian),
    ];
    session.count(RoundCounters.pages);
  }

  bool _sameOrder(List<WordPair> a, List<WordPair> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) {
        return false;
      }
    }
    return true;
  }

  void _after(Duration delay, void Function() action) {
    late final Cancel cancel;
    cancel = _schedule(delay, () {
      _pending.remove(cancel);
      if (_disposed) {
        return;
      }
      action();
      _notify();
    });
    _pending.add(cancel);
  }

  List<MatchTile> _column(MatchSide side) =>
      side == MatchSide.english ? _english : _hungarian;

  MatchSide _opposite(MatchSide side) =>
      side == MatchSide.english ? MatchSide.hungarian : MatchSide.english;

  MatchTile? _selectedIn(MatchSide side) {
    for (final tile in _column(side)) {
      if (tile.state == TileState.selected) {
        return tile;
      }
    }
    return null;
  }

  void _setState(String id, MatchSide side, TileState state) {
    final column = _column(side);
    final updated = [
      for (final tile in column)
        if (tile.word.id == id) tile.withState(state) else tile,
    ];
    if (side == MatchSide.english) {
      _english = updated;
    } else {
      _hungarian = updated;
    }
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}
