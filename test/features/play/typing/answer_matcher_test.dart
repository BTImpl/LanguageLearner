import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/play/typing/answer_matcher.dart';

void main() {
  bool matches(String input, [List<String> accepted = const ['útlevél']]) =>
      AnswerMatcher.matches(input, accepted);

  group('case', () {
    test('an exact answer is right', () {
      expect(matches('útlevél'), isTrue);
    });

    test('upper and lower case do not matter', () {
      expect(matches('ÚTLEVÉL'), isTrue);
      expect(matches('Útlevél'), isTrue);
      expect(matches('útlevél', ['ÚTLEVÉL']), isTrue);
    });

    test('Hungarian double acute letters are compared in any case', () {
      expect(matches('ŐRÜLT', ['őrült']), isTrue);
      expect(matches('őrült', ['ŐRÜLT']), isTrue);
    });
  });

  group('spaces', () {
    test('spaces around the answer do not matter', () {
      expect(matches('  útlevél  '), isTrue);
      expect(matches('\tútlevél\n'), isTrue);
    });

    test('several spaces between words count as one', () {
      expect(
        matches('a  connecting   flight', ['a connecting flight']),
        isTrue,
      );
      expect(matches('a\tconnecting flight', ['a connecting flight']), isTrue);
    });

    test('a missing space is a mistake', () {
      expect(matches('aconnecting flight', ['a connecting flight']), isFalse);
    });

    test('spaces in the accepted answer are normalized too', () {
      expect(matches('boarding pass', [' boarding   pass ']), isTrue);
    });
  });

  group('accents', () {
    test('a missing accent is a mistake', () {
      expect(matches('utlevel'), isFalse);
      expect(matches('útlevel'), isFalse);
      expect(matches('utlevél'), isFalse);
    });

    test('a wrong accent is a mistake', () {
      expect(matches('ütlevél'), isFalse);
      expect(matches('őrült', ['örült']), isFalse);
    });
  });

  group('several accepted answers', () {
    const accepted = ['jegy', 'menetjegy', 'belépő'];

    test('any of them is right', () {
      for (final answer in accepted) {
        expect(matches(answer, accepted), isTrue);
      }
      expect(matches('  MENETJEGY ', accepted), isTrue);
    });

    test('something else is wrong', () {
      expect(matches('bilet', accepted), isFalse);
      expect(matches('jegy menetjegy', accepted), isFalse);
    });

    test('nothing accepted means nothing is right', () {
      expect(matches('jegy', const []), isFalse);
    });
  });

  group('empty input', () {
    test('an empty text is never right', () {
      expect(matches(''), isFalse);
      expect(matches('   '), isFalse);
      expect(matches('\n\t'), isFalse);
    });

    test('an empty text is not right even if an empty answer is accepted', () {
      expect(matches('', ['']), isFalse);
    });
  });

  group('characters that only look right', () {
    test('invisible characters are ignored', () {
      expect(matches('\u200Bútlevél'), isTrue);
      expect(matches('út\u200Blevél'), isTrue);
      expect(matches('útlevél\u200B'), isTrue);
      expect(matches('\uFEFFútlevél'), isTrue);
      expect(matches('út\u00ADlevél'), isTrue);
      expect(matches('\u200Eútlevél\u200F'), isTrue);
      expect(
        matches('a\u2060 connecting flight', ['a connecting flight']),
        isTrue,
      );
    });

    test('a text with only invisible characters is empty', () {
      expect(matches('\u200B\u200B', ['']), isFalse);
      expect(AnswerMatcher.normalize('\u200B \uFEFF'), isEmpty);
    });

    test('a non-breaking space is a space', () {
      expect(
        matches('a\u00A0connecting\u202Fflight', ['a connecting flight']),
        isTrue,
      );
      expect(matches('\u00A0útlevél\u00A0'), isTrue);
    });

    test('curly quotes are plain quotes', () {
      expect(matches('don\u2019t', ["don't"]), isTrue);
      expect(matches('don\u2018t', ["don't"]), isTrue);
      expect(matches("don't", ['don\u2019t']), isTrue);
      expect(matches('\u201Chello\u201D', ['"hello"']), isTrue);
      expect(matches('\u201Ehello\u201D', ['"hello"']), isTrue);
    });

    test('long dashes are hyphens', () {
      expect(matches('ice\u2013cream', ['ice-cream']), isTrue);
      expect(matches('ice\u2014cream', ['ice-cream']), isTrue);
      expect(matches('ice\u2011cream', ['ice-cream']), isTrue);
      expect(matches('ice\u2212cream', ['ice-cream']), isTrue);
    });

    test('an ellipsis character is three dots', () {
      expect(matches('well\u2026', ['well...']), isTrue);
    });

    test('a different character is still wrong', () {
      expect(matches("don't", ['dont']), isFalse);
      expect(matches('ice cream', ['ice-cream']), isFalse);
    });
  });

  group('combining accents', () {
    test('a base letter and a combining accent is the accented letter', () {
      expect(matches('u\u0301tlevel\u0301'), isFalse); // not -l-e-v-é-l
      expect(matches('u\u0301tleve\u0301l'), isTrue);
      expect(matches('útleve\u0301l'), isTrue);
      expect(matches('o\u0308', ['\u00F6']), isTrue);
      expect(matches('o\u030B', ['\u0151']), isTrue);
      expect(matches('u\u030B', ['\u0171']), isTrue);
      expect(matches('U\u030B', ['\u0171']), isTrue);
    });

    test('the accented letter in the sheet can be the decomposed one', () {
      expect(matches('útlevél', ['u\u0301tleve\u0301l']), isTrue);
    });

    test('a combining accent on the wrong letter is a mistake', () {
      expect(matches('u\u0308tleve\u0301l'), isFalse);
      expect(matches('o\u0301', ['\u0151']), isFalse);
    });
  });

  test('normalize trims, single-spaces and lowercases', () {
    expect(AnswerMatcher.normalize('  A   Big\tCat '), 'a big cat');
  });
}
