import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/matching/match_tile.dart';
import 'package:languagelearner/features/play/matching/matching_game.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';

import '../../../helpers/manual_scheduler.dart';

List<WordPair> _words(int count) => [
  for (var i = 0; i < count; i++)
    WordPair.fromCells(id: 'w$i', english: 'en$i', hungarian: 'hu$i'),
];

class _Setup {
  _Setup(int count, {int pairsPerPage = 5, int seed = 1}) {
    session = RoundSession(
      words: _words(count),
      promptLanguage: PromptLanguage.english,
      random: Random(seed),
    );
    game = MatchingGame(
      session: session,
      pairsPerPage: pairsPerPage,
      random: Random(seed),
      schedule: scheduler.call,
    );
  }

  final scheduler = ManualScheduler();
  late final RoundSession session;
  late final MatchingGame game;

  /// The words of the current page.
  List<WordPair> get page => [for (final tile in game.englishTiles) tile.word];

  void tap(WordPair word, MatchSide side) => game.tap(word, side);

  void pair(WordPair english, WordPair hungarian) {
    tap(english, MatchSide.english);
    tap(hungarian, MatchSide.hungarian);
  }

  /// Pairs the words of the current page correctly and lets them disappear.
  void solvePage() {
    for (final word in page) {
      pair(word, word);
    }
    scheduler.elapse(const Duration(milliseconds: 400));
  }

  TileState? stateOf(WordPair word, MatchSide side) =>
      game.tile(word, side)?.state;
}

const _eng = MatchSide.english;
const _hun = MatchSide.hungarian;

