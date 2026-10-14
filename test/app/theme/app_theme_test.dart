import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/app/theme/theme_mode.dart';

void main() {
  const expectedByMode = <(ThemeMode, Color)>[
    (ThemeMode.dark, Color(0xFF0A1226)),
    (ThemeMode.light, Color(0xFFF2F4FB)),
  ];

  for (final (mode, background) in expectedByMode) {
    testWidgets('${mode.name} mode uses the design background', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appThemeModeProvider.overrideWithValue(mode)],
          child: const LanguageLearnerApp(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final context = tester.element(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);
      expect(Theme.of(context).scaffoldBackgroundColor, background);
      expect(context.colors.background, background);
    });
  }

  test('both themes carry the color tokens and the fonts', () {
    expect(AppTheme.dark.extension<AppColors>(), AppColors.dark);
    expect(AppTheme.light.extension<AppColors>(), AppColors.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.textTheme.bodyMedium?.fontFamily, bodyFontFamily);
    expect(
      AppTheme.dark.textTheme.headlineSmall?.fontFamily,
      headingFontFamily,
    );
    expect(AppTheme.dark.textTheme.headlineSmall?.fontWeight, FontWeight.w700);
  });
}
