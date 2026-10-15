import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/stats/data/stats_providers.dart';

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
  final repository = ref.read(statsRepositoryProvider);
  unawaited(_save(repository.saveRound(result, deckId: deckId, mode: mode)));
}

Future<void> _save(Future<void> saving) async {
  try {
    await saving;
  } on Exception {
    // Ignored on purpose, see above.
  }
}
