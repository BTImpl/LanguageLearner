import 'package:flutter/widgets.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The practice modes. [name] is the route segment: `/play/<name>`.
enum PlayMode { flashcards, matching, quiz, typing, speaking, mix }

extension PlayModeTexts on PlayMode {
  /// The localized name of the mode.
  String title(BuildContext context) {
    final i18n = context.i18n;
    return switch (this) {
      PlayMode.flashcards => i18n.modeFlashcards,
      PlayMode.matching => i18n.modeMatching,
      PlayMode.quiz => i18n.modeQuiz,
      PlayMode.typing => i18n.modeTyping,
      PlayMode.speaking => i18n.modeSpeaking,
      PlayMode.mix => i18n.modeMix,
    };
  }

  /// A short description of the mode.
  String hint(BuildContext context) {
    final i18n = context.i18n;
    return switch (this) {
      PlayMode.flashcards => i18n.modeFlashcardsHint,
      PlayMode.matching => i18n.modeMatchingHint,
      PlayMode.quiz => i18n.modeQuizHint,
      PlayMode.typing => i18n.modeTypingHint,
      PlayMode.speaking => i18n.modeSpeakingHint,
      PlayMode.mix => i18n.modeMixHint,
    };
  }
}
