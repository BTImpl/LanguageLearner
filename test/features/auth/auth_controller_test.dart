import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';
import 'package:languagelearner/features/auth/auth_state.dart';

import '../../helpers/fake_auth_repository.dart';

class _CountingRepository implements WordRepository {
  var clears = 0;

  /// When set, [clearLocal] throws it.
  Exception? clearError;

  @override
  Future<List<Deck>> getDecks() async => const [];

  @override
  Future<void> refresh() async {}

  @override
  Future<void> clearLocal() async {
    clears++;
    if (clearError case final error?) {
      throw error;
    }
  }
}

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

  group('the saved words', () {
    late _CountingRepository words;

    ProviderContainer signedInContainer() {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          initialAuthStateProvider.overrideWithValue(
            const SignedIn(testAccount),
          ),
          wordRepositoryProvider.overrideWithValue(words),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    setUp(() => words = _CountingRepository());

    test('are forgotten when the student signs out', () async {
      final c = signedInContainer();

      await c.read(authControllerProvider.notifier).signOut();

      expect(words.clears, 1);
    });

    test('a problem forgetting them does not stop the sign-out', () async {
      words.clearError = Exception('disk');
      final c = signedInContainer();

      await c.read(authControllerProvider.notifier).signOut();

      expect(c.read(authControllerProvider), isA<SignedOut>());
    });
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

  test(
    'signing out twice at once signs out once, for the first reason',
    () async {
      final c = container(initial: const SignedIn(testAccount));
      final notifier = c.read(authControllerProvider.notifier);

      await Future.wait([
        notifier.signOutStudentNotFound(),
        notifier.signOut(),
      ]);

      expect(repository.signOutCalls, 1);
      expect(
        (c.read(authControllerProvider) as SignedOut).studentNotFound,
        isTrue,
      );
    },
  );

  test('signing out while signed out does nothing', () async {
    final c = container(initial: const SignedOut(studentNotFound: true));

    await c.read(authControllerProvider.notifier).signOut();

    expect(repository.signOutCalls, 0);
    expect(
      (c.read(authControllerProvider) as SignedOut).studentNotFound,
      isTrue,
    );
  });

  test('signing in again clears the explanation', () async {
    final c = container(initial: const SignedOut(studentNotFound: true));

    await c.read(authControllerProvider.notifier).signIn();

    expect(c.read(authControllerProvider), isA<SignedIn>());
  });
}
