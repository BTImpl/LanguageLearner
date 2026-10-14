import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/widgets/app_progress_bar.dart';

import '../../helpers/pump_themed.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, double value, ThemeMode mode) =>
      pumpThemed(tester, AppProgressBar(value: value), mode: mode);

  for (final mode in themeModes) {
    group('${mode.name} mode', () {
      testWidgets('is 6 high and fills the given fraction', (tester) async {
        await pumpBar(tester, 0.25, mode);
        await tester.pumpAndSettle();

        final bar = tester.getSize(find.byType(AppProgressBar));
        expect(bar.height, 6);
        final fill = tester.getSize(find.byType(AnimatedFractionallySizedBox));
        expect(fill.width, closeTo(bar.width * 0.25, 0.01));
      });

      testWidgets('clamps values outside 0..1', (tester) async {
        await pumpBar(tester, 1.7, mode);
        await tester.pumpAndSettle();
        final bar = tester.getSize(find.byType(AppProgressBar));
        expect(
          tester.getSize(find.byType(AnimatedFractionallySizedBox)).width,
          bar.width,
        );

        await pumpBar(tester, -1, mode);
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(AnimatedFractionallySizedBox)).width,
          0,
        );
      });
    });
  }

  testWidgets('exposes the percentage to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBar(tester, 0.5, ThemeMode.dark);

    expect(tester.getSemantics(find.byType(AppProgressBar)).value, '50%');
    handle.dispose();
  });
}
