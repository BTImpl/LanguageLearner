import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_exception.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_quiz_failure_view.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  var newPhoto = 0;
  var home = 0;
  var retry = 0;

  setUp(() {
    newPhoto = 0;
    home = 0;
    retry = 0;
  });

  Future<void> pumpView(
    WidgetTester tester,
    PhotoQuizFailure failure, {
    bool canRetry = false,
    DateTime? resetsAt,
    int? limit,
    Locale locale = const Locale('en'),
    ThemeMode mode = ThemeMode.dark,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: PhotoQuizFailureView(
                failure: failure,
                canRetry: canRetry,
                resetsAt: resetsAt,
                limit: limit,
                onNewPhoto: () => newPhoto++,
                onHome: () => home++,
                onRetry: () => retry++,
              ),
            ),
          ),
        ),
      ),
      asScreen: true,
      locale: locale,
      mode: mode,
    );
  }

  Future<void> tapPrimary(WidgetTester tester) async {
    await tester.tap(find.byKey(photoFailurePrimaryKey));
    await tester.pump();
  }

  Future<void> tapSecondary(WidgetTester tester) async {
    await tester.tap(find.byKey(photoFailureSecondaryKey));
    await tester.pump();
  }

  group('no question found', () {
    testWidgets('says so, with a new photo and a way back', (tester) async {
      await pumpView(tester, PhotoQuizFailure.noQuestions);

      expect(find.text('No questions found'), findsOneWidget);
      expect(find.textContaining('Try again in better light'), findsOneWidget);
      expect(find.text('New photo'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      await tapPrimary(tester);
      await tapSecondary(tester);
      expect(newPhoto, 1);
      expect(home, 1);
      expect(retry, 0);
    });
  });

  group('a photo that cannot be used', () {
    for (final failure in [
      PhotoQuizFailure.imageTooLarge,
      PhotoQuizFailure.imageUnsupported,
    ]) {
      testWidgets('${failure.name}: one general text, a new photo', (
        tester,
      ) async {
        await pumpView(tester, failure);

        expect(find.text("I can't process this photo"), findsOneWidget);
        expect(find.text('New photo'), findsOneWidget);
        expect(find.byKey(photoFailureSecondaryKey), findsNothing);

        await tapPrimary(tester);
        expect(newPhoto, 1);
      });
    }

    testWidgets('the explanations differ', (tester) async {
      await pumpView(tester, PhotoQuizFailure.imageTooLarge);
      expect(find.textContaining('too large'), findsOneWidget);

      await pumpView(tester, PhotoQuizFailure.imageUnsupported);
      expect(find.textContaining('JPEG or PNG'), findsOneWidget);
    });
  });

  group('failures that may pass', () {
    testWidgets('no network: try again with the same photo, or cancel', (
      tester,
    ) async {
      await pumpView(tester, PhotoQuizFailure.noNetwork, canRetry: true);

      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.textContaining('Your photo is kept'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tapPrimary(tester);
      await tapSecondary(tester);
      expect(retry, 1);
      expect(home, 1);
      expect(newPhoto, 0);
    });

    testWidgets('timeout: try again', (tester) async {
      await pumpView(tester, PhotoQuizFailure.timeout, canRetry: true);

      expect(find.text('It took too long'), findsOneWidget);
      await tapPrimary(tester);
      expect(retry, 1);
    });

    testWidgets('service not available: try again', (tester) async {
      await pumpView(
        tester,
        PhotoQuizFailure.serviceUnavailable,
        canRetry: true,
      );

      expect(find.text('The quiz could not be made'), findsOneWidget);
      expect(find.textContaining('not available right now'), findsOneWidget);
      await tapPrimary(tester);
      expect(retry, 1);
    });

    testWidgets('without the photo it offers a new one instead', (
      tester,
    ) async {
      await pumpView(tester, PhotoQuizFailure.noNetwork);

      expect(find.text('Try again'), findsNothing);
      expect(find.text('New photo'), findsOneWidget);
      await tapPrimary(tester);
      expect(newPhoto, 1);
      expect(retry, 0);
    });
  });

  group('the daily limit', () {
    testWidgets('names the limit and shows it used up', (tester) async {
      await pumpView(tester, PhotoQuizFailure.dailyLimit, limit: 20);

      expect(find.text('No quizzes left for today'), findsOneWidget);
      expect(
        find.text(
          'You can make up to 20 quizzes a day from photos. '
          'Try again tomorrow.',
        ),
        findsOneWidget,
      );
      expect(find.text('20 / 20 used today'), findsOneWidget);
      expect(find.text('Back to home'), findsOneWidget);
      expect(find.byKey(photoFailureSecondaryKey), findsNothing);

      await tapPrimary(tester);
      expect(home, 1);
    });

    testWidgets('says when it starts again, in local time', (tester) async {
      final resetsAt = DateTime.utc(2026, 10, 25, 22, 30);
      await pumpView(
        tester,
        PhotoQuizFailure.dailyLimit,
        limit: 20,
        resetsAt: resetsAt,
      );

      expect(
        find.text('Available again: ${formatLocalTime(resetsAt)}'),
        findsOneWidget,
      );
    });

    testWidgets('without the numbers it still says it, and shows no bar', (
      tester,
    ) async {
      await pumpView(tester, PhotoQuizFailure.dailyLimit);

      expect(find.text('No quizzes left for today'), findsOneWidget);
      expect(
        find.text("You've used up today's quizzes. Try again tomorrow."),
        findsOneWidget,
      );
      expect(find.textContaining('used today'), findsNothing);
      expect(find.textContaining('Available again'), findsNothing);
    });
  });

  group('other failures', () {
    for (final failure in [
      PhotoQuizFailure.serverError,
      PhotoQuizFailure.unauthorized,
      PhotoQuizFailure.studentNotFound,
    ]) {
      testWidgets('${failure.name}: general text and a new photo', (
        tester,
      ) async {
        await pumpView(tester, failure);

        expect(find.text('The quiz could not be made'), findsOneWidget);
        expect(find.text('Something went wrong. Try again.'), findsOneWidget);
        await tapPrimary(tester);
        expect(newPhoto, 1);
      });
    }
  });

  testWidgets('speaks Hungarian', (tester) async {
    await pumpView(
      tester,
      PhotoQuizFailure.noNetwork,
      canRetry: true,
      locale: const Locale('hu'),
    );

    expect(find.text('Nincs internetkapcsolat'), findsOneWidget);
    expect(find.text('Újrapróbálom'), findsOneWidget);
    expect(find.text('Mégse'), findsOneWidget);

    await pumpView(
      tester,
      PhotoQuizFailure.dailyLimit,
      limit: 20,
      locale: const Locale('hu'),
    );
    expect(find.text('Mára elfogytak a kvízek'), findsOneWidget);
    expect(find.text('20 / 20 felhasználva ma'), findsOneWidget);
    expect(find.text('Vissza a kezdőlapra'), findsOneWidget);
  });

  group('every failure fits', () {
    for (final mode in themeModes) {
      for (final failure in PhotoQuizFailure.values) {
        testWidgets('${failure.name} in ${mode.name} with large text', (
          tester,
        ) async {
          await pumpView(
            tester,
            failure,
            canRetry: true,
            limit: 20,
            resetsAt: DateTime.utc(2026, 10, 25),
            mode: mode,
            size: const Size(320, 568),
            textScale: 2,
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(photoFailurePrimaryKey), findsOneWidget);
        });
      }
    }
  });

  test('formats the local time with the date', () {
    expect(
      formatLocalTime(DateTime.utc(2026, 10, 25, 1, 5)),
      matches(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$')),
    );
  });
}
