import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';
import 'package:languagelearner/features/auth/data/google_auth_repository.dart';
import 'package:languagelearner/features/auth/data/google_sign_in_client.dart';

import '../../helpers/jwt.dart';

class _FakeClient implements GoogleSignInClient {
  GoogleIdentity? restored;
  GoogleIdentity? authenticated;
  Object? restoreError;
  Object? authenticateError;
  var restoreCalls = 0;
  var signOutCalls = 0;

  @override
  Future<GoogleIdentity?> restore() async {
    restoreCalls++;
    final error = restoreError;
    if (error != null) {
      throw error;
    }
    return restored;
  }

  @override
  Future<GoogleIdentity> authenticate() async {
    final error = authenticateError;
    if (error != null) {
      throw error;
    }
    return authenticated!;
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}

final _now = DateTime.utc(2026, 10, 19, 12);

GoogleIdentity _identity({required Duration validFor, String name = 'Anna'}) =>
    GoogleIdentity(
      name: name,
      email: 'anna@example.com',
      idToken: fakeJwt(expires: _now.add(validFor)),
    );

void main() {
  late _FakeClient client;
  late GoogleAuthRepository repository;

  setUp(() {
    client = _FakeClient();
    repository = GoogleAuthRepository(client, now: () => _now);
  });

  test('restore gives the account, or null when nobody signed in', () async {
    expect(await repository.restore(), isNull);

    client.restored = _identity(validFor: const Duration(hours: 1));
    final account = await repository.restore();

    expect(account?.name, 'Anna');
    expect(account?.email, 'anna@example.com');
  });

  test('signIn gives the account of the identity', () async {
    client.authenticated = _identity(validFor: const Duration(hours: 1));

    final account = await repository.signIn();

    expect(account.email, 'anna@example.com');
  });

  test('signIn passes on the failure of the client', () async {
    client.authenticateError = const AuthException(AuthFailure.cancelled);

    await expectLater(
      repository.signIn(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.cancelled,
        ),
      ),
    );
  });

  test('idToken without a sign-in fails', () async {
    await expectLater(
      repository.idToken(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.notSignedIn,
        ),
      ),
    );
  });

  test('a token that is valid for long enough is not renewed', () async {
    final identity = _identity(validFor: const Duration(minutes: 30));
    client.authenticated = identity;
    await repository.signIn();

    expect(await repository.idToken(), identity.idToken);
    expect(client.restoreCalls, 0);
  });

  test('a token that expires soon is renewed silently', () async {
    client.authenticated = _identity(validFor: const Duration(minutes: 2));
    await repository.signIn();
    final fresh = _identity(validFor: const Duration(hours: 1));
    client.restored = fresh;

    expect(await repository.idToken(), fresh.idToken);
    expect(client.restoreCalls, 1);
    // The renewed token is kept.
    expect(await repository.idToken(), fresh.idToken);
    expect(client.restoreCalls, 1);
  });

  test('forceRefresh renews a token that has not expired', () async {
    client.authenticated = _identity(validFor: const Duration(hours: 1));
    await repository.signIn();
    final fresh = _identity(validFor: const Duration(hours: 2));
    client.restored = fresh;

    expect(await repository.idToken(forceRefresh: true), fresh.idToken);
    expect(client.restoreCalls, 1);
  });

  test('calls that arrive together share one renewal', () async {
    client.authenticated = _identity(validFor: const Duration(minutes: 1));
    await repository.signIn();
    client.restored = _identity(validFor: const Duration(hours: 1));

    final tokens = await Future.wait([
      repository.idToken(),
      repository.idToken(),
    ]);

    expect(tokens.first, tokens.last);
    expect(client.restoreCalls, 1);
  });

  test('a token that cannot be read is renewed', () async {
    client.authenticated = const GoogleIdentity(
      name: 'Anna',
      email: 'anna@example.com',
      idToken: 'not-a-jwt',
    );
    await repository.signIn();
    client.restored = _identity(validFor: const Duration(hours: 1));

    await repository.idToken();

    expect(client.restoreCalls, 1);
  });

  test('when the renewal finds nobody, the student is signed out', () async {
    client.authenticated = _identity(validFor: const Duration(minutes: 1));
    await repository.signIn();
    client.restored = null;

    await expectLater(
      repository.idToken(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.notSignedIn,
        ),
      ),
    );
    await expectLater(repository.idToken(), throwsA(isA<AuthException>()));
  });

  test('a renewal that breaks is reported as a failure', () async {
    client.authenticated = _identity(validFor: const Duration(minutes: 1));
    await repository.signIn();
    client.restoreError = StateError('offline');

    await expectLater(
      repository.idToken(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.failed,
        ),
      ),
    );
  });

  test('signOut forgets the student and signs out of Google', () async {
    client.authenticated = _identity(validFor: const Duration(hours: 1));
    await repository.signIn();

    await repository.signOut();

    expect(client.signOutCalls, 1);
    await expectLater(repository.idToken(), throwsA(isA<AuthException>()));
  });
}
