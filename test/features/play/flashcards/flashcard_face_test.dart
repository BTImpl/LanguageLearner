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
}
