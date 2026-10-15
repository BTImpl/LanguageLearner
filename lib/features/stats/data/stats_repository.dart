import 'package:flutter/foundation.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/stats/data/attempt_record.dart';
import 'package:languagelearner/features/stats/data/attempt_store.dart';

/// The totals of one deck.
@immutable
class DeckSummary {
  const DeckSummary({
    required this.totalAnswers,
    required this.firstTryAnswers,
    required this.wordsGoingFirstTry,
  });

  static const empty = DeckSummary(
    totalAnswers: 0,
    firstTryAnswers: 0,
    wordsGoingFirstTry: 0,
  );

  /// All answers ever given on the words of the deck.
  final int totalAnswers;

  /// How many of them were right at the first attempt.
  final int firstTryAnswers;

  /// How many words "go first try": their latest answer was right at the
  /// first attempt.
  final int wordsGoingFirstTry;

  @override
  bool operator ==(Object other) =>
      other is DeckSummary &&
      other.totalAnswers == totalAnswers &&
      other.firstTryAnswers == firstTryAnswers &&
      other.wordsGoingFirstTry == wordsGoingFirstTry;

  @override
  int get hashCode =>
      Object.hash(totalAnswers, firstTryAnswers, wordsGoingFirstTry);

  @override
  String toString() =>
      'DeckSummary($firstTryAnswers/$totalAnswers, $wordsGoingFirstTry words)';
}

/// How one word went so far.
@immutable
class WordStat {
  const WordStat({
    required this.wordId,
    required this.firstTry,
    required this.total,
  });

  final String wordId;

  /// Answers that were right at the first attempt.
  final int firstTry;

  /// All answers on the word.
  final int total;

  @override
  bool operator ==(Object other) =>
      other is WordStat &&
      other.wordId == wordId &&
      other.firstTry == firstTry &&
      other.total == total;

  @override
  int get hashCode => Object.hash(wordId, firstTry, total);

  @override
  String toString() => 'WordStat($wordId: $firstTry/$total)';
}

/// Saves the results of the finished rounds and answers questions about them.
class StatsRepository {
  StatsRepository({
    required this._store,
    required this._now,
    required this._newId,
  });

  final AttemptStore _store;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Saves the per-word results of a finished round in one go.
  ///
  /// Call it only when the round is over: an abandoned round saves nothing.
  /// Flashcards have no right or wrong answer, so that mode saves nothing
  /// either.
  Future<void> saveRound(
    RoundResult result, {
    required String deckId,
    required PlayMode mode,
  }) async {
    if (mode == PlayMode.flashcards || result.outcomes.isEmpty) {
      return;
    }
    final answeredAt = _now();
    await _store.insertAll([
      for (final entry in result.outcomes.entries)
        AttemptRecord(
          id: _newId(),
          deckId: deckId,
          wordId: entry.key,
          mode: mode,
          outcome: entry.value,
          answeredAt: answeredAt,
        ),
    ]);
  }

  /// The totals of [deckId]; all zero while nothing was answered.
  Future<DeckSummary> deckSummary(String deckId) async {
    final records = await _store.forDeck(deckId);
    final firstTryAnswers = records
        .where((record) => record.outcome == WordOutcome.firstTry)
        .length;
    // The records are oldest first, so the last one of a word wins.
    final latest = <String, WordOutcome>{
      for (final record in records) record.wordId: record.outcome,
    };
    return DeckSummary(
      totalAnswers: records.length,
      firstTryAnswers: firstTryAnswers,
      wordsGoingFirstTry: latest.values
          .where((outcome) => outcome == WordOutcome.firstTry)
          .length,
    );
  }

  /// Every answered word of [deckId], the hardest first: the lowest share of
  /// first-try answers on top, and among equal shares the one with more
  /// answers. Words nobody answered yet are not listed.
  Future<List<WordStat>> wordStats(String deckId) async {
    final records = await _store.forDeck(deckId);
    final firstTry = <String, int>{};
    final total = <String, int>{};
    for (final record in records) {
      total[record.wordId] = (total[record.wordId] ?? 0) + 1;
      if (record.outcome == WordOutcome.firstTry) {
        firstTry[record.wordId] = (firstTry[record.wordId] ?? 0) + 1;
      }
    }
    final stats = [
      for (final entry in total.entries)
        WordStat(
          wordId: entry.key,
          firstTry: firstTry[entry.key] ?? 0,
          total: entry.value,
        ),
    ];
    stats.sort((a, b) {
      // a.firstTry / a.total < b.firstTry / b.total, without division.
      final byShare = (a.firstTry * b.total).compareTo(b.firstTry * a.total);
      if (byShare != 0) {
        return byShare;
      }
      final byAnswers = b.total.compareTo(a.total);
      return byAnswers != 0 ? byAnswers : a.wordId.compareTo(b.wordId);
    });
    return stats;
  }
}
