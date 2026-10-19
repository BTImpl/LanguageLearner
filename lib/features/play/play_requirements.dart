import 'package:languagelearner/features/play/play_mode.dart';

/// How many words a deck needs for [mode] to make sense.
///
/// - matching needs two words to pair up;
/// - the quiz needs four, so that every question has three wrong answers;
/// - the other modes work from one word on. The Mix never draws a task the
///   deck is too small for (it asks only to type with one word, and to type
///   and match with two or three).
int minWordsFor(PlayMode mode) => switch (mode) {
  PlayMode.matching => 2,
  PlayMode.quiz => 4,
  PlayMode.flashcards || PlayMode.typing || PlayMode.mix => 1,
};

/// Whether a deck with [wordCount] words can be practiced in [mode].
bool hasEnoughWords(PlayMode mode, int wordCount) =>
    wordCount >= minWordsFor(mode);
