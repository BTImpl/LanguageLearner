import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/widgets/choice_tile.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/auth/account.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_providers.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/screens/photo_fill_screen.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_fill_summary.dart';

import '../../../helpers/photo_quiz_fakes.dart';

const _student = Account(name: 'Kiss Anna', email: 'kiss.anna@example.com');

/// Answers every photo with the same quiz.
class _FixedRepository implements PhotoQuizRepository {
  _FixedRepository(this.quiz);

  final PhotoQuiz quiz;

  @override
  Future<PhotoQuiz> createFromImage(File image) async => quiz;
}

void main() {
  late Directory dir;
  late GoRouter router;

  String path() => router.routerDelegate.currentConfiguration.uri.path;

  Future<void> openFill(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
          accountProvider.overrideWithValue(_student),
          appLocaleProvider.overrideWithValue(locale),
          photoQuizRepositoryProvider.overrideWithValue(
            _FixedRepository(samplePhotoQuiz()),
          ),
        ],
        child: const LanguageLearnerApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LanguageLearnerApp)),
    );
    unawaited(
      container
          .read(photoQuizControllerProvider.notifier)
          .start(makePhoto(dir)),
    );
    await tester.pump();
    router.go(AppRoutes.photoQuizFill);
    await tester.pumpAndSettle();
  }

  ChoiceState optionState(WidgetTester tester, int index) =>
      tester.widget<ChoiceTile>(find.byKey(photoOptionKey(index))).state;

  Future<void> tapOption(WidgetTester tester, int index) async {
    await tester.tap(find.byKey(photoOptionKey(index)));
    await tester.pump();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.byKey(photoNextKey));
    await tester.pumpAndSettle();
  }

  Future<void> tapPrevious(WidgetTester tester) async {
    await tester.tap(find.byKey(photoPreviousKey));
    await tester.pumpAndSettle();
  }

  /// Goes to the last question.
  Future<void> toLast(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tapNext(tester);
    }
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('photo_fill_');
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  group('a question', () {
    testWidgets('shows the title, the counter, the text and the options', (
      tester,
    ) async {
      await openFill(tester);

      expect(path(), AppRoutes.photoQuizFill);
      expect(find.text('Grammar – Worksheet 3'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('She ___ to school every day.'), findsOneWidget);
      for (final option in ['a) go', 'b) goes', 'c) going', 'd) gone']) {
        expect(find.text(option), findsOneWidget);
      }
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('has no read-aloud button', (tester) async {
      await openFill(tester);

      expect(find.byIcon(Icons.volume_up), findsNothing);
    });

    testWidgets('nothing is chosen at the start', (tester) async {
      await openFill(tester);

      for (var i = 0; i < 4; i++) {
        expect(optionState(tester, i), ChoiceState.idle);
      }
    });
  });

  group('choosing', () {
    testWidgets('the chosen option is highlighted', (tester) async {
      await openFill(tester);

      await tapOption(tester, 1);

      expect(optionState(tester, 1), ChoiceState.selected);
      expect(optionState(tester, 0), ChoiceState.idle);
    });

    testWidgets('the choice can be changed', (tester) async {
      await openFill(tester);

      await tapOption(tester, 1);
      await tapOption(tester, 3);

      expect(optionState(tester, 3), ChoiceState.selected);
      expect(optionState(tester, 1), ChoiceState.idle);
    });

    testWidgets('tapping the chosen option again clears it', (tester) async {
      await openFill(tester);

      await tapOption(tester, 2);
      await tapOption(tester, 2);

      expect(optionState(tester, 2), ChoiceState.idle);
    });

    testWidgets('is never right or wrong: no green and no red state', (
      tester,
    ) async {
      await openFill(tester);

      for (var i = 0; i < 4; i++) {
        await tapOption(tester, i);
        for (var j = 0; j < 4; j++) {
          expect(
            optionState(tester, j),
            anyOf(ChoiceState.idle, ChoiceState.selected),
          );
        }
      }
    });
  });

  group('stepping', () {
    testWidgets('next and previous move one question and keep the choice', (
      tester,
    ) async {
      await openFill(tester);
      await tapOption(tester, 2);

      await tapNext(tester);
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('London is the capital of England.'), findsOneWidget);
      expect(find.byKey(photoOptionKey(2)), findsNothing); // two options
      expect(optionState(tester, 0), ChoiceState.idle);

      await tapPrevious(tester);
      expect(find.text('1 / 4'), findsOneWidget);
      expect(optionState(tester, 2), ChoiceState.selected);
    });

    testWidgets('previous is off on the first question', (tester) async {
      await openFill(tester);

      final button = tester.widget<SecondaryButton>(
        find.byKey(photoPreviousKey),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('the last question offers the summary and not "Next"', (
      tester,
    ) async {
      await openFill(tester);

      await toLast(tester);

      expect(find.text('4 / 4'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      expect(find.text('I ___ my homework right now.'), findsOneWidget);
      expect(find.text('e) have done'), findsOneWidget);
    });

    testWidgets('a long question can be read to the end', (tester) async {
      await openFill(tester);

      await tapNext(tester);
      await tapNext(tester);

      expect(
        find.textContaining('After the meeting had finished'),
        findsOneWidget,
      );
      expect(find.text('c) The schedule was for last month.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the summary', () {
    testWidgets('lists every question with its answer', (tester) async {
      await openFill(tester);
      await tapOption(tester, 1); // 1: goes
      await toLast(tester);
      await tapOption(tester, 4); // 4: have done
      await tapNext(tester);

      expect(find.text('Summary'), findsNothing);
      expect(find.text('2 / 4 answered'), findsOneWidget);
      expect(find.text('1. She ___ to school every day.'), findsOneWidget);
      expect(find.text('b) goes'), findsOneWidget);
      expect(find.text('4. I ___ my homework right now.'), findsOneWidget);
      expect(find.text('e) have done'), findsOneWidget);
    });

    testWidgets('marks the questions without an answer', (tester) async {
      await openFill(tester);
      await tapOption(tester, 0);
      await toLast(tester);
      await tapNext(tester);

      expect(find.text('1 / 4 answered'), findsOneWidget);
      expect(find.text('no answer'), findsNWidgets(3));
      expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(3));
    });

    testWidgets('has no warning when everything is answered', (tester) async {
      await openFill(tester);
      await tapOption(tester, 0);
      for (var i = 0; i < 3; i++) {
        await tapNext(tester);
        await tapOption(tester, 0);
      }
      await tapNext(tester);

      expect(find.text('4 / 4 answered'), findsOneWidget);
      expect(find.text('no answer'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('tapping a question opens it with its choice', (tester) async {
      await openFill(tester);
      await tapNext(tester);
      await tapOption(tester, 1); // 2: False
      await tapNext(tester);
      await tapNext(tester);
      await tapNext(tester); // the summary

      await tester.tap(find.byKey(photoSummaryRowKey(1)));
      await tester.pumpAndSettle();

      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('London is the capital of England.'), findsOneWidget);
      expect(optionState(tester, 1), ChoiceState.selected);
    });

    testWidgets('an answer changed from the summary shows there', (
      tester,
    ) async {
      await openFill(tester);
      await toLast(tester);
      await tapNext(tester);
      expect(find.text('0 / 4 answered'), findsOneWidget);

      await tester.tap(find.byKey(photoSummaryRowKey(0)));
      await tester.pumpAndSettle();
      await tapOption(tester, 2);
      await toLast(tester);
      await tapNext(tester);

      expect(find.text('1 / 4 answered'), findsOneWidget);
      expect(find.text('c) going'), findsOneWidget);
    });

    testWidgets('the send button is there, and off until the sending exists', (
      tester,
    ) async {
      await openFill(tester);
      await toLast(tester);
      await tapNext(tester);

      expect(find.text('Send to teacher'), findsOneWidget);
      final button = tester.widget<PrimaryButton>(find.byKey(photoSubmitKey));
      expect(button.onPressed, isNull);
    });
  });

  group('leaving', () {
    testWidgets('asks first and stays when the student keeps filling', (
      tester,
    ) async {
      await openFill(tester);
      await tapOption(tester, 1);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Leave the quiz?'), findsOneWidget);
      expect(find.text('Your answers are not saved.'), findsOneWidget);

      await tester.tap(find.text('Keep playing'));
      await tester.pumpAndSettle();

      expect(path(), AppRoutes.photoQuizFill);
      expect(optionState(tester, 1), ChoiceState.selected);
    });

    testWidgets('goes back to the review after the confirmation', (
      tester,
    ) async {
      await openFill(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(path(), AppRoutes.photoQuizReview);
    });

    testWidgets('the answers are gone when the quiz is filled in again', (
      tester,
    ) async {
      await openFill(tester);
      await tapOption(tester, 1);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      router.go(AppRoutes.photoQuizFill);
      await tester.pumpAndSettle();

      expect(find.text('1 / 4'), findsOneWidget);
      expect(optionState(tester, 1), ChoiceState.idle);
    });

    testWidgets('the summary asks too', (tester) async {
      await openFill(tester);
      await toLast(tester);
      await tapNext(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Leave the quiz?'), findsOneWidget);
    });
  });

  testWidgets('without a ready quiz it goes to the home screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = createAppRouter(initialLocation: AppRoutes.photoQuizFill);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
          accountProvider.overrideWithValue(_student),
          appLocaleProvider.overrideWithValue(const Locale('en')),
        ],
        child: const LanguageLearnerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.home);
  });

  testWidgets('speaks Hungarian', (tester) async {
    await openFill(tester, locale: const Locale('hu'));

    expect(find.text('1. kérdés'), findsOneWidget);
    expect(find.text('Következő'), findsOneWidget);
    expect(find.text('Előző'), findsOneWidget);

    await toLast(tester);
    expect(find.text('Összegzés'), findsOneWidget);
    await tapNext(tester);

    expect(find.text('0 / 4 megválaszolva'), findsOneWidget);
    expect(find.text('nincs válasz'), findsNWidgets(4));
    expect(find.text('Beküldés a tanárnak'), findsOneWidget);
  });
}
