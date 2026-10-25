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
import 'package:languagelearner/core/services/system_settings_opener.dart';
import 'package:languagelearner/features/auth/account.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_exception.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_providers.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_engine.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_providers.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_source.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_quiz_failure_view.dart';

import '../../../helpers/fake_system_settings_opener.dart';
import '../../../helpers/in_memory_key_value_store.dart';
import '../../../helpers/photo_quiz_fakes.dart';

const _student = Account(name: 'Kiss Anna', email: 'kiss.anna@example.com');

void main() {
  late Directory dir;
  late ScriptedPhotoQuizRepository repository;
  late FakeSystemSettingsOpener opener;
  late GoRouter router;
  late FakePhotoSource source;

  String path() => router.routerDelegate.currentConfiguration.uri.path;

  Future<void> open(
    WidgetTester tester,
    List<PhotoPickResult> picks, {
    String location = AppRoutes.home,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    source = FakePhotoSource(picks);
    router = createAppRouter(initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
          accountProvider.overrideWithValue(_student),
          appLocaleProvider.overrideWithValue(locale),
          photoSourceProvider.overrideWithValue(source),
          photoQuizRepositoryProvider.overrideWithValue(repository),
          systemSettingsOpenerProvider.overrideWithValue(opener),
        ],
        child: const LanguageLearnerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('photo_quiz_flow_');
    repository = ScriptedPhotoQuizRepository();
    opener = FakeSystemSettingsOpener();
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  testWidgets('the home screen has the entry that opens the capture screen', (
    tester,
  ) async {
    await open(tester, []);

    expect(find.text('Quiz from a photo'), findsOneWidget);
    expect(find.text('Photograph a worksheet'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);

    await tester.ensureVisible(find.text('Quiz from a photo'));
    await tester.tap(find.text('Quiz from a photo'));
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.photoQuiz);
    expect(find.text('Photograph the worksheet'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from the gallery'), findsOneWidget);
  });

  testWidgets('the capture screen is written in Hungarian too', (tester) async {
    await open(
      tester,
      [],
      location: AppRoutes.photoQuiz,
      locale: const Locale('hu'),
    );

    expect(find.text('Fotózd le a feladatlapot'), findsOneWidget);
    expect(find.text('Fotó készítése'), findsOneWidget);
    expect(find.text('Választás a galériából'), findsOneWidget);
  });

  testWidgets('a photo goes to the processing screen and then to the review', (
    tester,
  ) async {
    final photo = makePhoto(dir);
    await open(tester, [PhotoPicked(photo)], location: AppRoutes.photoQuiz);

    await tester.tap(find.text('Take a photo'));
    await tester.pump();
    await tester.pump();

    expect(path(), AppRoutes.photoQuizProcessing);
    expect(find.text('Reading the worksheet…'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(repository.requests, [photo]);

    repository.succeed();
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.photoQuizReview);
    expect(find.text('4 questions'), findsOneWidget);
    expect(photo.existsSync(), isFalse);
  });

  testWidgets('the buttons ask for the camera and for the gallery', (
    tester,
  ) async {
    await open(tester, [
      const PhotoPickCancelled(),
      const PhotoPickCancelled(),
    ], location: AppRoutes.photoQuiz);

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from the gallery'));
    await tester.pumpAndSettle();

    expect(source.asked, [PhotoOrigin.camera, PhotoOrigin.gallery]);
  });

  testWidgets('cancelling the camera changes nothing', (tester) async {
    await open(tester, [
      const PhotoPickCancelled(),
    ], location: AppRoutes.photoQuiz);

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.photoQuiz);
    expect(repository.requests, isEmpty);
  });

  testWidgets('a refused permission is explained and the settings open', (
    tester,
  ) async {
    await open(tester, [
      const PhotoPickPermissionDenied(PhotoOrigin.camera),
    ], location: AppRoutes.photoQuiz);

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(find.text('No access to the camera'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pump();
    expect(opener.opened, 1);
    expect(path(), AppRoutes.photoQuiz);
  });

  testWidgets('a missing camera and an unusable photo are explained', (
    tester,
  ) async {
    await open(tester, [
      const PhotoPickCameraUnavailable(),
      const PhotoPickUnusable(),
    ], location: AppRoutes.photoQuiz);

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no camera to use'), findsOneWidget);

    await tester.tap(find.text('Choose from the gallery'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cannot be read'), findsOneWidget);
    expect(find.textContaining('no camera to use'), findsNothing);
  });

  testWidgets('cancelling while the photo is read goes home and cleans up', (
    tester,
  ) async {
    final photo = makePhoto(dir);
    await open(tester, [PhotoPicked(photo)], location: AppRoutes.photoQuiz);
    await tester.tap(find.text('Take a photo'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.home);
    expect(photo.existsSync(), isFalse);
    repository.succeed(); // a late answer changes nothing
    await tester.pumpAndSettle();
    expect(path(), AppRoutes.home);
  });

  testWidgets('a failure is explained and a new photo starts again', (
    tester,
  ) async {
    final photo = makePhoto(dir);
    await open(tester, [PhotoPicked(photo)], location: AppRoutes.photoQuiz);
    await tester.tap(find.text('Take a photo'));
    await tester.pump();
    await tester.pump();

    repository.fail(const PhotoQuizException(PhotoQuizFailure.noQuestions));
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.photoQuizProcessing);
    expect(find.text('No questions found'), findsOneWidget);
    expect(find.textContaining('Try again in better light'), findsOneWidget);
    expect(photo.existsSync(), isFalse);

    await tester.tap(find.text('New photo'));
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.photoQuiz);
  });

  for (final failure in PhotoQuizFailure.values) {
    testWidgets('the failure ${failure.name} is explained', (tester) async {
      final photo = makePhoto(dir);
      await open(tester, [PhotoPicked(photo)], location: AppRoutes.photoQuiz);
      await tester.tap(find.text('Take a photo'));
      await tester.pump();
      await tester.pump();

      repository.fail(PhotoQuizException(failure));
      await tester.pumpAndSettle();

      expect(find.byKey(photoFailurePrimaryKey), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  }

  testWidgets('no network: try again sends the same photo once more', (
    tester,
  ) async {
    final photo = makePhoto(dir);
    await open(tester, [PhotoPicked(photo)], location: AppRoutes.photoQuiz);
    await tester.tap(find.text('Take a photo'));
    await tester.pump();
    await tester.pump();
    repository.fail(const PhotoQuizException(PhotoQuizFailure.noNetwork));
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(photo.existsSync(), isTrue);

    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(repository.requests, [photo, photo]);
    expect(find.text('Reading the worksheet…'), findsOneWidget);

    repository.succeed();
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.photoQuizReview);
    expect(photo.existsSync(), isFalse);
  });

  testWidgets('no network: cancel goes home and drops the photo', (
    tester,
  ) async {
    final photo = makePhoto(dir);
    await open(tester, [PhotoPicked(photo)], location: AppRoutes.photoQuiz);
    await tester.tap(find.text('Take a photo'));
    await tester.pump();
    await tester.pump();
    repository.fail(const PhotoQuizException(PhotoQuizFailure.noNetwork));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(path(), AppRoutes.home);
    expect(photo.existsSync(), isFalse);
  });

  testWidgets('the processing screen without a request goes home', (
    tester,
  ) async {
    await open(tester, [], location: AppRoutes.photoQuizProcessing);

    expect(path(), AppRoutes.home);
  });

  testWidgets('the review screen without a quiz goes home', (tester) async {
    await open(tester, [], location: AppRoutes.photoQuizReview);

    expect(path(), AppRoutes.home);
  });

  testWidgets('the buttons are labeled and big enough to tap', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, [], location: AppRoutes.photoQuiz);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
