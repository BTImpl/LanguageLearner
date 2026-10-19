import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/stats/data/attempt_sync_providers.dart';
import 'package:languagelearner/features/stats/data/attempt_sync_service.dart';
import 'package:languagelearner/features/stats/data/stats_providers.dart';
import 'package:languagelearner/features/stats/data/stats_repository.dart';

/// Saves a finished round in the statistics.
///
/// Call it once, when the round is over. A storage problem must not spoil the
/// round-end screen, so a failure is ignored: that round is just missing from
/// the statistics.
void recordRound(
  WidgetRef ref, {
  required RoundResult result,
  required String deckId,
  required PlayMode mode,
}) {
  // Read everything now: the screen may be gone when the saving is done.
  final repository = ref.read(statsRepositoryProvider);
  final revision = ref.read(statsRevisionProvider.notifier);
  final sync = ref.read(attemptSyncServiceProvider);
  unawaited(_save(repository, revision, sync, result, deckId, mode));
}

Future<void> _save(
  StatsRepository repository,
  StatsRevision revision,
  AttemptSyncService sync,
  RoundResult result,
  String deckId,
  PlayMode mode,
) async {
  try {
    await repository.saveRound(result, deckId: deckId, mode: mode);
    revision.bump();
  } on Exception {
    // Ignored on purpose, see above.
    return;
  }
  // Upload the new answers; a failure stays silent and is retried later.
  await sync.sync();
}
