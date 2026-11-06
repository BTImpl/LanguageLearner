import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/features/play/flashcards/widgets/flashcard_face.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  Future<double> sizeOf(
    WidgetTester tester,
    String text,
    PromptLanguage language,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpThemed(
      tester,
      Padding(
        padding: const EdgeInsets.all(20),
        child: FlashcardFace(language: language, text: text),
      ),
      asScreen: true,
    );
    return tester.widget<Text>(find.text(text)).style!.fontSize!;
  }

  for (final language in PromptLanguage.values) {
    testWidgets('a short word keeps the full size ($language)', (tester) async {
      expect(await sizeOf(tester, 'cat', language), 46);
    });

    testWidgets('a long word is smaller, but not below 24 ($language)', (
      tester,
    ) async {
      final size = await sizeOf(tester, 'megvalósíthatatlanság', language);

      expect(size, lessThan(46));
      expect(size, greaterThanOrEqualTo(24));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a phrase of short words keeps the full size ($language)', (
      tester,
    ) async {
      expect(await sizeOf(tester, 'to be or not to be', language), 46);
    });
  }

  group('long texts and the example sentence', () {
    const longText =
        'to be or not to be that is the question whether it is nobler in the '
        'mind to suffer the slings and arrows of outrageous fortune or to take '
        'arms against a sea of troubles';
    const example = 'The flight has a two-hour delay because of the storm.';

    Future<void> pumpFace(
      WidgetTester tester,
      PromptLanguage language, {
      String text = 'delay',
      String? withExample = example,
      Size size = const Size(390, 600),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpThemed(
        tester,
        Padding(
          padding: const EdgeInsets.all(20),
          child: FlashcardFace(
            language: language,
            text: text,
            example: withExample,
          ),
        ),
        asScreen: true,
      );
    }

    testWidgets('the English side shows the example sentence', (tester) async {
      await pumpFace(tester, PromptLanguage.english);

      expect(find.text('delay'), findsOneWidget);
      expect(find.text(example), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Hungarian side does not show it', (tester) async {
      await pumpFace(tester, PromptLanguage.hungarian);

      expect(find.text(example), findsNothing);
    });

    testWidgets('no example, no example text', (tester) async {
      await pumpFace(tester, PromptLanguage.english, withExample: null);

      expect(find.text(example), findsNothing);
    });

    for (final language in PromptLanguage.values) {
      testWidgets('a long text is smaller and fits the card ($language)', (
        tester,
      ) async {
        await pumpFace(tester, language, text: longText);

        final finder = find.text(longText);
        expect(tester.widget<Text>(finder).style!.fontSize, lessThan(46));
        expect(tester.takeException(), isNull);
        final card = tester.getRect(find.byType(FlashcardFace));
        final text = tester.getRect(finder);
        expect(text.top, greaterThanOrEqualTo(card.top));
        expect(text.bottom, lessThanOrEqualTo(card.bottom));
      });
    }

    testWidgets('a long text and a long example both fit', (tester) async {
      await pumpFace(
        tester,
        PromptLanguage.english,
        text: longText,
        withExample: '$example $example $example',
        size: const Size(360, 640),
      );

      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(FlashcardFace));
      for (final text in [longText, '$example $example $example']) {
        final rect = tester.getRect(find.text(text));
        expect(rect.top, greaterThanOrEqualTo(card.top));
        expect(rect.bottom, lessThanOrEqualTo(card.bottom));
      }
    });
  });
}
