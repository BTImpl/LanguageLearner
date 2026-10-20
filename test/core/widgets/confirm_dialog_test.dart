import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/widgets/confirm_dialog.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';

import '../../helpers/pump_themed.dart';

/// Pumps a screen with a button that opens the dialog; [answers] collects
/// what the dialog returned.
Future<void> _open(
  WidgetTester tester,
  List<bool> answers, {
  ThemeMode mode = ThemeMode.dark,
  String title = 'Leave the round?',
  String message = 'Your result so far will not be saved.',
  String confirmLabel = 'Leave',
  String cancelLabel = 'Keep playing',
}) async {
  await pumpThemed(
    tester,
    Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () async => answers.add(
            await showConfirmDialog(
              context,
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              cancelLabel: cancelLabel,
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
    mode: mode,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  for (final mode in themeModes) {
    testWidgets('shows the title, the message and both buttons in '
        '${mode.name} mode', (tester) async {
      await _open(tester, [], mode: mode);

      expect(find.byType(ConfirmDialog), findsOneWidget);
      expect(find.text('Leave the round?'), findsOneWidget);
      expect(
        find.text('Your result so far will not be saved.'),
        findsOneWidget,
      );
      expect(find.text('Keep playing'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
    });
  }

  testWidgets('the texts are large enough to read', (tester) async {
    await _open(tester, []);

    final title = tester.widget<Text>(find.text('Leave the round?'));
    final message = tester.widget<Text>(
      find.text('Your result so far will not be saved.'),
    );
    expect(title.style!.fontSize, greaterThanOrEqualTo(22));
    expect(title.style!.fontWeight, FontWeight.w700);
    expect(message.style!.fontSize, greaterThanOrEqualTo(17));
  });

  testWidgets('both buttons are at least 48 high and as wide as the card', (
    tester,
  ) async {
    await _open(tester, []);

    for (final label in ['Keep playing', 'Leave']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.bySubtype<ButtonStyleButton>(),
      );
      final size = tester.getSize(button);
      expect(size.height, greaterThanOrEqualTo(48), reason: label);
      expect(
        size.width,
        tester.getSize(find.byType(PrimaryButton)).width,
        reason: label,
      );
    }
  });

  testWidgets('Keep playing is the main button and Leave the quiet one', (
    tester,
  ) async {
    await _open(tester, []);

    expect(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.text('Keep playing'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SecondaryButton),
        matching: find.text('Leave'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Keep playing answers false and closes the dialog', (
    tester,
  ) async {
    final answers = <bool>[];
    await _open(tester, answers);

    await tester.tap(find.text('Keep playing'));
    await tester.pumpAndSettle();

    expect(answers, [false]);
    expect(find.byType(ConfirmDialog), findsNothing);
  });

  testWidgets('Leave answers true and closes the dialog', (tester) async {
    final answers = <bool>[];
    await _open(tester, answers);

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(answers, [true]);
    expect(find.byType(ConfirmDialog), findsNothing);
  });

  testWidgets('a tap outside the dialog answers false', (tester) async {
    final answers = <bool>[];
    await _open(tester, answers);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(answers, [false]);
    expect(find.byType(ConfirmDialog), findsNothing);
  });

  testWidgets('the system back gesture answers false', (tester) async {
    final answers = <bool>[];
    await _open(tester, answers);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(answers, [false]);
    expect(find.byType(ConfirmDialog), findsNothing);
  });

  testWidgets('large system text does not overflow and can be scrolled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final answers = <bool>[];

    await _open(tester, answers);

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Leave'),
      100,
      scrollable: find.descendant(
        of: find.byType(ConfirmDialog),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(answers, [true]);
  });

  testWidgets('long Hungarian labels fit on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _open(
      tester,
      [],
      title: 'Biztosan kilépsz a körből?',
      message: 'Az eddigi eredmény nem mentődik, a kör elölről kezdődik.',
      confirmLabel: 'Kilépek a körből',
      cancelLabel: 'Folytatom a játékot',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Folytatom a játékot'), findsOneWidget);
    expect(find.text('Kilépek a körből'), findsOneWidget);
  });
}
