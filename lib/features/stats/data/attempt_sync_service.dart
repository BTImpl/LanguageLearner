import 'dart:developer' as developer;

import 'package:languagelearner/features/stats/data/attempt_store.dart';
import 'package:languagelearner/features/stats/data/attempt_uploader.dart';

/// The largest batch sent in one request (the backend accepts 500).
const attemptSyncBatchSize = 200;

/// Uploads the local answers the backend does not have yet (card LL-30).
///
/// - Batches of at most [batchSize], the oldest first, until nothing waits.
/// - Only one sync runs at a time; a call during a run joins it, and the run
///   looks again for rows saved meanwhile.
/// - A network or server problem stops the sync silently; the rows stay and
///   the next trigger tries again.
/// - A batch the backend refuses (400) is marked as rejected and logged, so it
///   cannot block the rows behind it.
class AttemptSyncService {
  AttemptSyncService({
    required this._store,
    required this._uploader,
    this.batchSize = attemptSyncBatchSize,
  });

  final AttemptStore _store;
  final AttemptUploader _uploader;
  final int batchSize;

  Future<void>? _running;
  bool _again = false;

  /// Whether a sync is running now.
  bool get isRunning => _running != null;

  /// Runs a sync, or joins the one that is running. Never throws.
  Future<void> sync() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _run().whenComplete(() => _running = null);
  }

  Future<void> _run() async {
    try {
      do {
        _again = false;
        if (!await _drain()) {
          return;
        }
      } while (_again);
    } on Object catch (error, stack) {
      // A storage problem: the rows stay for the next time.
      developer.log(
        'Attempt sync failed',
        name: 'AttemptSyncService',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Sends batches until none waits. Returns false when it had to stop.
  Future<bool> _drain() async {
    while (true) {
      final batch = await _store.pending(limit: batchSize);
      if (batch.isEmpty) {
        return true;
      }
      final ids = [for (final record in batch) record.id];
      try {
        await _uploader.upload(batch);
      } on AttemptUploadException catch (error) {
        if (error.failure == AttemptUploadFailure.rejected) {
          developer.log(
            'The backend rejected ${ids.length} attempts, '
            'they are not sent again',
            name: 'AttemptSyncService',
            level: 900,
          );
          await _store.markRejected(ids);
          continue;
        }
        return false;
      }
      await _store.markSynced(ids);
    }
  }
}
