import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/shell/app_bottom_nav.dart';
import 'package:languagelearner/app/theme/app_colors.dart';

import '../../helpers/pump_themed.dart';

const _items = [
  AppNavItem(icon: Icons.school_outlined, label: 'Learn'),
  AppNavItem(icon: Icons.bar_chart, label: 'Statistics'),
  AppNavItem(icon: Icons.settings_outlined, label: 'Settings'),
];

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

FontWeight? _labelWeight(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.fontWeight;

void main() {
  for (final mode in themeModes) {
    group('${mode.name} mode', () {
      testWidgets('the active tab is primary colored and bold', (tester) async {
        await pumpThemed(
          tester,
          AppBottomNav(items: _items, currentIndex: 1, onSelected: (_) {}),
          mode: mode,
        );

        final c = tester.element(find.byType(AppBottomNav)).colors;
        expect(_labelColor(tester, 'Statistics'), c.primary);
        expect(_labelWeight(tester, 'Statistics'), FontWeight.w700);
        expect(_labelColor(tester, 'Learn'), c.textMuted);
        expect(_labelColor(tester, 'Settings'), c.textMuted);
        expect(_labelWeight(tester, 'Learn'), FontWeight.w500);
      });

      testWidgets('every tab has an icon and a label', (tester) async {
        await pumpThemed(
          tester,
          AppBottomNav(items: _items, currentIndex: 0, onSelected: (_) {}),
          mode: mode,
        );

        for (final item in _items) {
          expect(find.byIcon(item.icon), findsOneWidget);
          expect(find.text(item.label), findsOneWidget);
        }
      });
    });
  }

  testWidgets('tapping a tab reports its index', (tester) async {
    final selected = <int>[];
    await pumpThemed(
      tester,
      AppBottomNav(items: _items, currentIndex: 0, onSelected: selected.add),
    );

    await tester.tap(find.text('Settings'));
    await tester.tap(find.text('Learn'));

    expect(selected, [2, 0]);
  });

  testWidgets('is 84 high with the bottom safe area of an iPhone', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
        child: AppBottomNav(items: _items, currentIndex: 0, onSelected: (_) {}),
      ),
    );

    // 50 of tabs + 34 of safe area.
    expect(tester.getSize(find.byType(AppBottomNav)).height, 84);
  });

  testWidgets('the tabs are labeled and big enough to tap', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpThemed(
      tester,
      AppBottomNav(items: _items, currentIndex: 1, onSelected: (_) {}),
    );

    expect(find.bySemanticsLabel('Learn'), findsOneWidget);
    expect(find.bySemanticsLabel('Statistics'), findsOneWidget);
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
