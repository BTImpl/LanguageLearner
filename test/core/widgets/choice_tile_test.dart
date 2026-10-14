import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/core/widgets/choice_tile.dart';

import '../../helpers/pump_themed.dart';

Material _surface(WidgetTester tester) =>
    tester.widget<Material>(find.byKey(ChoiceTile.surfaceKey));

BorderSide _side(WidgetTester tester) =>
    (_surface(tester).shape! as RoundedRectangleBorder).side;

void main() {
  for (final mode in themeModes) {
    group('${mode.name} mode', () {
      testWidgets('idle: surface color, line border, no icon', (tester) async {
        await pumpThemed(tester, const ChoiceTile(label: 'kapu'), mode: mode);

        final c = tester.element(find.byType(ChoiceTile)).colors;
        expect(_surface(tester).color, c.surface);
        expect(_side(tester).color, c.line);
        expect(find.byType(Icon), findsNothing);
      });

      testWidgets('selected: raised surface, highlight border', (tester) async {
        await pumpThemed(
          tester,
          const ChoiceTile(label: 'kapu', state: ChoiceState.selected),
          mode: mode,
        );

        final c = tester.element(find.byType(ChoiceTile)).colors;
        expect(_surface(tester).color, c.surfaceRaised);
        expect(_side(tester).color, c.highlight);
        expect(find.byType(Icon), findsNothing);
      });

      testWidgets('correct: green with a check icon', (tester) async {
        await pumpThemed(
          tester,
          const ChoiceTile(label: 'kapu', state: ChoiceState.correct),
          mode: mode,
        );

        final c = tester.element(find.byType(ChoiceTile)).colors;
        expect(_surface(tester).color, c.successBackground);
        expect(_side(tester).color, c.successBorder);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('wrong: red with an X icon', (tester) async {
        await pumpThemed(
          tester,
          const ChoiceTile(label: 'jegy', state: ChoiceState.wrong),
          mode: mode,
        );

        final c = tester.element(find.byType(ChoiceTile)).colors;
        expect(_surface(tester).color, c.errorBackground);
        expect(_side(tester).color, c.errorBorder);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });
  }

  testWidgets('is at least 64 high and calls onTap', (tester) async {
    var taps = 0;
    await pumpThemed(tester, ChoiceTile(label: 'kapu', onTap: () => taps++));

    expect(
      tester.getSize(find.byType(ChoiceTile)).height,
      greaterThanOrEqualTo(64),
    );
    await tester.tap(find.text('kapu'));
    expect(taps, 1);
  });

  testWidgets('without onTap nothing happens and it stays a plain tile', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      const ChoiceTile(label: 'kapu', state: ChoiceState.correct),
    );

    await tester.tap(find.text('kapu'));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('screen readers get the state in the label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpThemed(
      tester,
      const Column(
        children: [
          ChoiceTile(label: 'kapu', state: ChoiceState.correct),
          ChoiceTile(label: 'jegy', state: ChoiceState.wrong),
          ChoiceTile(label: 'ülés'),
        ],
      ),
    );

    expect(find.bySemanticsLabel('kapu, correct answer'), findsOneWidget);
    expect(find.bySemanticsLabel('jegy, wrong answer'), findsOneWidget);
    expect(find.bySemanticsLabel('ülés'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('state labels are localized', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpThemed(
      tester,
      const ChoiceTile(label: 'kapu', state: ChoiceState.wrong),
      locale: const Locale('hu'),
    );

    expect(find.bySemanticsLabel('kapu, hibás válasz'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('meets the tap target and label guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpThemed(
      tester,
      Column(
        children: [
          ChoiceTile(label: 'kapu', onTap: () {}),
          ChoiceTile(label: 'jegy', state: ChoiceState.wrong, onTap: () {}),
        ],
      ),
    );

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
