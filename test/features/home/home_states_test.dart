import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/features/home/widgets/deck_card.dart';

import '../../helpers/fake_tts_service.dart';
import '../../helpers/scripted_word_repository.dart';

class _Home {
  _Home(this.router);

  final GoRouter router;

  String get path => router.routerDelegate.currentConfiguration.uri.path;
}

Future<_Home> _openHome(
  WidgetTester tester,
  WordRepository repository, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        appLocaleProvider.overrideWithValue(locale),
        ttsServiceProvider.overrideWithValue(FakeTtsService()),
        wordRepositoryProvider.overrideWithValue(repository),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return _Home(router);
}

WordLoadException _failure(WordLoadFailure failure) =>
    WordLoadException(failure);

void main() {
  group('the word list could not be downloaded', () {
    final cases = <(WordLoadFailure, String, String)>[
      (
        WordLoadFailure.noNetwork,
        'No internet connection',
        'The first download of the word list needs internet.',
      ),
      (
        WordLoadFailure.timeout,
        'No internet connection',
        'The first download of the word list needs internet.',
      ),
      (
        WordLoadFailure.sheetUnavailable,
        'The word list is not available right now',
        'Please try again a little later.',
      ),
      (
        WordLoadFailure.serverError,
        'Could not download the word list',
        'Something went wrong. Please try again.',
      ),
    ];
    for (final (failure, title, message) in cases) {
      testWidgets('${failure.name} is explained, without the modes', (
        tester,
      ) async {
        await _openHome(
          tester,
          ScriptedWordRepository((_) async => throw _failure(failure)),
        );

        expect(find.text(title), findsOneWidget);
        expect(find.text(message), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.byType(DeckCard), findsNothing);
        expect(find.text('Mix'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }

    testWidgets('Try again downloads the word list again', (tester) async {
      final repository = ScriptedWordRepository(
        (call) async => call == 1
            ? throw _failure(WordLoadFailure.noNetwork)
            : [testDeck(12)],
      );
      await _openHome(tester, repository);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(repository.gets, 2);
      expect(find.byType(DeckCard), findsOneWidget);
      expect(find.text('Mix'), findsOneWidget);
      expect(find.text('No internet connection'), findsNothing);
    });

    testWidgets('Try again can fail again', (tester) async {
      final repository = ScriptedWordRepository(
        (_) async => throw _failure(WordLoadFailure.noNetwork),
      );
      await _openHome(tester, repository);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(repository.gets, 2);
      expect(find.text('No internet connection'), findsOneWidget);
    });

    testWidgets('is explained in Hungarian', (tester) async {
      await _openHome(
        tester,
        ScriptedWordRepository(
          (_) async => throw _failure(WordLoadFailure.noNetwork),
        ),
        locale: const Locale('hu'),
      );

      expect(find.text('Nincs internetkapcsolat'), findsOneWidget);
      expect(
        find.text('A szólista első letöltéséhez netre van szükség.'),
        findsOneWidget,
      );
      expect(find.text('Újra'), findsOneWidget);
    });
  });

  group('the student has no deck', () {
    testWidgets('is asked to ask the teacher and refresh', (tester) async {
      await _openHome(tester, ScriptedWordRepository.always(const []));

      expect(find.text('No word list yet'), findsOneWidget);
      expect(find.text('Ask your teacher, then refresh.'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.byType(DeckCard), findsNothing);
      expect(find.text('Mix'), findsNothing);
    });

    testWidgets('Refresh brings the decks the teacher added', (tester) async {
      var added = false;
      final repository = ScriptedWordRepository(
        (_) async => added ? [testDeck(12)] : const [],
        onRefresh: () async => added = true,
      );
      await _openHome(tester, repository);

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      expect(repository.refreshes, 1);
      expect(find.byType(DeckCard), findsOneWidget);
      expect(find.text('No word list yet'), findsNothing);
    });

    testWidgets('a failed Refresh says so and keeps the message', (
      tester,
    ) async {
      final repository = ScriptedWordRepository(
        (_) async => const [],
        onRefresh: () async => throw _failure(WordLoadFailure.noNetwork),
      );
      await _openHome(tester, repository);

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not refresh. You still see the earlier word list.'),
        findsOneWidget,
      );
      expect(find.text('No word list yet'), findsOneWidget);
    });

    testWidgets('is shown in Hungarian', (tester) async {
      await _openHome(
        tester,
        ScriptedWordRepository.always(const []),
        locale: const Locale('hu'),
      );

      expect(find.text('Még nincs szólistád'), findsOneWidget);
      expect(find.text('Szólj a tanárodnak, aztán frissíts.'), findsOneWidget);
      expect(find.text('Frissítés'), findsOneWidget);
    });
  });

  group('a deck that is too small for some modes', () {
    testWidgets('an empty deck disables every mode', (tester) async {
      final home = await _openHome(
        tester,
        ScriptedWordRepository.always([testDeck(0)]),
      );

      expect(find.text('This deck has no words'), findsOneWidget);
      expect(find.text('At least 1 word needed'), findsNWidgets(3));
      expect(find.text('At least 2 words needed'), findsOneWidget);
      expect(find.text('At least 4 words needed'), findsOneWidget);

      for (final title in ['Mix', 'Flashcards', 'Matching', 'Quiz']) {
        await tester.tap(find.text(title).first);
        await tester.pumpAndSettle();
        expect(home.path, AppRoutes.home, reason: '$title is disabled');
      }
    });

    testWidgets('a single word disables Matching and Quiz', (tester) async {
      final home = await _openHome(
        tester,
        ScriptedWordRepository.always([testDeck(1)]),
      );

      expect(find.text('At least 1 word needed'), findsNothing);
      expect(find.text('At least 2 words needed'), findsOneWidget);
      expect(find.text('At least 4 words needed'), findsOneWidget);

      await tester.tap(find.text('Matching'));
      await tester.pumpAndSettle();
      expect(home.path, AppRoutes.home);

      await tester.tap(find.text('Mix'));
      await tester.pumpAndSettle();
      expect(home.path, '/play/mix');
    });

    testWidgets('three words disable only the Quiz', (tester) async {
      final home = await _openHome(
        tester,
        ScriptedWordRepository.always([testDeck(3)]),
      );

      expect(find.text('At least 4 words needed'), findsOneWidget);
      expect(find.text('At least 2 words needed'), findsNothing);

      await tester.tap(find.text('Quiz'));
      await tester.pumpAndSettle();
      expect(home.path, AppRoutes.home);

      await tester.tap(find.text('Matching'));
      await tester.pumpAndSettle();
      expect(home.path, '/play/matching');
    });

    testWidgets('four words enable everything', (tester) async {
      await _openHome(tester, ScriptedWordRepository.always([testDeck(4)]));

      expect(find.textContaining('needed'), findsNothing);
    });

    testWidgets('the requirement is shown in Hungarian', (tester) async {
      await _openHome(
        tester,
        ScriptedWordRepository.always([testDeck(3)]),
        locale: const Locale('hu'),
      );

      expect(find.text('Legalább 4 szó kell'), findsOneWidget);
    });
  });

  testWidgets('a deck without words says so on its card', (tester) async {
    await _openHome(
      tester,
      ScriptedWordRepository.always([testDeck(0, name: 'Empty')]),
    );

    final card = find.byType(DeckCard);
    expect(
      find.descendant(of: card, matching: find.text('Empty')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('This deck has no words')),
      findsOneWidget,
    );
    expect(find.text('Not practiced yet'), findsNothing);
  });

  testWidgets('keeps showing the decks while they are refreshed', (
    tester,
  ) async {
    final repository = ScriptedWordRepository.always([testDeck(12)]);
    await _openHome(tester, repository);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LanguageLearnerApp)),
    );
    container.invalidate(decksProvider);
    await tester.pump();

    expect(find.byType(DeckCard), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
