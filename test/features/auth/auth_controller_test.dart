import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';
import 'package:languagelearner/features/auth/auth_state.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  ProviderContainer container({AuthState initial = const SignedOut()}) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        initialAuthStateProvider.overrideWithValue(initial),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => repository = FakeAuthRepository());

  test('starts with the state found at app start', () {
    expect(container().read(authControllerProvider), isA<SignedOut>());
    expect(container().read(accountProvider), isNull);

    final signedIn = container(initial: const SignedIn(testAccount));

    expect(signedIn.read(accountProvider), testAccount);
  });

  test('signing in makes the student the signed-in account', () async {
    final c = container();

    await c.read(authControllerProvider.notifier).signIn();

    expect(c.read(authControllerProvider), isA<SignedIn>());
    expect(c.read(accountProvider), testAccount);
  });

  test('a failed sign-in throws and keeps the student signed out', () async {
    repository.signInError = const AuthException(AuthFailure.cancelled);
    final c = container();

    await expectLater(
      c.read(authControllerProvider.notifier).signIn(),
      throwsA(isA<AuthException>()),
    );

    expect(c.read(authControllerProvider), isA<SignedOut>());
  });

  test('signing out signs out of Google and clears the account', () async {
    final c = container(initial: const SignedIn(testAccount));

    await c.read(authControllerProvider.notifier).signOut();

    expect(repository.signOutCalls, 1);
    expect(c.read(accountProvider), isNull);
    final state = c.read(authControllerProvider);
    expect(state, isA<SignedOut>());
    expect((state as SignedOut).studentNotFound, isFalse);
  });

  test('the student leaves even if Google cannot be reached', () async {
    repository.signOutError = Exception('offline');
    final c = container(initial: const SignedIn(testAccount));

    await c.read(authControllerProvider.notifier).signOut();

    expect(c.read(authControllerProvider), isA<SignedOut>());
  });

  test('an unknown student is signed out with an explanation', () async {
    final c = container(initial: const SignedIn(testAccount));

    await c.read(authControllerProvider.notifier).signOutStudentNotFound();

    final state = c.read(authControllerProvider);
    expect(state, isA<SignedOut>());
    expect((state as SignedOut).studentNotFound, isTrue);
  });

  test('signing in again clears the explanation', () async {
    final c = container(initial: const SignedOut(studentNotFound: true));

    await c.read(authControllerProvider.notifier).signIn();

    expect(c.read(authControllerProvider), isA<SignedIn>());
  });
}
