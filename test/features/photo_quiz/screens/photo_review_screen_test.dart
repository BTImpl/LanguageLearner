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
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/auth/account.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_providers.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';

import '../../../helpers/in_memory_key_value_store.dart';
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
  late ProviderContainer container;

  String path() => router.routerDelegate.currentConfiguration.uri.path;

  PhotoQuizState state() => container.read(photoQuizControllerProvider);

  Future<void> openReview(
    WidgetTester tester, {
    PhotoQuiz? quiz,
    Locale locale = const Locale('en'),
    Size size = const Size(390, 1800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
          accountProvider.overrideWithValue(_student),
          appLocaleProvider.overrideWithValue(locale),
          photoQuizRepositoryProvider.overrideWithValue(
            _FixedRepository(quiz ?? samplePhotoQuiz()),
          ),
        ],
        child: const LanguageLearnerApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(LanguageLearnerApp)),
    );
    unawaited(
      container
          .read(photoQuizControllerProvider.notifier)
          .start(makePhoto(dir)),
    );
    await tester.pump();
    router.go(AppRoutes.photoQuizReview);
    await tester.pumpAndSettle();
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('photo_review_');
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  // `TextButton.icon` and `FilledButton.icon` are subclasses, which
  // `find.byType` does not match.
  Finder deleteButtons() => find.ancestor(
    of: find.text('Delete'),
    matching: find.byWidgetPredicate((widget) => widget is TextButton),
  );

  testWidgets('shows the title, the count and every question', (tester) async {
    await openReview(tester);

    expect(path(), AppRoutes.photoQuizReview);
    expect(find.text('Review the quiz'), findsOneWidget);
    expect(find.text('Grammar – Worksheet 3'), findsOneWidget);
    expect(find.text('4 questions'), findsOneWidget);
    expect(find.text('She ___ to school every day.'), findsOneWidget);
    expect(find.text('London is the capital of England.'), findsOneWidget);
    expect(
      find.textContaining('After the meeting had finished'),
      findsOneWidget,
    );
    expect(find.text('I ___ my homework right now.'), findsOneWidget);
    expect(deleteButtons(), findsNWidgets(4));
  });

  testWidgets('every option is listed, whatever their number', (tester) async {
    await openReview(tester);

    // Two, three, four and five options.
    expect(find.text('a) True'), findsOneWidget);
    expect(find.text('b) False'), findsOneWidget);
    expect(find.text('c) The schedule was for last month.'), findsOneWidget);
    expect(find.text('d) gone'), findsOneWidget);
    expect(find.text('e) have done'), findsOneWidget);
  });

  testWidgets('a long question and its long options are not cut off', (
    tester,
  ) async {
    await openReview(tester);

    for (final text in [
      'After the meeting had finished, the manager asked everyone to '
          'stay behind because she wanted to talk about the new schedule '
          'for the following month. Which sentence is true?',
      'a) The manager wanted to talk to everyone after the meeting.',
    ]) {
      final widget = tester.widget<Text>(find.text(text));
      expect(widget.overflow, isNull);
      expect(widget.maxLines, isNull);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the questions keep the numbers of the worksheet', (
    tester,
  ) async {
    await openReview(tester);
    await tester.tap(deleteButtons().first);
    await tester.pumpAndSettle();

    // Question 1 is gone; 2, 3 and 4 keep their numbers.
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('without a title the general title is shown', (tester) async {
    final quiz = PhotoQuiz(questions: samplePhotoQuiz().questions);
    await openReview(tester, quiz: quiz);

    // Once in the header and once above the questions.
    expect(find.text('Quiz from a photo'), findsNWidgets(2));
  });

  testWidgets('the skipped questions are mentioned, only when there are', (
    tester,
  ) async {
    await openReview(tester, quiz: samplePhotoQuiz(skippedQuestions: 1));
    expect(find.text('1 question could not be read'), findsOneWidget);
  });

  testWidgets('no note when nothing was skipped', (tester) async {
    await openReview(tester);

    expect(find.textContaining('could not be read'), findsNothing);
  });

  testWidgets('delete removes a question and undo puts it back', (
    tester,
  ) async {
    await openReview(tester);
    final before = (state() as PhotoQuizReady).quiz;

    await tester.tap(deleteButtons().at(1));
    // Let the message slide in completely before it is tapped.
    await tester.pumpAndSettle();

    expect(find.text('London is the capital of England.'), findsNothing);
    expect(find.text('3 questions'), findsOneWidget);
    expect(deleteButtons(), findsNWidgets(3));
    expect(find.text('Question deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('London is the capital of England.'), findsOneWidget);
    expect(find.text('4 questions'), findsOneWidget);
    expect((state() as PhotoQuizReady).quiz, before);
    // Back at its place: second.
    expect(
      tester.getTopLeft(find.text('London is the capital of England.')).dy,
      greaterThan(
        tester.getTopLeft(find.text('She ___ to school every day.')).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.text('London is the capital of England.')).dy,
      lessThan(tester.getTopLeft(find.textContaining('After the meeting')).dy),
    );
  });

  testWidgets('Start is off when every question is deleted', (tester) async {
    await openReview(tester);
    Finder start() => find.ancestor(
      of: find.text('Start'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );

    expect(tester.widget<FilledButton>(start()).onPressed, isNotNull);
    for (var i = 0; i < 4; i++) {
      await tester.tap(deleteButtons().first);
      await tester.pumpAndSettle();
    }

    expect(
      find.text('No questions left. Take the photo again.'),
      findsOneWidget,
    );
    expect(find.text('0 questions'), findsOneWidget);
    expect(tester.widget<FilledButton>(start()).onPressed, isNull);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(start()).onPressed, isNotNull);
  });

  testWidgets('Start opens the fill-in screen with the kept questions', (
    tester,
  ) async {
    await openReview(tester);
    await tester.tap(deleteButtons().first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.photoQuizFill);
    expect(find.text('1 / 3'), findsOneWidget);
    expect((state() as PhotoQuizReady).quiz.questions, hasLength(3));
  });

  testWidgets('Retake photo throws the quiz away and goes to the camera', (
    tester,
  ) async {
    await openReview(tester);

    await tester.tap(find.text('Retake photo'));
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.photoQuiz);
    expect(state(), isA<PhotoQuizIdle>());
    expect(find.text('Photograph the worksheet'), findsOneWidget);
  });

  testWidgets('the back button throws the quiz away and goes home', (
    tester,
  ) async {
    await openReview(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.home);
    expect(state(), isA<PhotoQuizIdle>());
  });

  testWidgets('a message of an earlier deletion does not follow us away', (
    tester,
  ) async {
    await openReview(tester);
    await tester.tap(deleteButtons().first);
    await tester.pump();
    expect(find.text('Question deleted'), findsOneWidget);

    await tester.tap(find.text('Retake photo'));
    await tester.pumpAndSettle();

    expect(find.text('Question deleted'), findsNothing);
  });

  testWidgets('is written in Hungarian too', (tester) async {
    await openReview(tester, locale: const Locale('hu'));

    expect(find.text('Kvíz áttekintése'), findsOneWidget);
    expect(find.text('4 kérdés'), findsOneWidget);
    expect(find.text('Törlés'), findsNWidgets(4));
    expect(find.text('Újra fotózom'), findsOneWidget);
    expect(find.text('Kezdés'), findsOneWidget);
  });

  testWidgets('a large text size stacks the buttons and does not overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openReview(tester, size: const Size(390, 2400));

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Retake photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the screen without a quiz goes home', (tester) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = createAppRouter(initialLocation: AppRoutes.photoQuizReview);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
          accountProvider.overrideWithValue(_student),
        ],
        child: const LanguageLearnerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.home);
  });

  testWidgets('the buttons are labeled and big enough to tap', (tester) async {
    final handle = tester.ensureSemantics();
    await openReview(tester);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
