import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/play/speaking/speaking_game.dart';
import 'package:languagelearner/features/play/widgets/answer_help_box.dart';
import 'package:languagelearner/features/play/widgets/question_card.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The body of the speaking game: the Hungarian word, the microphone button,
/// what was heard, the help and the buttons. It has no frame (title,
/// counter), so the speaking screen and the Mix mode can both use it.
///
/// It shows the state of [game] and must be rebuilt when the game changes.
class SpeakingContent extends ConsumerStatefulWidget {
  const SpeakingContent({required this.game, super.key});

  final SpeakingGame game;

  @override
  ConsumerState<SpeakingContent> createState() => _SpeakingContentState();
}

class _SpeakingContentState extends ConsumerState<SpeakingContent> {
  void _onMic() {
    final game = widget.game;
    if (game.isListening) {
      game.stopListening().ignore();
    } else {
      game.listen().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final word = game.current;
    if (word == null) {
      return const SizedBox.shrink();
    }
    final i18n = context.i18n;
    final session = game.session;
    final solved = game.isSolved;
    final givenUp = game.isGivenUp;
    final isLast = game.index == game.total - 1;
    final locked = solved || givenUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuestionCard(
                  label: i18n.speakingPrompt,
                  text: session.promptText(word),
                  onReadAloud: null,
                ),
                const SizedBox(height: 24),
                Center(
                  child: _MicButton(
                    listening: game.isListening,
                    enabled: !locked,
                    onPressed: _onMic,
                  ),
                ),
                const SizedBox(height: 12),
                _Caption(game: game),
                const SizedBox(height: 12),
                _Feedback(game: game),
                if (game.helpVisible) ...[
                  const SizedBox(height: 12),
                  AnswerHelpBox(
                    text: game.helpText!,
                    revision: game.helpRevision,
                    duration: game.helpDuration,
                  ),
                ],
                if (solved) ...[
                  const SizedBox(height: 12),
                  _SolvedAnswer(
                    text: session.answerText(word),
                    onReadAloud: ref.canReadAloud
                        ? () => ref
                              .read(ttsServiceProvider)
                              .speak(word.english)
                              .ignore()
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (solved)
          PrimaryButton(
            label: isLast ? i18n.finish : i18n.next,
            onPressed: game.next,
          )
        else
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: i18n.speakingHelp,
                  icon: Icons.visibility_outlined,
                  onPressed: givenUp ? null : game.requestHelp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: i18n.speakingSkip,
                  icon: Icons.skip_next_outlined,
                  onPressed: givenUp ? null : game.skip,
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// The round microphone button: filled while idle, a frame with a stop sign
/// while listening.
class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.listening,
    required this.enabled,
    required this.onPressed,
  });

  final bool listening;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final fill = listening
        ? c.surface
        : (enabled ? c.primary : c.surfaceRaised);
    final icon = listening
        ? c.highlight
        : (enabled ? c.onPrimary : c.textMuted);
    return Semantics(
      button: true,
      enabled: enabled,
      label: listening ? i18n.speakingStop : i18n.speakingStart,
      excludeSemantics: true,
      child: Material(
        key: const ValueKey('speaking-mic'),
        color: fill,
        shape: CircleBorder(
          side: listening
              ? BorderSide(color: c.highlight, width: 3)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: SizedBox.square(
            dimension: 88,
            child: Icon(
              listening ? Icons.stop_rounded : Icons.mic,
              size: 40,
              color: icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// The line under the microphone: what to do, or what is heard right now.
class _Caption extends StatelessWidget {
  const _Caption({required this.game});

  final SpeakingGame game;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final String text;
    if (game.isListening) {
      text = game.partial.isEmpty ? i18n.speakingListening : game.partial;
    } else if (game.isSolved || game.isGivenUp) {
      text = '';
    } else {
      text = i18n.speakingStart;
    }
    return Column(
      children: [
        SizedBox(
          height: 24,
          child: Semantics(
            liveRegion: true,
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: bodyFontFamily,
                fontSize: 16,
                fontWeight: game.isListening && game.partial.isNotEmpty
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: game.isListening && game.partial.isNotEmpty
                    ? c.text
                    : c.textMuted,
              ),
            ),
          ),
        ),
        if (game.audioMayLeaveDevice && !game.isSolved) ...[
          const SizedBox(height: 4),
          Text(
            i18n.speakingPrivacy,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: bodyFontFamily,
              fontSize: 12,
              color: c.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// What the last try led to: right, wrong, nothing heard or an error. It
/// always takes its place, so nothing jumps when it appears.
class _Feedback extends StatelessWidget {
  const _Feedback({required this.game});

  final SpeakingGame game;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final feedback = game.feedback;
    final (
      String? title,
      String? text,
      Color color,
      Color background,
    ) = switch (feedback) {
      SpeakingFeedback.none => (null, null, c.text, c.surface),
      SpeakingFeedback.correct => (
        null,
        i18n.speakingCorrect,
        c.successText,
        c.successBackground,
      ),
      SpeakingFeedback.wrong => (
        null,
        game.isGivenUp
            ? i18n.speakingGaveUp
            : (game.isLastAttempt
                  ? i18n.speakingMismatchLast
                  : i18n.speakingMismatch),
        c.errorText,
        c.errorBackground,
      ),
      SpeakingFeedback.nothing => (
        null,
        i18n.speakingNothing,
        c.textMuted,
        c.surfaceRaised,
      ),
      SpeakingFeedback.denied => (
        i18n.speakingDeniedTitle,
        i18n.speakingDeniedMessage,
        c.errorText,
        c.errorBackground,
      ),
      SpeakingFeedback.unavailable => (
        null,
        i18n.speakingUnavailable,
        c.errorText,
        c.errorBackground,
      ),
      SpeakingFeedback.failed => (
        null,
        i18n.speakingFailed,
        c.errorText,
        c.errorBackground,
      ),
    };
    if (text == null) {
      return const SizedBox(height: 24);
    }
    final showHeard =
        game.heard.isNotEmpty &&
        (feedback == SpeakingFeedback.wrong ||
            feedback == SpeakingFeedback.correct);
    return Semantics(
      liveRegion: true,
      child: AppCard(
        color: background,
        borderRadius: AppRadii.choice,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title,
                style: TextStyle(
                  fontFamily: bodyFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            Text(
              text,
              style: TextStyle(
                fontFamily: bodyFontFamily,
                fontSize: 16,
                fontWeight: title == null ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
            if (showHeard) ...[
              const SizedBox(height: 4),
              Text(
                '${i18n.speakingHeard}: “${game.heard}”',
                style: TextStyle(
                  fontFamily: bodyFontFamily,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The right answer after it was said, with the button that reads it aloud.
class _SolvedAnswer extends StatelessWidget {
  const _SolvedAnswer({required this.text, required this.onReadAloud});

  final String text;
  final VoidCallback? onReadAloud;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      color: c.surfaceRaised,
      borderRadius: AppRadii.choice,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: headingFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
          ),
          if (onReadAloud != null) ReadAloudButton(onPressed: onReadAloud!),
        ],
      ),
    );
  }
}
