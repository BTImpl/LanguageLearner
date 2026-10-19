import 'dart:async';
import 'dart:math';

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
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/features/home/home_screen.dart';
import 'package:languagelearner/features/play/flashcards/flashcards_screen.dart';
import 'package:languagelearner/features/play/matching/matching_screen.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/quiz/quiz_screen.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';

import '../../../helpers/fake_tts_service.dart';
import '../../../helpers/scripted_word_repository.dart';

Future<GoRouter> _openDirectly(
  WidgetTester tester,
  PlayMode mode,
  WordRepository repository, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = createAppRouter(initialLocation: AppRoutes.play(mode));
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        appLocaleProvider.overrideWithValue(const Locale('en')),
        roundRandomProvider.overrideWithValue(Random(1)),
        ttsServiceProvider.overrideWithValue(FakeTtsService()),
        wordRepositoryProvider.overrideWithValue(repository),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  group('a game route opened directly', () {
    testWidgets('opens when the deck has enough words', (tester) async {
      final router = await _openDirectly(
        tester,
        PlayMode.quiz,
        ScriptedWordRepository.always([testDeck(4)]),
      );

      expect(_path(router), AppRoutes.play(PlayMode.quiz));
      expect(find.byType(QuizScreen), findsOneWidget);
    });

    testWidgets('opens with a single word where one is enough', (tester) async {
      final router = await _openDirectly(
        tester,
        PlayMode.flashcards,
        ScriptedWordRepository.always([testDeck(1)]),
      );

      expect(_path(router), AppRoutes.play(PlayMode.flashcards));
      expect(find.byType(FlashcardsScreen), findsOneWidget);
    });

    final tooSmall = <(PlayMode, int)>[
      (PlayMode.quiz, 3),
      (PlayMode.matching, 1),
      (PlayMode.flashcards, 0),
      (PlayMode.typing, 0),
      (PlayMode.mix, 0),
    ];
    for (final (mode, words) in tooSmall) {
      testWidgets('${mode.name} with $words words goes home', (tester) async {
        final router = await _openDirectly(
          tester,
          mode,
          ScriptedWordRepository.always([testDeck(words)]),
        );

        expect(_path(router), AppRoutes.home);
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    }

    testWidgets('goes home when the student has no deck', (tester) async {
      final router = await _openDirectly(
        tester,
        PlayMode.matching,
        ScriptedWordRepository.always(const []),
      );

      expect(_path(router), AppRoutes.home);
      expect(find.byType(MatchingScreen), findsNothing);
    });

    testWidgets('goes home when the word list cannot be downloaded', (
      tester,
    ) async {
      final router = await _openDirectly(
        tester,
        PlayMode.quiz,
        ScriptedWordRepository(
          (_) async => throw const WordLoadException(WordLoadFailure.noNetwork),
        ),
      );

      expect(_path(router), AppRoutes.home);
      expect(find.text('No internet connection'), findsOneWidget);
    });

    testWidgets('shows a spinner until the decks arrive', (tester) async {
      final answer = Completer<List<Deck>>();
      final router = await _openDirectly(
        tester,
        PlayMode.quiz,
        ScriptedWordRepository((_) => answer.future),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(QuizScreen), findsNothing);
      expect(_path(router), AppRoutes.play(PlayMode.quiz));

      answer.complete([testDeck(12)]);
      await tester.pumpAndSettle();

      expect(find.byType(QuizScreen), findsOneWidget);
    });

    testWidgets('does not pull a running round away when the decks shrink', (
      tester,
    ) async {
      final repository = ScriptedWordRepository(
        (call) async => call == 1 ? [testDeck(12)] : [testDeck(2)],
      );
      final router = await _openDirectly(tester, PlayMode.quiz, repository);
      expect(find.byType(QuizScreen), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LanguageLearnerApp)),
      );
      container.invalidate(decksProvider);
      await tester.pumpAndSettle();

      expect(repository.gets, 2);
      expect(_path(router), AppRoutes.play(PlayMode.quiz));
      expect(find.byType(QuizScreen), findsOneWidget);
    });
  });
}
