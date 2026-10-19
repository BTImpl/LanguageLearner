import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:languagelearner/core/data/deck_cache.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';

/// How old the saved decks may get before [CachedWordRepository.getDecks]
/// downloads them again in the background.
const deckCacheMaxAge = Duration(minutes: 15);

/// A [WordRepository] that keeps the last downloaded decks on the phone, so
/// the student can practice without a network.
///
/// - [getDecks] answers from the saved decks at once. If they are older than
///   [maxAge], they are downloaded again in the background, and
///   [onBackgroundUpdate] tells the screens when that brought something new.
///   Only when nothing is saved yet does [getDecks] wait for the network.
/// - [refresh] always asks the backend and replaces the saved decks.
/// - A failed download never touches the saved decks.
class CachedWordRepository implements WordRepository {
  CachedWordRepository({
    required this._remote,
    required this._cache,
    required this._now,
    required this._onBackgroundUpdate,
    this.maxAge = deckCacheMaxAge,
  });

  final WordRepository _remote;
  final DeckCache _cache;
  final DateTime Function() _now;
  final VoidCallback _onBackgroundUpdate;
  final Duration maxAge;

  /// Grows when the saved decks are forgotten; a download that started before
  /// that must not save its decks (they may belong to the previous student).
  var _epoch = 0;
  var _updatingInBackground = false;

  @override
  Future<List<Deck>> getDecks() async {
    final saved = await _readSaved();
    if (saved == null) {
      return _download();
    }
    if (_isStale(saved.fetchedAt)) {
      unawaited(_updateInBackground(saved.decks));
    }
    return saved.decks;
  }

  @override
  Future<void> refresh() async {
    final epoch = _epoch;
    await _remote.refresh();
    final decks = await _remote.getDecks();
    if (epoch == _epoch) {
      await _cache.replace(decks, _now());
    }
  }

  @override
  Future<void> clearLocal() async {
    _epoch++;
    await _cache.clear();
  }

  bool _isStale(DateTime fetchedAt) {
    final age = _now().difference(fetchedAt);
    // A negative age means the clock of the phone was set back.
    return age.isNegative || age > maxAge;
  }

  // A broken local database must not keep the student from the words: it
  // counts as nothing saved.
  Future<DeckSnapshot?> _readSaved() async {
    try {
      return await _cache.read();
    } on Exception {
      return null;
    }
  }

  Future<List<Deck>> _download() async {
    final epoch = _epoch;
    final decks = await _remote.getDecks();
    if (epoch == _epoch) {
      await _trySave(decks);
    }
    return decks;
  }

  Future<void> _updateInBackground(List<Deck> shown) async {
    if (_updatingInBackground) {
      return;
    }
    _updatingInBackground = true;
    final epoch = _epoch;
    try {
      final decks = await _remote.getDecks();
      if (epoch != _epoch) {
        return;
      }
      await _cache.replace(decks, _now());
      if (epoch == _epoch && !listEquals(decks, shown)) {
        _onBackgroundUpdate();
      }
    } on Exception {
      // The saved decks stay; the next start or the refresh button tries again.
    } finally {
      _updatingInBackground = false;
    }
  }

  Future<void> _trySave(List<Deck> decks) async {
    try {
      await _cache.replace(decks, _now());
    } on Exception {
      // The decks are shown anyway, they are just not saved for later.
    }
  }
}
