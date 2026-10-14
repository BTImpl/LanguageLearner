import 'dart:math';

import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';

/// One round of practice: the words of a deck in random order, the position
/// in them and the outcome of every word.
///
/// Pure Dart, shared by all game modes. A new session always shuffles, so
/// opening a mode and restarting a round give a new order.
class RoundSession {
  /// Starts a round with [words] shuffled by [random] (an unseeded [Random]
  /// by default; pass a seeded one in tests) and the time taken from [now].
  RoundSession({
    required List<WordPair> words,
    required this.promptLanguage,
    Random? random,
    DateTime Function()? now,
  }) : _random = random ?? Random(),
       _now = now ?? DateTime.now,
       _words = List.unmodifiable(shuffled(words, random ?? Random())) {
    _startedAt = _now();
    if (_words.isEmpty) {
      _finishedAt = _startedAt;
    }
  }

  /// Returns a copy of [items] in random order (Fisher–Yates).
  static List<T> shuffled<T>(Iterable<T> items, Random random) {
    final result = items.toList();
    for (var i = result.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final swapped = result[i];
      result[i] = result[j];
      result[j] = swapped;
    }
    return result;
  }

  /// Which side of a word is the question.
  final PromptLanguage promptLanguage;

  final Random _random;
  final DateTime Function() _now;
  List<WordPair> _words;
  late DateTime _startedAt;
  DateTime? _finishedAt;
  var _index = 0;
  final _outcomes = <String, WordOutcome>{};
  final _extras = <String, int>{};

  /// The words in the order of this round.
  List<WordPair> get words => _words;

  int get total => _words.length;

  bool get isEmpty => _words.isEmpty;

  /// The position of the current word, from 0. Equals [total] when finished.
  int get index => _index;

  bool get isFinished => _index >= total;

  /// The current word, `null` when the round is finished (or empty).
  WordPair? get current => isFinished ? null : _words[_index];

  /// Moves [count] words forward. The round is finished after the last word.
  void advance([int count = 1]) {
    _index = min(_index + count, total);
    if (isFinished) {
      _finishedAt ??= _now();
    }
  }

  /// Moves one word back; does nothing at the first word.
  void back() {
    if (_index == 0) {
      return;
    }
    _index--;
    _finishedAt = null;
  }

  /// Records an attempt at [word]. Only the first attempt (or help request)
  /// of a word counts; later ones are ignored.
  void recordAttempt(WordPair word, {required bool correct}) {
    _record(word, correct ? WordOutcome.firstTry : WordOutcome.wrongFirst);
  }

  /// Records that the student asked for help with [word]. Counts only if it
  /// is the first thing that happened to the word.
  void recordHelp(WordPair word) => _record(word, WordOutcome.withHelp);

  /// The outcome of [word] so far, `null` while it has none.
  WordOutcome? outcomeOf(WordPair word) => _outcomes[word.id];

  /// Adds [by] to the extra counter [name], see [RoundCounters].
  void count(String name, [int by = 1]) =>
      _extras[name] = (_extras[name] ?? 0) + by;

  /// The text of [word] that is the question.
  String promptText(WordPair word) => switch (promptLanguage) {
    PromptLanguage.english => word.english,
    PromptLanguage.hungarian => word.hungarian,
  };

  /// The text of [word] that is the answer.
  String answerText(WordPair word) => switch (promptLanguage) {
    PromptLanguage.english => word.hungarian,
    PromptLanguage.hungarian => word.english,
  };

  /// Every text accepted as an exact answer for [word].
  List<String> acceptedAnswers(WordPair word) => switch (promptLanguage) {
    PromptLanguage.english => word.acceptedHungarian,
    PromptLanguage.hungarian => word.acceptedEnglish,
  };

  /// Whether the question is English, i.e. whether it can be read aloud.
  bool get promptIsEnglish => promptLanguage == PromptLanguage.english;

  /// The outcome so far. The duration runs until the round is finished.
  RoundResult get result {
    final decided = [
      for (final word in _words)
        if (_outcomes.containsKey(word.id)) word,
    ];
    int countOf(WordOutcome outcome) =>
        decided.where((word) => _outcomes[word.id] == outcome).length;
    List<WordPair> wordsOf(WordOutcome outcome) => [
      for (final word in decided)
        if (_outcomes[word.id] == outcome) word,
    ];
    return RoundResult(
      total: total,
      firstTry: countOf(WordOutcome.firstTry),
      withHelp: countOf(WordOutcome.withHelp),
      wrongFirst: countOf(WordOutcome.wrongFirst),
      missedWords: wordsOf(WordOutcome.wrongFirst),
      helpedWords: wordsOf(WordOutcome.withHelp),
      duration: (_finishedAt ?? _now()).difference(_startedAt),
      extras: Map.unmodifiable(_extras),
    );
  }

  /// Starts over with a new random order and no outcomes.
  void restart() {
    _words = List.unmodifiable(shuffled(_words, _random));
    _index = 0;
    _outcomes.clear();
    _extras.clear();
    _startedAt = _now();
    _finishedAt = _words.isEmpty ? _startedAt : null;
  }

  void _record(WordPair word, WordOutcome outcome) {
    if (!_words.any((w) => w.id == word.id)) {
      throw ArgumentError.value(word, 'word', 'is not part of this round');
    }
    _outcomes.putIfAbsent(word.id, () => outcome);
  }
}
