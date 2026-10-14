import 'package:flutter/widgets.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The practice modes. [name] is the route segment: `/play/<name>`.
enum PlayMode { flashcards, matching, quiz, typing, mix }

extension PlayModeTitle on PlayMode {
  /// The localized name of the mode.
  String title(BuildContext context) {
    final i18n = context.i18n;
    return switch (this) {
      PlayMode.flashcards => i18n.modeFlashcards,
      PlayMode.matching => i18n.modeMatching,
      PlayMode.quiz => i18n.modeQuiz,
      PlayMode.typing => i18n.modeTyping,
      PlayMode.mix => i18n.modeMix,
    };
  }
}
