import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/services/system_settings_opener.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_engine.dart';
import 'package:languagelearner/features/photo_quiz/photo/widgets/photo_permission_message.dart';

import '../../../../helpers/fake_system_settings_opener.dart';
import '../../../../helpers/pump_themed.dart';

Future<FakeSystemSettingsOpener> _pump(
  WidgetTester tester,
  PhotoOrigin origin, {
  ThemeMode mode = ThemeMode.dark,
  Locale locale = const Locale('en'),
}) async {
  final opener = FakeSystemSettingsOpener();
  await pumpThemed(
    tester,
    ProviderScope(
      overrides: [systemSettingsOpenerProvider.overrideWithValue(opener)],
      child: SingleChildScrollView(
        child: PhotoPermissionMessage(origin: origin),
      ),
    ),
    mode: mode,
    locale: locale,
  );
  return opener;
}

void main() {
  for (final mode in themeModes) {
    group('${mode.name} mode', () {
      testWidgets('explains the refused camera and offers the settings', (
        tester,
      ) async {
        await _pump(tester, PhotoOrigin.camera, mode: mode);

        expect(find.text('No access to the camera'), findsOneWidget);
        expect(
          find.text('Allow it in Settings to make a quiz from a photo.'),
          findsOneWidget,
        );
        expect(find.text('Open Settings'), findsOneWidget);
      });

      testWidgets('explains the refused photos', (tester) async {
        await _pump(tester, PhotoOrigin.gallery, mode: mode);

        expect(find.text('No access to your photos'), findsOneWidget);
        expect(find.text('No access to the camera'), findsNothing);
      });
    });
  }

  testWidgets('the button opens the system settings', (tester) async {
    final opener = await _pump(tester, PhotoOrigin.camera);

    await tester.tap(find.text('Open Settings'));
    await tester.pump();

    expect(opener.opened, 1);
  });

  testWidgets('is written in Hungarian too', (tester) async {
    await _pump(tester, PhotoOrigin.camera, locale: const Locale('hu'));

    expect(find.text('Nincs hozzáférés a kamerához'), findsOneWidget);
    expect(find.text('Megnyitás a Beállításokban'), findsOneWidget);
  });

  testWidgets('the button is big enough to tap and labeled', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, PhotoOrigin.camera);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
