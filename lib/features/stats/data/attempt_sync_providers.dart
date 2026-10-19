import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/stats/data/attempt_store.dart';
import 'package:languagelearner/features/stats/data/attempt_sync_service.dart';
import 'package:languagelearner/features/stats/data/attempt_uploader.dart';
import 'package:languagelearner/features/stats/data/stats_providers.dart';

/// Where the answers go. `main` overrides it with the backend; the default
/// never reaches one, which is what tests and the offline mode want.
final attemptUploaderProvider = Provider<AttemptUploader>(
  (ref) => const NoopAttemptUploader(),
);

/// The sync of the local answers with the backend (card LL-30).
final attemptSyncServiceProvider = Provider<AttemptSyncService>(
  (ref) => AttemptSyncService(
    store: ref.watch(attemptStoreProvider),
    uploader: ref.watch(attemptUploaderProvider),
  ),
);

/// The key under which the e-mail of the student who owns the local answers
/// is saved.
const attemptOwnerKey = 'attemptOwner';

/// Makes sure the local answers belong to the student who is signed in.
///
/// The answers stay on the phone when the student signs out (so nothing is
/// lost if the sign-out was automatic). They are forgotten only when somebody
/// else signs in, so they are never uploaded under another account. Returns
/// false when the owner could not be checked; nothing may be uploaded then.
Future<bool> claimAttempts({
  required KeyValueStore Function() keys,
  required AttemptStore store,
  required String email,
}) async {
  try {
    final keyValues = keys();
    final owner = await keyValues.getString(attemptOwnerKey);
    if (owner != null && owner != email) {
      await store.clear();
    }
    if (owner != email) {
      await keyValues.setString(attemptOwnerKey, email);
    }
    return true;
  } on Object catch (error, stack) {
    developer.log(
      'Could not check the owner of the local answers',
      name: 'attemptSync',
      error: error,
      stackTrace: stack,
    );
    return false;
  }
}
