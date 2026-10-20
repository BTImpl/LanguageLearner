import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/play/typing/typing_game.dart';
import 'package:languagelearner/features/play/widgets/question_card.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The body of the exact-match game: the question card, the input, the help
/// and the two buttons. It has no frame (title, counter), so the typing
/// screen and the Mix mode can both use it.
///
/// It shows the state of [game] and must be rebuilt when the game changes.
/// It owns the text input, so a new game needs a new widget (a new key).
class TypingContent extends ConsumerStatefulWidget {
  const TypingContent({required this.game, super.key});

  final TypingGame game;

  @override
  ConsumerState<TypingContent> createState() => _TypingContentState();
}

class _TypingContentState extends ConsumerState<TypingContent> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// Whether the last check was wrong and the text has not been edited since.
  var _mismatch = false;

  // The word the input belongs to. When the game moves on by itself (the
  // attempts ran out), the input has to be emptied here.
  String? _wordId;

  @override
  void initState() {
    super.initState();
    _wordId = widget.game.current?.id;
  }

  @override
  void didUpdateWidget(TypingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.game.current?.id;
    if (id != _wordId) {
      _wordId = id;
      _controller.clear();
      _mismatch = false;
    }
  }

  /// "Check" and the send key of the keyboard: checks the answer, or moves on
  /// when it is already right.
  void _submit() {
    final game = widget.game;
    if (game.isSolved) {
      _next();
      return;
    }
    final result = game.submit(_controller.text);
    switch (result) {
      case SubmitResult.correct:
        HapticFeedback.lightImpact().ignore();
        setState(() => _mismatch = false);
      case SubmitResult.wrong:
        HapticFeedback.heavyImpact().ignore();
        // The text stays as it was typed, so the mistake can be seen (and
        // corrected) until the attempts run out.
        setState(() => _mismatch = true);
      case SubmitResult.ignored:
        break;
    }
  }

  void _next() {
    _controller.clear();
    _mismatch = false;
    widget.game.next();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
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
    final fieldState = solved
        ? _FieldState.correct
        : (_mismatch || givenUp ? _FieldState.wrong : _FieldState.idle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Only this part scrolls, so the buttons stay above the keyboard.
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuestionCard(
                  label: session.promptIsEnglishFor(word)
                      ? i18n.typingWriteHungarian
                      : i18n.typingWriteEnglish,
                  text: session.promptText(word),
                  onReadAloud:
                      session.promptIsEnglishFor(word) && ref.canReadAloud
                      ? () => ref
                            .read(ttsServiceProvider)
                            .speak(word.english)
                            .ignore()
                      : null,
                ),
                const SizedBox(height: 20),
                _AnswerField(
                  controller: _controller,
                  focusNode: _focus,
                  state: fieldState,
                  locked: givenUp,
                  onChanged: (_) {
                    if (_mismatch) {
                      setState(() => _mismatch = false);
                    }
                  },
                  onSubmit: _submit,
                ),
                const SizedBox(height: 12),
                _MismatchHint(
                  visible: fieldState == _FieldState.wrong,
                  text: givenUp
                      ? i18n.typingGaveUp
                      : (game.isLastAttempt
                            ? i18n.typingMismatchLast
                            : i18n.typingMismatch),
                ),
                if (game.helpVisible) ...[
                  const SizedBox(height: 12),
                  _HelpBox(
                    text: game.helpText!,
                    revision: game.helpRevision,
                    duration: game.helpDuration,
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: i18n.typingHelp,
                icon: Icons.visibility_outlined,
                onPressed: solved || givenUp ? null : game.requestHelp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: solved
                    ? (isLast ? i18n.finish : i18n.next)
                    : i18n.typingCheck,
                onPressed: givenUp ? null : _submit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

enum _FieldState { idle, wrong, correct }

/// The "Your answer" input: 60 high, an indigo frame when focused, red after
/// a wrong answer, green with a check mark when right.
class _AnswerField extends StatelessWidget {
  const _AnswerField({
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.locked,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final _FieldState state;

  /// The attempts are used up: the text cannot be edited any more.
  final bool locked;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: AppRadii.choice,
      borderSide: BorderSide(color: color, width: width),
    );
    final (fill, idleBorder, focusBorder, labelColor) = switch (state) {
      _FieldState.idle => (
        c.surface,
        border(c.line, 1),
        c.highlight,
        c.textMuted,
      ),
      _FieldState.wrong => (
        c.errorBackground,
        border(c.errorBorder, 2),
        c.errorBorder,
        c.errorText,
      ),
      _FieldState.correct => (
        c.successBackground,
        border(c.successBorder, 2),
        c.successBorder,
        c.successText,
      ),
    };
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      // A solved answer cannot be edited, but the field stays connected to the
      // keyboard, so its send key can still move on to the next word.
      inputFormatters: [
        if (state == _FieldState.correct || locked)
          TextInputFormatter.withFunction((oldValue, newValue) => oldValue),
      ],
      autocorrect: false,
      enableSuggestions: false,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      textCapitalization: TextCapitalization.none,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      // Instead of onSubmitted, so the keyboard stays open.
      onEditingComplete: onSubmit,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: state == _FieldState.correct ? c.successText : c.text,
      ),
      cursorColor: c.highlight,
      decoration: InputDecoration(
        labelText: context.i18n.typingAnswerLabel,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: TextStyle(
          fontFamily: bodyFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: labelColor,
        ),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: idleBorder,
        enabledBorder: idleBorder,
        focusedBorder: border(focusBorder, 2),
        suffixIcon: state == _FieldState.correct
            ? Icon(Icons.check, color: c.successText)
            : null,
      ),
    );
  }
}

/// "Doesn't match" under the input. It always takes its place, so nothing
/// jumps when it appears.
class _MismatchHint extends StatelessWidget {
  const _MismatchHint({required this.visible, required this.text});

  final bool visible;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 24,
      child: visible
          ? Semantics(
              liveRegion: true,
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: bodyFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.errorText,
                ),
              ),
            )
          : null,
    );
  }
}

/// The right answer, with a countdown and a bar that runs out in [duration].
/// A new [revision] (help asked again) starts the countdown over.
class _HelpBox extends StatefulWidget {
  const _HelpBox({
    required this.text,
    required this.revision,
    required this.duration,
  });

  final String text;
  final int revision;
  final Duration duration;

  @override
  State<_HelpBox> createState() => _HelpBoxState();
}

class _HelpBoxState extends State<_HelpBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void didUpdateWidget(_HelpBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: AppCard(
        color: c.surfaceRaised,
        borderColor: c.highlight,
        borderRadius: AppRadii.choice,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final totalMs = widget.duration.inMilliseconds;
            final leftMs = (totalMs * (1 - _controller.value)).round();
            final ceiling = (leftMs / 1000).ceil();
            final seconds = ceiling < 1 ? 1 : ceiling;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          fontFamily: headingFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.i18n.typingHelpCountdown(seconds),
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 14,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 1 - _controller.value,
                    minHeight: 4,
                    backgroundColor: c.line,
                    color: c.highlight,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
