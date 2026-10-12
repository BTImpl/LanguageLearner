import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/app.dart';

void main() {
  testWidgets('az app elindul és a kezdőképernyőt mutatja', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LanguageLearnerApp()));

    expect(find.text('LanguageLearner'), findsOneWidget);
  });
}
