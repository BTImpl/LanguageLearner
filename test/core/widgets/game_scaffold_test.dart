import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/widgets/app_progress_bar.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';

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

  testWidgets('an action sits before the counter, the title stays centered', (
    tester,
  ) async {
    var taps = 0;
    await pumpThemed(
      tester,
      GameScaffold(
        title: 'Quiz',
        counter: '7 / 12',
        progress: 0.5,
        action: IconSquareButton(
          icon: Icons.swap_horiz,
          semanticLabel: 'Switch',
          onPressed: () => taps++,
        ),
        child: const SizedBox.shrink(),
      ),
      asScreen: true,
    );

    final screen = tester.getSize(find.byType(Scaffold));
    expect(tester.getCenter(find.text('Quiz')).dx, screen.width / 2);
    expect(
      tester.getCenter(find.byTooltip('Switch')).dx,
      lessThan(tester.getCenter(find.text('7 / 12')).dx),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Switch'));
    expect(taps, 1);
  });

  testWidgets('the header with an action fits a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpThemed(
      tester,
      GameScaffold(
        title: 'Pontos egyezés',
        counter: '12 / 12',
        progress: 1,
        action: IconSquareButton(
          icon: Icons.swap_horiz,
          semanticLabel: 'Switch',
          onPressed: () {},
        ),
        child: const SizedBox.shrink(),
      ),
      asScreen: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('12 / 12'), findsOneWidget);
  });

  group('confirmLeave', () {
    Future<List<String>> pumpConfirming(
      WidgetTester tester, {
      bool confirmLeave = true,
    }) async {
      final events = <String>[];
      await pumpThemed(
        tester,
        GameScaffold(
          title: 'Quiz',
          counter: '3 / 12',
          progress: 0.25,
          confirmLeave: confirmLeave,
          onBack: () => events.add('back'),
          child: const SizedBox.shrink(),
        ),
        asScreen: true,
      );
      return events;
    }

    testWidgets('asks before the back button leaves', (tester) async {
      final events = await pumpConfirming(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Leave the round?'), findsOneWidget);
      expect(
        find.text('Your result so far will not be saved.'),
        findsOneWidget,
      );
      expect(events, isEmpty);
    });

    testWidgets('Keep playing stays', (tester) async {
      final events = await pumpConfirming(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep playing'));
      await tester.pumpAndSettle();

      expect(find.text('Leave the round?'), findsNothing);
      expect(events, isEmpty);
    });

    testWidgets('Leave goes back', (tester) async {
      final events = await pumpConfirming(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(find.text('Leave the round?'), findsNothing);
      expect(events, ['back']);
    });

    testWidgets('the system back asks too', (tester) async {
      final events = await pumpConfirming(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Leave the round?'), findsOneWidget);
      expect(events, isEmpty);

      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(events, ['back']);
    });

    testWidgets('without it the back button leaves at once', (tester) async {
      final events = await pumpConfirming(tester, confirmLeave: false);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Leave the round?'), findsNothing);
      expect(events, ['back']);
    });

    testWidgets('Leave pops the route when there is no onBack', (tester) async {
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
                    counter: '3 / 12',
                    progress: 0.25,
                    confirmLeave: true,
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

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(find.text('Quiz'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
