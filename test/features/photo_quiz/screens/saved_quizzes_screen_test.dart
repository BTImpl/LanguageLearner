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
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/auth/account.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/photo_quiz/data/fake_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_providers.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/saved/quiz_fingerprint.dart';
import 'package:languagelearner/features/photo_quiz/saved/saved_quiz.dart';
import 'package:languagelearner/features/photo_quiz/saved/saved_quiz_store.dart';
import 'package:languagelearner/features/photo_quiz/screens/photo_fill_screen.dart';
import 'package:languagelearner/features/photo_quiz/screens/saved_quizzes_screen.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';

import '../../../helpers/in_memory_key_value_store.dart';
import '../../../helpers/photo_quiz_fakes.dart';

const _student = Account(name: 'Kiss Anna', email: 'kiss.anna@example.com');

final _t0 = DateTime.utc(2026, 10, 1, 10);
final _now = DateTime.utc(2026, 10, 24, 18);

PhotoQuiz _sample() => samplePhotoQuiz();

/// A second quiz without a title, so that it is told apart from the sample.
PhotoQuiz _untitled() =>
    PhotoQuiz(questions: samplePhotoQuiz().questions.sublist(2));

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
  late InMemoryKeyValueStore storage;
  late KeyValueSavedQuizStore store;

  String path() => router.routerDelegate.currentConfiguration.uri.path;

  Future<void> open(
    WidgetTester tester,
    String location, {
    Locale locale = const Locale('en'),
    PhotoQuiz? quiz,
  }) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = createAppRouter(initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
          keyValueStoreProvider.overrideWithValue(storage),
          accountProvider.overrideWithValue(_student),
          appLocaleProvider.overrideWithValue(locale),
          clockProvider.overrideWithValue(() => _now),
          photoQuizRepositoryProvider.overrideWithValue(
            _FixedRepository(quiz ?? _sample()),
          ),
        ],
        child: const LanguageLearnerApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(LanguageLearnerApp)),
    );
  }

  /// Opens the review screen with [quiz] as the ready quiz.
  Future<void> openReview(WidgetTester tester, PhotoQuiz quiz) async {
    await open(tester, AppRoutes.home, quiz: quiz);
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
    dir = Directory.systemTemp.createTempSync('saved_quizzes_');
    addTearDown(() => dir.deleteSync(recursive: true));
    storage = InMemoryKeyValueStore();
    store = KeyValueSavedQuizStore(storage);
  });

  group('recording at Start', () {
    // The scripted repository answers with the sample quiz.
    testWidgets('the quiz appears among the saved ones after Start', (
      tester,
    ) async {
      await openReview(tester, _sample());

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(path(), AppRoutes.photoQuizFill);
      final entries = await store.list(_student.email);
      expect(entries, hasLength(1));
      expect(entries.single.quiz, _sample());
      expect(entries.single.fillCount, 1);
      expect(find.textContaining('already saved'), findsNothing);
    });

    testWidgets('only the kept questions are saved', (tester) async {
      await openReview(tester, _sample());
      await tester.tap(
        find
            .ancestor(
              of: find.text('Delete').first,
              matching: find.byWidgetPredicate((w) => w is TextButton),
            )
            .first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      final entries = await store.list(_student.email);
      expect(entries.single.quiz.questions, hasLength(3));
    });

    testWidgets('reading the same quiz again does not add a second one', (
      tester,
    ) async {
      await store.record(_student.email, _sample(), _t0);
      await openReview(tester, _sample());

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You have already saved this quiz, so I am using the saved one.',
        ),
        findsOneWidget,
      );
      final entries = await store.list(_student.email);
      expect(entries, hasLength(1));
      expect(entries.single.createdAt, _t0);
      expect(entries.single.lastUsedAt, _now);
      expect(entries.single.fillCount, 2);
    });

    testWidgets('a student does not meet the quizzes of another one', (
      tester,
    ) async {
      await store.record('nagy.bela@example.com', _sample(), _t0);
      await openReview(tester, _sample());

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(find.textContaining('already saved'), findsNothing);
      expect(await store.list(_student.email), hasLength(1));
      expect(await store.list('nagy.bela@example.com'), hasLength(1));
    });
  });

  group('the saved quizzes screen', () {
    testWidgets('the capture screen opens it', (tester) async {
      await open(tester, AppRoutes.photoQuiz);

      await tester.tap(find.byTooltip('Saved quizzes'));
      await tester.pumpAndSettle();

      expect(path(), AppRoutes.photoQuizSaved);
    });

    testWidgets('lists the quizzes, the last used first', (tester) async {
      await store.record(_student.email, _sample(), _t0);
      await store.record(
        _student.email,
        _untitled(),
        _t0.add(const Duration(days: 1)),
      );
      await store.markUsed(
        _student.email,
        quizFingerprint(_sample()),
        _t0.add(const Duration(days: 2)),
      );
      await store.markUsed(
        _student.email,
        quizFingerprint(_sample()),
        _t0.add(const Duration(days: 3)),
      );

      await open(tester, AppRoutes.photoQuizSaved);

      expect(find.text('Saved quizzes'), findsOneWidget);
      final first = tester.getTopLeft(find.text('Grammar – Worksheet 3'));
      final second = tester.getTopLeft(find.text('Quiz from a photo'));
      expect(first.dy, lessThan(second.dy));
      expect(find.textContaining('4 questions'), findsOneWidget);
      expect(find.textContaining('2 questions'), findsOneWidget);
      expect(find.textContaining('Filled 3 times'), findsOneWidget);
      expect(find.textContaining('Filled once'), findsOneWidget);
    });

    testWidgets('a tap starts the quiz again, without answers', (tester) async {
      await store.record(_student.email, _sample(), _t0);
      await open(tester, AppRoutes.photoQuizSaved);

      await tester.tap(find.text('Grammar – Worksheet 3'));
      await tester.pumpAndSettle();

      expect(path(), AppRoutes.photoQuizFill);
      expect(find.text('1 / 4'), findsOneWidget);
      expect(find.text('She ___ to school every day.'), findsOneWidget);
      final entry = (await store.list(_student.email)).single;
      expect(entry.fillCount, 2);
      expect(entry.lastUsedAt, _now);
    });

    testWidgets('filling it in again twice starts empty both times', (
      tester,
    ) async {
      await store.record(_student.email, _sample(), _t0);
      await open(tester, AppRoutes.photoQuizSaved);
      await tester.tap(find.text('Grammar – Worksheet 3'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(photoOptionKey(0)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(path(), AppRoutes.photoQuizSaved);

      await tester.tap(find.text('Grammar – Worksheet 3'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 4'), findsOneWidget);
      final fill = container.read(photoQuizControllerProvider);
      expect(fill, isA<PhotoQuizReady>());
      expect((fill as PhotoQuizReady).fromSaved, isTrue);
    });

    testWidgets('leaving the quiz goes back to the list, not the review', (
      tester,
    ) async {
      await store.record(_student.email, _sample(), _t0);
      await open(tester, AppRoutes.photoQuizSaved);
      await tester.tap(find.text('Grammar – Worksheet 3'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(path(), AppRoutes.photoQuizSaved);
      expect(find.text('Grammar – Worksheet 3'), findsOneWidget);
    });

    testWidgets('delete removes the quiz and Undo puts it back', (
      tester,
    ) async {
      await store.record(_student.email, _sample(), _t0);
      await store.record(
        _student.email,
        _untitled(),
        _t0.add(const Duration(days: 1)),
      );
      await open(tester, AppRoutes.photoQuizSaved);

      await tester.tap(
        find.byKey(savedQuizDeleteKey(quizFingerprint(_untitled()))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quiz from a photo'), findsNothing);
      expect(find.text('Grammar – Worksheet 3'), findsOneWidget);
      expect(find.text('Quiz deleted'), findsOneWidget);
      expect(await store.list(_student.email), hasLength(1));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Quiz from a photo'), findsOneWidget);
      expect(await store.list(_student.email), hasLength(2));
    });

    testWidgets('the empty list explains itself and offers the photo', (
      tester,
    ) async {
      await open(tester, AppRoutes.photoQuizSaved);

      expect(find.text('No saved quizzes yet'), findsOneWidget);

      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();

      expect(path(), AppRoutes.photoQuiz);
    });

    testWidgets('the back button goes to the capture screen', (tester) async {
      await open(tester, AppRoutes.photoQuizSaved);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(path(), AppRoutes.photoQuiz);
    });

    testWidgets('works in Hungarian too', (tester) async {
      await store.record(_student.email, _sample(), _t0);
      await open(tester, AppRoutes.photoQuizSaved, locale: const Locale('hu'));

      expect(find.text('Mentett kvízek'), findsOneWidget);
      expect(find.textContaining('4 kérdés'), findsOneWidget);
      expect(find.textContaining('1× kitöltve'), findsOneWidget);
    });
  });

  test('SavedQuiz survives its JSON', () {
    final entry = SavedQuiz(
      id: quizFingerprint(_sample()),
      quiz: _sample(),
      createdAt: _t0,
      lastUsedAt: _now,
      fillCount: 3,
    );

    expect(SavedQuiz.fromJson(entry.toJson()), entry);
  });

  test('SavedQuiz.fromJson names a missing field', () {
    expect(
      () => SavedQuiz.fromJson({'id': 'x'}),
      throwsA(isA<FormatException>()),
    );
  });
}
