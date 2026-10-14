import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/models/word_pair.dart';

void main() {
  group('parseVariants', () {
    test('splits on semicolons', () {
      expect(parseVariants('jegy;menetjegy'), ['jegy', 'menetjegy']);
    });

    test('trims the whitespace around the variants', () {
      expect(parseVariants('  jegy ;  menetjegy  '), ['jegy', 'menetjegy']);
    });

    test('keeps the spaces inside a variant', () {
      expect(parseVariants('boarding pass; boarding card'), [
        'boarding pass',
        'boarding card',
      ]);
    });

    test('skips empty variants', () {
      expect(parseVariants('jegy;; ;menetjegy;'), ['jegy', 'menetjegy']);
    });

    test('gives no variants for an empty or blank cell', () {
      expect(parseVariants(''), isEmpty);
      expect(parseVariants('   '), isEmpty);
      expect(parseVariants(' ; ;'), isEmpty);
    });

    test('a single value is one variant', () {
      expect(parseVariants('jegy'), ['jegy']);
    });
  });

  group('WordPair.fromCells', () {
    test('shows the first variant and accepts all of them', () {
      final word = WordPair.fromCells(
        id: 'w1',
        english: 'ticket',
        hungarian: 'jegy; menetjegy',
      );

      expect(word.english, 'ticket');
      expect(word.hungarian, 'jegy');
      expect(word.acceptedEnglish, ['ticket']);
      expect(word.acceptedHungarian, ['jegy', 'menetjegy']);
      expect(word.example, isNull);
    });

    test('keeps a trimmed example and drops a blank one', () {
      final withExample = WordPair.fromCells(
        id: 'w1',
        english: 'delay',
        hungarian: 'késés',
        example: '  A long delay.  ',
      );
      final blankExample = WordPair.fromCells(
        id: 'w2',
        english: 'delay',
        hungarian: 'késés',
        example: '   ',
      );

      expect(withExample.example, 'A long delay.');
      expect(blankExample.example, isNull);
    });

    test('rejects a cell without any text', () {
      expect(
        () => WordPair.fromCells(id: 'w1', english: ' ; ', hungarian: 'jegy'),
        throwsArgumentError,
      );
      expect(
        () => WordPair.fromCells(id: 'w1', english: 'ticket', hungarian: ''),
        throwsArgumentError,
      );
    });

    test('words with the same content are equal', () {
      WordPair build() => WordPair.fromCells(
        id: 'w1',
        english: 'ticket',
        hungarian: 'jegy; menetjegy',
      );

      expect(build(), build());
      expect(build().hashCode, build().hashCode);
    });
  });
}
