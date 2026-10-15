import 'package:flutter/foundation.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';

/// One answered word, as stored in the local database.
@immutable
class AttemptRecord {
  const AttemptRecord({
    required this.id,
    required this.deckId,
    required this.wordId,
    required this.mode,
    required this.outcome,
    required this.answeredAt,
    this.synced = false,
  });

  /// Generated on the phone (UUID), see card LL-30.
  final String id;
  final String deckId;
  final String wordId;
  final PlayMode mode;
  final WordOutcome outcome;
  final DateTime answeredAt;

  /// Whether the backend already has this row.
  final bool synced;

  @override
  bool operator ==(Object other) =>
      other is AttemptRecord &&
      other.id == id &&
      other.deckId == deckId &&
      other.wordId == wordId &&
      other.mode == mode &&
      other.outcome == outcome &&
      other.answeredAt == answeredAt &&
      other.synced == synced;

  @override
  int get hashCode =>
      Object.hash(id, deckId, wordId, mode, outcome, answeredAt, synced);
}
