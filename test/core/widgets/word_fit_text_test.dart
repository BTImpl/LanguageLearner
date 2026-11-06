import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/widgets/word_fit_text.dart';

// The test font 'Ahem' draws every character as a square of the font size, so
// the width of a word is its length times the size.
const _style = TextStyle(fontFamily: 'Ahem', fontSize: 46, height: 1.1);

double _fit(
  String text, {
  double width = 300,
  TextScaler scaler = TextScaler.noScaling,
}) => fitWordFontSize(
  text: text,
  style: _style,
  maxWidth: width,
  minFontSize: 24,
  textScaler: scaler,
);

void main() {
  group('fitWordFontSize', () {
    test('keeps the full size for a short word', () {
      expect(_fit('cat'), 46);
    });

    test('shrinks for a word that is wider than the line', () {
      // 12 letters: 299 / 12 = 24.9, so 24.
      expect(_fit('szükségesség'), 24);
      // 9 letters: 299 / 9 = 33.2.
      expect(_fit('necessity'), 33);
    });

    test('keeps the full size for many short words', () {
      // 18 characters would not fit one line, but every word does.
      expect(_fit('to be or not to be'), 46);
    });

    test('shrinks for a long word between short ones', () {
      expect(_fit('it is a necessity'), 33);
    });

    test('never goes below the smallest size', () {
      expect(_fit('megvalósíthatatlanság'), 24);
    });

    test('a word that fits exactly keeps the full size', () {
      expect(_fit('abcdef', width: 277), 46);
    });

    test('may break after a hyphen, so a compound is measured in parts', () {
      expect(_fit('well-known'), 46);
    });

    test('uses the text scale of the phone', () {
      const scaler = TextScaler.linear(1.5);
      expect(_fit('cat', scaler: scaler), 46);
      // 5 letters at 1.5 times: 299 / (5 * 1.5) = 39.9, so 39.
      expect(_fit('house', scaler: scaler), 39);
      expect(_fit('szükségesség', scaler: scaler), 24);
    });

    test('keeps the full size without text or without a width', () {
      expect(_fit(''), 46);
      expect(_fit('szükségesség', width: double.infinity), 46);
      expect(_fit('szükségesség', width: 0), 46);
    });
  });

  group('WordFitText', () {
    Future<void> pump(WidgetTester tester, String text, {double? width}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width ?? 300,
                child: WordFitText(text, style: _style),
              ),
            ),
          ),
        ),
      );
    }

    double size(WidgetTester tester) =>
        tester.widget<Text>(find.byType(Text)).style!.fontSize!;

    testWidgets('a long word is smaller and stays in one line', (tester) async {
      await pump(tester, 'szükségesség');

      expect(size(tester), 24);
      // One line: the height of a single line at this size.
      expect(tester.getSize(find.byType(Text)).height, lessThan(24 * 1.1 + 1));
    });

    testWidgets('many short words wrap between the words at full size', (
      tester,
    ) async {
      await pump(tester, 'to be or not to be');

      expect(size(tester), 46);
      expect(
        tester.getSize(find.byType(Text)).height,
        greaterThan(46 * 1.1 * 2),
      );
    });

    testWidgets('a word that does not fit at the smallest size breaks', (
      tester,
    ) async {
      await pump(tester, 'megvalósíthatatlanság');

      expect(size(tester), 24);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(Text)).height,
        greaterThan(24 * 1.1 * 1.5),
      );
    });

    testWidgets('the size follows a changed text', (tester) async {
      await pump(tester, 'szükségesség');
      expect(size(tester), 24);

      await pump(tester, 'cat');
      expect(size(tester), 46);
    });
  });

  group('fitHeightFontSize', () {
    const text = 'aa bb cc dd ee ff gg hh ii jj kk ll mm nn oo pp';

    double fit({double height = 100, double min = 10}) => fitHeightFontSize(
      text: text,
      style: _style,
      start: 46,
      maxWidth: 300,
      maxHeight: height,
      minFontSize: min,
      textScaler: TextScaler.noScaling,
    );

    test('keeps the size when the text is low enough', () {
      expect(fit(height: 2000), 46);
    });

    test('shrinks until the wrapped text fits in the height', () {
      final size = fit();

      expect(size, lessThan(46));
      expect(size, greaterThanOrEqualTo(10));
      // One size larger would not fit.
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: _style.copyWith(fontSize: size + 1),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 300);
      expect(painter.height, greaterThan(100));
      painter.dispose();
    });

    test('stops at the smallest size', () {
      expect(fit(height: 5, min: 20), 20);
    });

    test('keeps the size without a limit', () {
      expect(
        fitHeightFontSize(
          text: text,
          style: _style,
          start: 46,
          maxWidth: 300,
          maxHeight: double.infinity,
          minFontSize: 10,
          textScaler: TextScaler.noScaling,
        ),
        46,
      );
    });
  });

  group('WordFitText in a limited height', () {
    Future<void> pump(
      WidgetTester tester,
      String text, {
      required double height,
      double minFontSize = 10,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: height,
                child: WordFitText(
                  text,
                  style: _style,
                  minFontSize: minFontSize,
                ),
              ),
            ),
          ),
        ),
      );
    }

    const longText =
        'aa bb cc dd ee ff gg hh ii jj kk ll mm nn oo pp qq rr ss tt';

    testWidgets('a long text gets a smaller size and fits', (tester) async {
      await pump(tester, longText, height: 120);

      final size = tester.widget<Text>(find.byType(Text)).style!.fontSize!;
      expect(size, lessThan(46));
      expect(tester.getSize(find.byType(Text)).height, lessThanOrEqualTo(120));
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('scrolls when it does not fit even at the smallest size', (
      tester,
    ) async {
      await pump(tester, longText * 3, height: 40, minFontSize: 24);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
