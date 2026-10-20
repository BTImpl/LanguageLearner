import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/data/fake_word_repository.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/widgets/choice_tile.dart';
import 'package:languagelearner/features/play/matching/match_tile.dart';
import 'package:languagelearner/features/play/matching/matching_content.dart';
import 'package:languagelearner/features/play/matching/matching_screen.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_screen.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';

/// One deck with long, multi-word texts.
class _LongWordsRepository implements WordRepository {
  @override
  Future<void> clearLocal() async {}

  static final words = [
    WordPair.fromCells(
      id: 'long-1',
      english: 'a connecting flight',
      hungarian: 'csatlakozó járat átszállással a következő városba',
    ),
    WordPair.fromCells(id: 'long-2', english: 'gate', hungarian: 'kapu'),
    WordPair.fromCells(id: 'long-3', english: 'seat', hungarian: 'ülés'),
  ];

  @override
  Future<List<Deck>> getDecks() async => [
    Deck(id: 'long', name: 'Long', updatedAt: DateTime.utc(2026), words: words),
  ];

  @override
  Future<void> refresh() async {}
}

class _Harness {
  _Harness(this.router, this.words);

  final GoRouter router;

  /// The words in the order of the round; page 1 is the first ones.
  final List<WordPair> words;

  String get path => router.routerDelegate.currentConfiguration.uri.path;
}

Future<_Harness> _open(
  WidgetTester tester, {
  int pairsPerPage = 5,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 1000),
  WordRepository? repository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final deck = (await (repository ?? FakeWordRepository()).getDecks()).first;
  final words = RoundSession.shuffled(deck.words, Random(1));
  final router = createAppRouter();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        appLocaleProvider.overrideWithValue(locale),
        roundRandomProvider.overrideWithValue(Random(1)),
        if (repository != null)
          wordRepositoryProvider.overrideWithValue(repository),
        initialSettingsProvider.overrideWithValue(
          AppSettings(pairsPerPage: pairsPerPage),
        ),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  router.go(AppRoutes.play(PlayMode.matching));
  await tester.pumpAndSettle();
  return _Harness(router, words);
}

Finder _tile(WordPair word, MatchSide side) =>
    find.byKey(matchTileKey(word, side));

ChoiceState _state(WidgetTester tester, WordPair word, MatchSide side) =>
    tester.widget<ChoiceTile>(_tile(word, side)).state;

Future<void> _tap(WidgetTester tester, WordPair word, MatchSide side) async {
  await tester.tap(_tile(word, side));
  await tester.pump();
}

Future<void> _pair(
  WidgetTester tester,
  WordPair english,
  WordPair hungarian,
) async {
  await _tap(tester, english, MatchSide.english);
  await _tap(tester, hungarian, MatchSide.hungarian);
}

