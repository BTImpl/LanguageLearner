import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';

void main() {
  const expectedByLocale = <(Locale, String)>[
    (Locale('en'), 'No words'),
    (Locale('hu'), 'Nincs szó'),
  ];

  for (final (locale, wordCountText) in expectedByLocale) {
    testWidgets('home screen is shown in ${locale.languageCode}', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appLocaleProvider.overrideWithValue(locale)],
          child: const LanguageLearnerApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LanguageLearner'), findsOneWidget);
      expect(find.text(wordCountText), findsOneWidget);
    });
  }
}
