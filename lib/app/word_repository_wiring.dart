import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/app_config.dart';
import 'package:languagelearner/core/data/api/api_attempt_uploader.dart';
import 'package:languagelearner/core/data/api/api_word_repository.dart';
import 'package:languagelearner/core/data/cached_word_repository.dart';
import 'package:languagelearner/core/data/deck_cache.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/api_photo_quiz_repository.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_repository.dart';
import 'package:languagelearner/features/stats/data/attempt_uploader.dart';

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
  final client = dio ?? _newClient();
  ref.onDispose(client.close);
  return ApiWordRepository(
    dio: client,
    idToken: _idTokenSource(ref),
    onUnauthorized: () =>
        unawaited(ref.read(authControllerProvider.notifier).signOut()),
    onStudentNotFound: () => unawaited(
      ref.read(authControllerProvider.notifier).signOutStudentNotFound(),
    ),
  );
}

/// The [AttemptUploader] that sends the answers to the backend, signed in with
/// the Google ID token of the student (card LL-30). A 401 answer that survives
/// a new token signs the student out. [dio] is for tests.
AttemptUploader createApiAttemptUploader(Ref ref, {Dio? dio}) {
  final client = dio ?? _newClient();
  ref.onDispose(client.close);
  return ApiAttemptUploader(
    dio: client,
    idToken: _idTokenSource(ref),
    onUnauthorized: () =>
        unawaited(ref.read(authControllerProvider.notifier).signOut()),
  );
}

/// The [PhotoQuizRepository] that sends the photos to the backend, signed in
/// with the Google ID token of the student (card LL-51). A 401 answer that
/// survives a new token signs the student out; a 403 answer signs the student
/// out and explains it on the sign-in screen. [dio] is for tests.
PhotoQuizRepository createApiPhotoQuizRepository(Ref ref, {Dio? dio}) {
  final client = dio ?? _newClient();
  ref.onDispose(client.close);
  return ApiPhotoQuizRepository(
    dio: client,
    idToken: _idTokenSource(ref),
    onUnauthorized: () =>
        unawaited(ref.read(authControllerProvider.notifier).signOut()),
    onStudentNotFound: () => unawaited(
      ref.read(authControllerProvider.notifier).signOutStudentNotFound(),
    ),
  );
}

Dio _newClient() => Dio(
  BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: _connectTimeout,
    receiveTimeout: _receiveTimeout,
    headers: {'Accept': 'application/json'},
  ),
);

IdTokenSource _idTokenSource(Ref ref) {
  final auth = ref.read(authRepositoryProvider);
  return ({bool forceRefresh = false}) =>
      _idToken(auth, forceRefresh: forceRefresh);
}

/// The [WordRepository] of the app: the decks of [remote] saved in [cache], so
/// the words are there without a network. A background download that brings
/// new words reloads the decks of the screens.
WordRepository createCachedWordRepository(
  Ref ref, {
  required WordRepository remote,
  required DeckCache cache,
}) {
  var disposed = false;
  ref.onDispose(() => disposed = true);
  return CachedWordRepository(
    remote: remote,
    cache: cache,
    now: ref.read(clockProvider),
    onBackgroundUpdate: () {
      if (!disposed) {
        ref.invalidate(decksProvider);
      }
    },
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
