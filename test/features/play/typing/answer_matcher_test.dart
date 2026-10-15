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

  test('normalize trims, single-spaces and lowercases', () {
    expect(AnswerMatcher.normalize('  A   Big\tCat '), 'a big cat');
  });
}
