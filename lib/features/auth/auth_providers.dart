import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/features/auth/account.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';
import 'package:languagelearner/features/auth/auth_state.dart';

/// The Google sign-in. `main` overrides this; so do tests, with a fake.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError('authRepositoryProvider is not set.'),
);

/// The state found at app start, after the silent sign-in attempt. `main`
/// overrides this; nobody is signed in by default.
final initialAuthStateProvider = Provider<AuthState>(
  (ref) => const SignedOut(),
);

/// Who is signed in, and the sign-in and sign-out actions.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// The signed-in student, `null` while nobody is signed in. The screens behind
/// the sign-in only exist while there is one.
final accountProvider = Provider<Account?>(
  (ref) => switch (ref.watch(authControllerProvider)) {
    SignedIn(:final account) => account,
    SignedOut() => null,
  },
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => ref.watch(initialAuthStateProvider);

  /// Opens the Google sign-in. Throws `AuthException` when it fails, and
  /// leaves the state as it was.
  Future<void> signIn() async {
    final account = await ref.read(authRepositoryProvider).signIn();
    state = SignedIn(account);
  }

  Future<void> signOut() => _signOut(studentNotFound: false);

  /// Signs out because the backend does not know the student; the sign-in
  /// screen then explains it (card LL-28 calls this on a 403 answer).
  Future<void> signOutStudentNotFound() => _signOut(studentNotFound: true);

  Future<void> _signOut({required bool studentNotFound}) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on Exception {
      // The student leaves the app even if Google cannot be reached.
    }
    // The next student must not see the words of this one.
    ref.invalidate(decksProvider);
    state = SignedOut(studentNotFound: studentNotFound);
  }
}
