import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/services/email_sender.dart';

void main() {
  group('the mailto link', () {
    OutgoingEmail email({String subject = 'Quiz', String body = 'text'}) =>
        OutgoingEmail(
          recipient: 'tanar@example.com',
          subject: subject,
          body: body,
        );

    test('addresses the teacher and carries the subject and the body', () {
      final uri = buildMailtoUri(email(subject: 'Quiz – Anna', body: 'Hi'));

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'tanar@example.com');
      expect(uri.queryParameters['subject'], 'Quiz – Anna');
      expect(uri.queryParameters['body'], 'Hi');
    });

    test('keeps every line break as %0A', () {
      final uri = buildMailtoUri(email(body: 'one\ntwo\n\nthree'));

      expect(uri.toString(), contains('body=one%0Atwo%0A%0Athree'));
      expect(uri.queryParameters['body'], 'one\ntwo\n\nthree');
    });

    test('writes a space as %20 and never as +', () {
      final uri = buildMailtoUri(email(subject: 'a b', body: 'c d'));

      expect(uri.toString(), contains('subject=a%20b'));
      expect(uri.toString(), contains('body=c%20d'));
      expect(uri.toString(), isNot(contains('+')));
    });

    test('survives characters that would end or split the query', () {
      const body = 'A & B = C # D + E ? F';
      final uri = buildMailtoUri(email(body: body));

      expect(uri.queryParameters['body'], body);
      expect('&'.allMatches(uri.toString()), hasLength(1));
    });

    test('keeps accents and the checkbox marks', () {
      const body = 'Diák: Árvíztűrő\n   [x] a) go\n   [ ] b) goes';
      final uri = buildMailtoUri(email(body: body));

      expect(uri.queryParameters['body'], body);
    });
  });
}
