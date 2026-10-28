import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/play/speaking/spoken_answer_matcher.dart';

MatchDecision _decide(List<String> expected, List<String> heard) =>
    decideSpokenAnswer(expected: expected, heard: heard);

void main() {
  group('normalizeSpoken', () {
    test('lower case, no punctuation, single spaces', () {
      expect(normalizeSpoken("  Don't   Stop! "), 'dont stop');
    });

    test('keeps accented letters and digits', () {
      expect(normalizeSpoken('Café 24'), 'café 24');
    });
  });

  group('decideSpokenAnswer', () {
    test('exact match after normalizing', () {
      final d = _decide(['House'], ['house.']);
      expect(d.kind, MatchKind.exact);
      expect(d.accepted, isTrue);
    });

    test('short words must be exact', () {
      expect(_decide(['cat'], ['cut']).kind, MatchKind.none);
      expect(_decide(['dogs'], ['dog']).kind, MatchKind.none);
    });

    test('medium words may differ by one letter', () {
      final d = _decide(['garden'], ['gardan']);
      expect(d.kind, MatchKind.close);
      expect(_decide(['garden'], ['gordan']).kind, MatchKind.none);
    });

    test('long words may differ by two letters', () {
      expect(_decide(['necessity'], ['nesessity']).kind, MatchKind.close);
      expect(_decide(['necessity'], ['nesesity']).kind, MatchKind.close);
      expect(_decide(['necessity'], ['nesesiti']).kind, MatchKind.none);
    });

    test('another reading of the recogniser is an alternative', () {
      final d = _decide(['house'], ['horse', 'house']);
      expect(d.kind, MatchKind.alternative);
      expect(d.matched, 'house');
    });

    test('any of several accepted answers counts', () {
      expect(_decide(['ticket', 'fare'], ['fare']).kind, MatchKind.exact);
    });

    test('words that sound the same are accepted', () {
      final d = _decide(['two'], ['too']);
      expect(d.kind, MatchKind.homophone);
      expect(d.accepted, isTrue);
      expect(_decide(['their'], ['there']).kind, MatchKind.homophone);
      expect(_decide(['to'], ['two']).kind, MatchKind.homophone);
    });

    test('a wrong word is rejected', () {
      final d = _decide(['house'], ['mouse']);
      expect(d.kind, MatchKind.none);
      expect(d.accepted, isFalse);
    });

    test('an empty reading is nothing', () {
      expect(_decide(['house'], const []).kind, MatchKind.nothing);
      expect(_decide(['house'], ['  ', '!']).kind, MatchKind.nothing);
      expect(_decide(['house'], const []).accepted, isFalse);
    });

    test('phrases are compared as a whole', () {
      expect(
        _decide(['to be or not to be'], ['To be or not to be!']).kind,
        MatchKind.exact,
      );
      expect(
        _decide(['to be or not to be'], ['to be or not to bee']).kind,
        MatchKind.close,
      );
    });
  });

  group('editDistance', () {
    test('counts insertions, deletions and substitutions', () {
      expect(editDistance('kitten', 'sitting'), 3);
      expect(editDistance('', 'abc'), 3);
      expect(editDistance('same', 'same'), 0);
    });
  });
}
