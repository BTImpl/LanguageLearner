import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_state.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  const expectedByLocale = <(Locale, String)>[
    (Locale('en'), 'What shall we practice today?'),
    (Locale('hu'), 'Mit gyakorolunk ma?'),
  ];

  for (final (locale, headline) in expectedByLocale) {
    testWidgets('home screen is shown in ${locale.languageCode}', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocaleProvider.overrideWithValue(locale),
            initialAuthStateProvider.overrideWithValue(
              const SignedIn(testAccount),
            ),
          ],
          child: const LanguageLearnerApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LanguageLearner'), findsOneWidget);
      expect(find.text(headline), findsOneWidget);
    });
  }
}