/// Pairs the given words correctly and waits until they are gone.
Future<void> _solve(WidgetTester tester, Iterable<WordPair> words) async {
  for (final word in words) {
    await _pair(tester, word, word);
  }
  // Timers do not schedule frames, so let the time pass explicitly.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

const _eng = MatchSide.english;
const _hun = MatchSide.hungarian;

void main() {
  testWidgets('shows the first page with two columns and the counters', (
    tester,
  ) async {
    final h = await _open(tester);

    expect(find.byType(MatchingScreen), findsOneWidget);
    expect(find.text('Matching'), findsOneWidget);
    expect(find.text('Page 1 of 3'), findsOneWidget);
    expect(find.text('Find the pair'), findsOneWidget);
    expect(find.text('0 / 12'), findsOneWidget);
    expect(find.text('pairs found'), findsOneWidget);
    expect(find.text('wrong attempts'), findsOneWidget);
    for (final word in h.words.take(5)) {
      expect(_tile(word, _eng), findsOneWidget);
      expect(_tile(word, _hun), findsOneWidget);
    }
    expect(_tile(h.words[5], _eng), findsNothing);
  });

  testWidgets('a tap selects a tile, a second tap deselects it', (
    tester,
  ) async {
    final h = await _open(tester);
    final word = h.words.first;

    await _tap(tester, word, _eng);
    expect(_state(tester, word, _eng), ChoiceState.selected);

    await _tap(tester, word, _eng);
    expect(_state(tester, word, _eng), ChoiceState.idle);
  });

  testWidgets('a correct pair turns green and fades away', (tester) async {
    final h = await _open(tester);
    final word = h.words.first;
    final other = h.words[1];

    await _pair(tester, word, word);

    expect(_state(tester, word, _eng), ChoiceState.correct);
    expect(_state(tester, word, _hun), ChoiceState.correct);
    expect(find.text('1 / 12'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(_tile(word, _eng), findsNothing);
    expect(_tile(word, _hun), findsNothing);
    // The others are still there and did not move to another place.
    expect(_state(tester, other, _eng), ChoiceState.idle);
    expect(find.text('1 / 12'), findsOneWidget);
  });

  testWidgets('the other tiles keep their place when a pair is gone', (
    tester,
  ) async {
    final h = await _open(tester);
    final other = h.words[1];
    final before = tester.getTopLeft(_tile(other, _eng));

    await _solve(tester, [h.words.first]);

    expect(tester.getTopLeft(_tile(other, _eng)), before);
  });

  testWidgets('a wrong pair turns red for a second, then back to normal', (
    tester,
  ) async {
    final h = await _open(tester);
    final a = h.words[0];
    final b = h.words[1];

    await _pair(tester, a, b);

    expect(_state(tester, a, _eng), ChoiceState.wrong);
    expect(_state(tester, b, _hun), ChoiceState.wrong);
    expect(find.text('1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    expect(_state(tester, a, _eng), ChoiceState.wrong);

    await tester.pump(const Duration(milliseconds: 200));
    expect(_state(tester, a, _eng), ChoiceState.idle);
    expect(_state(tester, b, _hun), ChoiceState.idle);
  });

  testWidgets('a wrong tile ignores taps, the others can be paired', (
    tester,
  ) async {
    final h = await _open(tester);
    final [a, b, c, ...] = h.words;
    await _pair(tester, a, b);

    await tester.tap(_tile(a, _eng), warnIfMissed: false);
    await tester.pump();
    expect(_state(tester, a, _eng), ChoiceState.wrong);

    await _pair(tester, c, c);
    expect(_state(tester, c, _eng), ChoiceState.correct);
  });

  testWidgets('the next page comes when the page is solved', (tester) async {
    final h = await _open(tester);

    await _solve(tester, h.words.take(5));

    expect(find.text('Page 2 of 3'), findsOneWidget);
    expect(find.text('5 / 12'), findsOneWidget);
    for (final word in h.words.skip(5).take(5)) {
      expect(_tile(word, _eng), findsOneWidget);
    }
    expect(_tile(h.words.first, _eng), findsNothing);
  });

  testWidgets('the summary lists the words of a wrong pair', (tester) async {
    final h = await _open(tester);
    final a = h.words[0];
    final b = h.words[1];

    await _pair(tester, a, b);
    await tester.pump(const Duration(seconds: 1));
    await _solve(tester, h.words.take(5));
    await _solve(tester, h.words.skip(5).take(5));
    await _solve(tester, h.words.skip(10));

    expect(h.path, AppRoutes.summary(PlayMode.matching));
    expect(find.byType(RoundSummaryScreen), findsOneWidget);
    expect(find.text('All 12 pairs found'), findsOneWidget);
    expect(find.text('Matching, Utazás'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Worth another look'), findsOneWidget);
    expect(find.text(a.english), findsOneWidget);
    expect(find.text(b.english), findsOneWidget);

    await tester.tap(find.text('Restart Matching'));
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.play(PlayMode.matching));
    expect(find.text('Page 1 of 3'), findsOneWidget);
  });

  testWidgets('the pairs per page follow the setting, 8 pairs scroll', (
    tester,
  ) async {
    final h = await _open(tester, pairsPerPage: 8, size: const Size(360, 640));

    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final last = h.words[7];
    await tester.scrollUntilVisible(
      _tile(last, _eng),
      100,
      scrollable: find.byType(Scrollable).first,
    );

    expect(_tile(last, _eng), findsOneWidget);
  });

  testWidgets('long texts wrap to several lines inside their tile', (
    tester,
  ) async {
    final h = await _open(
      tester,
      pairsPerPage: 3,
      // Narrow like a small phone, tall enough that wrapped tiles stay on
      // screen and can be tapped.
      size: const Size(320, 1400),
      repository: _LongWordsRepository(),
    );
    final long = _LongWordsRepository.words.first;
    final short = _LongWordsRepository.words[1];

    expect(tester.takeException(), isNull);
    final longTile = tester.getRect(_tile(long, _hun));
    final shortTile = tester.getRect(_tile(short, _hun));
    expect(longTile.height, greaterThan(shortTile.height));
    // Inside the screen with its 20 px margin, not wider than its column.
    expect(longTile.right, lessThanOrEqualTo(320 - 20));
    expect(longTile.width, shortTile.width);

    await _pair(tester, long, long);
    expect(_state(tester, long, _hun), ChoiceState.correct);
    expect(h.words, hasLength(3));
  });

  group('stable row height', () {
    // The two columns are shuffled on their own, so a row holds an English and
    // a Hungarian tile of two different words.
    List<Rect> rows(WidgetTester tester) => [
      for (final row
          in find
              .descendant(
                of: find.byType(MatchingContent),
                matching: find.byType(IntrinsicHeight),
              )
              .evaluate())
        tester.getRect(find.byWidget(row.widget)),
    ];

    Future<_Harness> openLong(WidgetTester tester) => _open(
      tester,
      pairsPerPage: 3,
      size: const Size(320, 1400),
      repository: _LongWordsRepository(),
    );

    testWidgets('both tiles of a row fill the height of the row', (
      tester,
    ) async {
      await openLong(tester);

      final rowRects = rows(tester);
      expect(rowRects, hasLength(3));
      // The long Hungarian text makes one row clearly taller than the rest.
      expect(rowRects.map((r) => r.height).reduce(max), greaterThan(100));
      final tiles = find.descendant(
        of: find.byType(MatchingContent),
        matching: find.byWidgetPredicate((w) => w is ChoiceTile),
      );
      expect(tiles, findsNWidgets(6));
      for (final tile in tiles.evaluate()) {
        final rect = tester.getRect(find.byWidget(tile.widget));
        final row = rowRects.singleWhere((r) => r.contains(rect.center));
        expect(rect.top, row.top);
        expect(rect.height, row.height);
      }
    });

    testWidgets('rows keep their place when pairs are gone', (tester) async {
      final h = await openLong(tester);
      final before = rows(tester);

      // Each pair empties a place in two different rows, so some rows have
      // only one tile left, and others none.
      await _solve(tester, [h.words.first]);
      expect(rows(tester), before);
      await _solve(tester, [h.words[1]]);
      expect(rows(tester), before);
    });

    testWidgets('selected and wrong states do not change the rows', (
      tester,
    ) async {
      final h = await openLong(tester);
      final long = _LongWordsRepository.words.first;
      final short = _LongWordsRepository.words[1];
      final before = rows(tester);

      await _tap(tester, long, _eng);
      expect(rows(tester), before);
      await _tap(tester, short, _hun);
      expect(_state(tester, long, _eng), ChoiceState.wrong);
      expect(rows(tester), before);
      expect(h.words, hasLength(3));
    });

    testWidgets('stays stable at a large text scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      // The frame around the game (header, bottom bar) does not fit this scale
      // on a narrow screen yet; only the rows are of interest here.
      final onError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        onError?.call(details);
      };
      addTearDown(() => FlutterError.onError = onError);

      final h = await _open(
        tester,
        pairsPerPage: 3,
        size: const Size(320, 3000),
        repository: _LongWordsRepository(),
      );
      final before = rows(tester);
      expect(before, hasLength(3));

      await _solve(tester, [h.words.first]);

      expect(rows(tester), before);
    });
  });

  testWidgets('has Hungarian texts', (tester) async {
    await _open(tester, locale: const Locale('hu'));

    expect(find.text('Párosító'), findsOneWidget);
    expect(find.text('1 / 3. oldal'), findsOneWidget);
    expect(find.text('Keresd meg a párját'), findsOneWidget);
    expect(find.text('pár megvan'), findsOneWidget);
    expect(find.text('hibás próbálkozás'), findsOneWidget);
  });

  testWidgets('meets the tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('leaving before any progress needs no confirmation', (
    tester,
  ) async {
    final h = await _open(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Leave the round?'), findsNothing);
    expect(h.path, AppRoutes.home);
  });

  testWidgets('leaving a round with progress asks first', (tester) async {
    final h = await _open(tester);
    await _solve(tester, [h.words.first]);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Leave the round?'), findsOneWidget);
    expect(h.path, AppRoutes.play(PlayMode.matching));

    await tester.tap(find.text('Keep playing'));
    await tester.pumpAndSettle();
    expect(h.path, AppRoutes.play(PlayMode.matching));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(h.path, AppRoutes.home);
  });
}
