import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/app.dart';

void main() {
  testWidgets('app starts and shows the home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LanguageLearnerApp()));

    expect(find.text('LanguageLearner'), findsOneWidget);
  });
}
