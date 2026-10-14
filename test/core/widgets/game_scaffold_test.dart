import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/widgets/app_progress_bar.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';

import '../../helpers/pump_themed.dart';

void main() {
  for (final mode in themeModes) {
    testWidgets('GameScaffold lays out the frame in ${mode.name} mode', (
      tester,
    ) async {
      var backs = 0;
      await pumpThemed(
        tester,
        GameScaffold(
          title: 'Quiz',
          counter: '7 / 12',
          progress: 7 / 12,
          onBack: () => backs++,
          child: const Text('content'),
        ),
        mode: mode,
        asScreen: true,
      );

      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('7 / 12'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
      expect(find.byType(AppProgressBar), findsOneWidget);

      // 20 px side margin: the progress bar spans the screen minus margins.
      final screen = tester.getSize(find.byType(Scaffold));
      expect(
        tester.getSize(find.byType(AppProgressBar)).width,
        screen.width - 40,
      );

      await tester.tap(find.byTooltip('Back'));
      expect(backs, 1);
    });
  }

  testWidgets('the back button label is localized', (tester) async {
    await pumpThemed(
      tester,
      const GameScaffold(
        title: 'Tanuló',
        counter: '1 / 12',
        progress: 0,
        child: SizedBox.shrink(),
      ),
      locale: const Locale('hu'),
      asScreen: true,
    );

    expect(find.byTooltip('Vissza'), findsOneWidget);
  });

  testWidgets('back pops the route by default', (tester) async {
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => const GameScaffold(
                  title: 'Quiz',
                  counter: '1 / 12',
                  progress: 0,
                  child: SizedBox.shrink(),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      asScreen: true,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz'), findsNothing);
  });
}
