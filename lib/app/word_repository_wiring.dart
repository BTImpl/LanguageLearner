import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/app_config.dart';
import 'package:languagelearner/core/data/api/api_word_repository.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';

/// The answer must start within this time of the connection.
const _connectTimeout = Duration(seconds: 10);

/// The whole answer must arrive within this time.
const _receiveTimeout = Duration(seconds: 20);

/// The [WordRepository] that asks the backend, signed in with the Google ID
/// token of the student.
///
/// A 401 answer that survives a new token signs the student out; a 403 answer
/// signs the student out and explains it on the sign-in screen. [dio] is for
/// tests; the app builds its own client for [AppConfig.apiBaseUrl].
WordRepository createApiWordRepository(Ref ref, {Dio? dio}) {
  final client =
      dio ??
      Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: _connectTimeout,
          receiveTimeout: _receiveTimeout,
          headers: {'Accept': 'application/json'},
        ),
      );
  ref.onDispose(client.close);
  final auth = ref.read(authRepositoryProvider);
  return ApiWordRepository(
    dio: client,
    idToken: ({bool forceRefresh = false}) =>
        _idToken(auth, forceRefresh: forceRefresh),
    onUnauthorized: () =>
        unawaited(ref.read(authControllerProvider.notifier).signOut()),
    onStudentNotFound: () => unawaited(
      ref.read(authControllerProvider.notifier).signOutStudentNotFound(),
    ),
  );
}

Future<String> _idToken(
  AuthRepository auth, {
  required bool forceRefresh,
}) async {
  try {
    return await auth.idToken(forceRefresh: forceRefresh);
  } on AuthException catch (error) {
    // A token that cannot be renewed because of the network is no reason to
    // sign the student out.
    throw WordLoadException(
      error.failure == AuthFailure.failed
          ? WordLoadFailure.noNetwork
          : WordLoadFailure.unauthorized,
    );
  }
}
