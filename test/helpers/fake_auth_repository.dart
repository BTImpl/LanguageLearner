import 'dart:async';

import 'package:languagelearner/features/auth/account.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';

const testAccount = Account(name: 'Kiss Anna', email: 'kiss.anna@example.com');

/// An [AuthRepository] for tests: it counts the calls and fails or waits on
/// demand.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.restored});

  /// What [restore] gives.
  Account? restored;

  /// When set, [signIn] throws it.
  AuthException? signInError;

  /// When set, [signIn] waits for it (to look at the screen while signing in).
  Completer<void>? signInGate;

  /// When set, [signOut] throws it.
  Exception? signOutError;

  var token = 'id-token';
  var signInCalls = 0;
  var signOutCalls = 0;

  @override
  Future<Account?> restore() async => restored;

  @override
  Future<Account> signIn() async {
    signInCalls++;
    await signInGate?.future;
    final error = signInError;
    if (error != null) {
      throw error;
    }
    return testAccount;
  }

  @override
  Future<String> idToken() async => token;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    final error = signOutError;
    if (error != null) {
      throw error;
    }
  }
}
