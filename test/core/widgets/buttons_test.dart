import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';

import '../../helpers/pump_themed.dart';

void main() {
  for (final mode in themeModes) {
    group('${mode.name} mode', () {
      testWidgets('PrimaryButton is 56 high and uses the primary color', (
        tester,
      ) async {
        var taps = 0;
        await pumpThemed(
          tester,
          PrimaryButton(
            label: 'Start',
            icon: Icons.play_arrow,
            onPressed: () => taps++,
          ),
          mode: mode,
        );

        expect(tester.getSize(find.byType(PrimaryButton)).height, 56);
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        final context = tester.element(find.byType(PrimaryButton));
        expect(
          button.style?.backgroundColor?.resolve({}),
          context.colors.primary,
        );
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        await tester.tap(find.text('Start'));
        expect(taps, 1);
      });

      testWidgets('PrimaryButton is disabled without a callback', (
        tester,
      ) async {
        await pumpThemed(
          tester,
          const PrimaryButton(label: 'Start', onPressed: null),
          mode: mode,
        );

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.enabled, isFalse);
      });

      testWidgets('SecondaryButton is 56 high and tappable', (tester) async {
        var taps = 0;
        await pumpThemed(
          tester,
          SecondaryButton(label: 'Skip', onPressed: () => taps++),
          mode: mode,
        );

        expect(tester.getSize(find.byType(SecondaryButton)).height, 56);
        await tester.tap(find.text('Skip'));
        expect(taps, 1);
      });

      testWidgets('compact SecondaryButton is 44 high and hugs its text', (
        tester,
      ) async {
        await pumpThemed(
          tester,
          Align(
            alignment: Alignment.topLeft,
            child: SecondaryButton(
              label: 'Sign out',
              compact: true,
              onPressed: () {},
            ),
          ),
          mode: mode,
        );

        final size = tester.getSize(find.byType(SecondaryButton));
        expect(size.height, 44);
        expect(size.width, lessThan(200));
      });

      testWidgets('IconSquareButton is 44 x 44 and has a label', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        var taps = 0;
        await pumpThemed(
          tester,
          Align(
            alignment: Alignment.topLeft,
            child: IconSquareButton(
              icon: Icons.refresh,
              semanticLabel: 'Refresh',
              onPressed: () => taps++,
            ),
          ),
          mode: mode,
        );

        expect(
          tester.getSize(find.byType(IconSquareButton)),
          const Size.square(44),
        );
        // IconButton reports its label to screen readers as the tooltip.
        final node = tester.getSemantics(find.byType(IconSquareButton));
        expect('${node.label} ${node.tooltip}', contains('Refresh'));
        await tester.tap(find.byType(IconSquareButton));
        expect(taps, 1);
        handle.dispose();
      });

      testWidgets('buttons meet the tap target and label guidelines', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpThemed(
          tester,
          Column(
            children: [
              PrimaryButton(label: 'Start', onPressed: () {}),
              const SizedBox(height: 8),
              SecondaryButton(label: 'Skip', onPressed: () {}),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: IconSquareButton(
                  icon: Icons.close,
                  semanticLabel: 'Close',
                  onPressed: () {},
                ),
              ),
            ],
          ),
          mode: mode,
        );

        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    });
  }
}
