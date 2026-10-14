import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';

import '../../helpers/pump_themed.dart';

BoxDecoration _decoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(AppCard),
      matching: find.byType(DecoratedBox),
    ),
  );
  return box.decoration as BoxDecoration;
}

void main() {
  for (final mode in themeModes) {
    testWidgets('AppCard uses surface color, line border, tile corners in '
        '${mode.name} mode', (tester) async {
      await pumpThemed(tester, const AppCard(child: Text('Hello')), mode: mode);

      final context = tester.element(find.byType(AppCard));
      final decoration = _decoration(tester);
      expect(decoration.color, context.colors.surface);
      expect(decoration.border, Border.all(color: context.colors.line));
      expect(decoration.borderRadius, AppRadii.tile);
      expect(find.text('Hello'), findsOneWidget);
    });
  }

  testWidgets('AppCard takes a custom corner shape and a gradient', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      AppCard(
        borderRadius: AppRadii.flip,
        gradient: AppColors.dark.brandGradient,
        child: const Text('Hello'),
      ),
    );

    final decoration = _decoration(tester);
    expect(decoration.borderRadius, AppRadii.flip);
    expect(decoration.gradient, AppColors.dark.brandGradient);
    expect(decoration.color, isNull);
  });
}
