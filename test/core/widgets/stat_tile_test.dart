import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';

import '../../helpers/pump_themed.dart';

void main() {
  for (final mode in themeModes) {
    group('${mode.name} mode', () {
      testWidgets('shows the number and the caption', (tester) async {
        await pumpThemed(
          tester,
          const StatTile(value: '5', label: 'correct first time'),
          mode: mode,
        );

        expect(find.text('5'), findsOneWidget);
        expect(find.text('correct first time'), findsOneWidget);
        final number = tester.widget<Text>(find.text('5'));
        expect(number.style?.fontFamily, headingFontFamily);
        expect(number.style?.fontSize, 26);
      });

      testWidgets('colors the number by tone', (tester) async {
        final expected = <StatTone, Color Function(AppColors)>{
          StatTone.neutral: (c) => c.text,
          StatTone.success: (c) => c.successNumber,
          StatTone.error: (c) => c.errorNumber,
        };
        for (final MapEntry(key: tone, value: color) in expected.entries) {
          await pumpThemed(
            tester,
            StatTile(value: '2', label: 'x', tone: tone),
            mode: mode,
          );
          final context = tester.element(find.byType(StatTile));
          expect(
            tester.widget<Text>(find.text('2')).style?.color,
            color(context.colors),
            reason: tone.name,
          );
        }
      });
    });
  }

  testWidgets('is read as one phrase by screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpThemed(
      tester,
      const StatTile(value: '5', label: 'correct first time'),
    );

    expect(find.bySemanticsLabel('correct first time: 5'), findsOneWidget);
    handle.dispose();
  });
}
