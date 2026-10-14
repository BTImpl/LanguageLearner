import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/core/widgets/segmented_toggle.dart';

import '../../helpers/pump_themed.dart';

const _options = [
  SegmentOption(value: 'a', label: 'Alpha'),
  SegmentOption(value: 'b', label: 'Beta', icon: Icons.dark_mode_outlined),
  SegmentOption(value: 'c', label: 'Gamma'),
];

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  for (final mode in themeModes) {
    group('${mode.name} mode', () {
      testWidgets('the selected choice is filled and bold', (tester) async {
        await pumpThemed(
          tester,
          SegmentedToggle<String>(
            options: _options,
            selected: 'b',
            onChanged: (_) {},
          ),
          mode: mode,
        );

        final c = tester.element(find.byType(SegmentedToggle<String>)).colors;
        expect(_labelColor(tester, 'Beta'), c.background);
        expect(
          tester.widget<Text>(find.text('Beta')).style?.fontWeight,
          FontWeight.w700,
        );
        expect(_labelColor(tester, 'Alpha'), c.textMuted);
        expect(_labelColor(tester, 'Gamma'), c.textMuted);
        expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      });

      testWidgets('tapping a choice reports its value', (tester) async {
        final picked = <String>[];
        await pumpThemed(
          tester,
          SegmentedToggle<String>(
            options: _options,
            selected: 'a',
            onChanged: picked.add,
          ),
          mode: mode,
        );

        await tester.tap(find.text('Gamma'));
        await tester.tap(find.text('Beta'));

        expect(picked, ['c', 'b']);
      });
    });
  }

  testWidgets('the choices are labeled and big enough to tap', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpThemed(
      tester,
      SegmentedToggle<String>(
        options: _options,
        selected: 'a',
        onChanged: (_) {},
      ),
    );

    expect(find.bySemanticsLabel('Alpha'), findsOneWidget);
    expect(find.bySemanticsLabel('Beta'), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
