import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/core/widgets/state_message.dart';

import '../../helpers/pump_themed.dart';

void main() {
  for (final mode in themeModes) {
    group('${mode.name} mode', () {
      testWidgets('shows the icon, the title and the message', (tester) async {
        await pumpThemed(
          tester,
          const StateMessage(
            icon: Icons.wifi_off_outlined,
            title: 'No internet connection',
            message: 'Try again later.',
          ),
          mode: mode,
        );

        expect(find.byIcon(Icons.wifi_off_outlined), findsOneWidget);
        expect(find.text('No internet connection'), findsOneWidget);
        expect(find.text('Try again later.'), findsOneWidget);
        expect(find.byType(PrimaryButton), findsNothing);
      });

      testWidgets('the button runs the action', (tester) async {
        var taps = 0;
        await pumpThemed(
          tester,
          StateMessage(
            icon: Icons.error_outline,
            title: 'Title',
            message: 'Message',
            actionLabel: 'Try again',
            onAction: () => taps++,
          ),
          mode: mode,
        );

        await tester.tap(find.text('Try again'));

        expect(taps, 1);
      });
    });
  }

  testWidgets('a running action shows a spinner and cannot be repeated', (
    tester,
  ) async {
    var taps = 0;
    await pumpThemed(
      tester,
      StateMessage(
        icon: Icons.menu_book_outlined,
        title: 'Title',
        message: 'Message',
        actionLabel: 'Refresh',
        actionLoading: true,
        onAction: () => taps++,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);

    expect(taps, 0);
  });

  testWidgets('is centered on the screen width', (tester) async {
    await pumpThemed(
      tester,
      const StateMessage(
        icon: Icons.error_outline,
        title: 'Title',
        message: 'Message',
      ),
    );

    final screen = tester.getSize(find.byType(Scaffold));
    expect(
      tester.getCenter(find.text('Title')).dx,
      closeTo(screen.width / 2, 0.5),
    );
  });
}