void main() {
  group('pages', () {
    test('12 words in pages of 5 are 5 + 5 + 2', () {
      final s = _Setup(12);
      final sizes = <int>[];

      expect(s.game.pageCount, 3);
      while (!s.game.isFinished) {
        sizes.add(s.page.length);
        s.solvePage();
      }

      expect(sizes, [5, 5, 2]);
    });

    test('every word is on exactly one page', () {
      final s = _Setup(12);
      final seen = <String>[];

      while (!s.game.isFinished) {
        seen.addAll(s.page.map((word) => word.id));
        s.solvePage();
      }

      expect(seen, hasLength(12));
      expect(seen.toSet(), hasLength(12));
    });

    test('the two columns have the same words in a different order', () {
      final s = _Setup(5);
      final english = s.game.englishTiles.map((tile) => tile.word.id).toList();
      final hungarian = s.game.hungarianTiles
          .map((tile) => tile.word.id)
          .toList();

      expect([...english]..sort(), [...hungarian]..sort());
      expect(english, isNot(hungarian));
    });

    test('a page size larger than the deck gives one page', () {
      final s = _Setup(3, pairsPerPage: 8);

      expect(s.game.pageCount, 1);
      expect(s.page, hasLength(3));
    });

    test('an empty deck is finished at once', () {
      final s = _Setup(0);

      expect(s.game.isFinished, isTrue);
      expect(s.game.englishTiles, isEmpty);
    });

    test('counts the pages in the result', () {
      final s = _Setup(12);

      while (!s.game.isFinished) {
        s.solvePage();
      }

      expect(s.game.result.extra(RoundCounters.pages), 3);
    });
  });

  group('selecting', () {
    test('a tap selects, a second tap on it deselects', () {
      final s = _Setup(5);
      final word = s.page.first;

      s.tap(word, _eng);
      expect(s.stateOf(word, _eng), TileState.selected);

      s.tap(word, _eng);
      expect(s.stateOf(word, _eng), TileState.idle);
    });

    test('tapping another tile of the column moves the selection', () {
      final s = _Setup(5);
      final [a, b, ...] = s.page;

      s.tap(a, _eng);
      s.tap(b, _eng);

      expect(s.stateOf(a, _eng), TileState.idle);
      expect(s.stateOf(b, _eng), TileState.selected);
    });

    test('one selected tile in each column forms a pair at once', () {
      final s = _Setup(5);
      final [a, b, ...] = s.page;

      s.tap(a, _eng);
      s.tap(b, _hun);

      expect(s.stateOf(a, _eng), TileState.wrong);
      expect(s.stateOf(b, _hun), TileState.wrong);
    });

    test('a tap on a word that is not on the page does nothing', () {
      final s = _Setup(12);
      final other = s.session.words.last;

      s.tap(other, _eng);

      expect(s.game.tile(other, _eng), isNull);
      expect(s.game.englishTiles.every((t) => t.state == TileState.idle), true);
    });
  });

  group('a correct pair', () {
    test('turns matched and disappears after 400 ms', () {
      final s = _Setup(5);
      final word = s.page.first;

      s.pair(word, word);

      expect(s.stateOf(word, _eng), TileState.matched);
      expect(s.stateOf(word, _hun), TileState.matched);

      s.scheduler.elapse(const Duration(milliseconds: 399));
      expect(s.game.tile(word, _eng), isNotNull);

      s.scheduler.elapse(const Duration(milliseconds: 1));
      expect(s.game.tile(word, _eng), isNull);
      expect(s.game.tile(word, _hun), isNull);
      expect(s.page, hasLength(4));
    });

    test('matched tiles ignore taps', () {
      final s = _Setup(5);
      final word = s.page.first;
      s.pair(word, word);

      s.tap(word, _eng);

      expect(s.stateOf(word, _eng), TileState.matched);
    });
  });

  group('a wrong pair', () {
    test('turns wrong and returns to normal after 1 second', () {
      final s = _Setup(5);
      final [a, b, ...] = s.page;

      s.pair(a, b);

      expect(s.stateOf(a, _eng), TileState.wrong);
      expect(s.stateOf(b, _hun), TileState.wrong);

      s.scheduler.elapse(const Duration(milliseconds: 999));
      expect(s.stateOf(a, _eng), TileState.wrong);

      s.scheduler.elapse(const Duration(milliseconds: 1));
      expect(s.stateOf(a, _eng), TileState.idle);
      expect(s.stateOf(b, _hun), TileState.idle);
    });

    test('wrong tiles ignore taps, the other tiles stay tappable', () {
      final s = _Setup(5);
      final [a, b, c, ...] = s.page;
      s.pair(a, b);

      s.tap(a, _eng);
      expect(s.stateOf(a, _eng), TileState.wrong);

      s.pair(c, c);
      expect(s.stateOf(c, _eng), TileState.matched);
      expect(s.stateOf(a, _eng), TileState.wrong);
    });

    test('counts the wrong pairs', () {
      final s = _Setup(5);
      final [a, b, ...] = s.page;

      s.pair(a, b);
      s.scheduler.elapse(const Duration(seconds: 1));
      s.pair(b, a);

      expect(s.game.result.extra(RoundCounters.wrongPairs), 2);
    });
  });

  group('the result', () {
    test('a word is first try unless it was in a wrong pair', () {
      final s = _Setup(5);
      final [a, b, c, d, e] = s.page;

      s.pair(a, b); // a and b are wrong
      s.scheduler.elapse(const Duration(seconds: 1));
      for (final word in [a, b, c, d, e]) {
        s.pair(word, word);
      }
      s.scheduler.elapse(const Duration(milliseconds: 400));
      final result = s.game.result;

      expect(s.game.isFinished, isTrue);
      expect(result.total, 5);
      expect(result.wrongFirst, 2);
      expect(
        result.missedWords.map((w) => w.id),
        unorderedEquals([a.id, b.id]),
      );
      expect(result.firstTry, 3);
    });

    test('a page ends only when its last pair is gone', () {
      final s = _Setup(7);
      final firstPage = s.page;

      for (final word in firstPage.take(4)) {
        s.pair(word, word);
      }
      s.scheduler.elapse(const Duration(milliseconds: 400));
      expect(s.game.pageIndex, 0);
      expect(s.page, hasLength(1));

      s.pair(firstPage.last, firstPage.last);
      s.scheduler.elapse(const Duration(milliseconds: 400));
      expect(s.game.pageIndex, 1);
      expect(s.page, hasLength(2));
    });
  });

  group('listeners and dispose', () {
    test('listeners hear about taps and about scheduled changes', () {
      final s = _Setup(5);
      var calls = 0;
      s.game.addListener(() => calls++);
      final word = s.page.first;

      s.pair(word, word);
      final afterTaps = calls;
      s.scheduler.elapse(const Duration(milliseconds: 400));

      expect(afterTaps, 2);
      expect(calls, 3);
    });

    test('dispose cancels the pending actions', () {
      final s = _Setup(5);
      final word = s.page.first;
      s.pair(word, word);
      expect(s.scheduler.pending, 1);

      s.game.dispose();

      expect(s.scheduler.pending, 0);
    });
  });

  group('single page', () {
    test('stops after its page, the session moves on by the page size', () {
      final s = _Setup(0);
      final session = RoundSession(
        words: _words(8),
        promptLanguage: PromptLanguage.english,
        random: Random(1),
      );
      final game = MatchingGame(
        session: session,
        pairsPerPage: 3,
        singlePage: true,
        random: Random(1),
        schedule: s.scheduler.call,
      );
      expect(game.pageDone, isFalse);
      final words = [for (final tile in game.englishTiles) tile.word];
      expect(words, hasLength(3));

      for (final word in words) {
        game
          ..tap(word, MatchSide.english)
          ..tap(word, MatchSide.hungarian);
      }
      s.scheduler.elapse(const Duration(milliseconds: 400));

      expect(game.pageDone, isTrue);
      expect(game.englishTiles, isEmpty);
      expect(session.index, 3);
      expect(session.isFinished, isFalse);
      expect(session.result.firstTry, 3);
    });

    test('a smaller rest makes a smaller page', () {
      final s = _Setup(0);
      final session = RoundSession(
        words: _words(2),
        promptLanguage: PromptLanguage.english,
        random: Random(1),
      );
      final game = MatchingGame(
        session: session,
        pairsPerPage: 3,
        singlePage: true,
        random: Random(1),
        schedule: s.scheduler.call,
      );

      expect(game.englishTiles, hasLength(2));
    });

    test('pages that follow each other are the default', () {
      final s = _Setup(7, pairsPerPage: 3);

      expect(s.game.singlePage, isFalse);
      s.solvePage();
      expect(s.game.pageDone, isFalse);
      expect(s.game.englishTiles, hasLength(3));
    });
  });
}
