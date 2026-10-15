import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/play/typing/typing_game.dart';
import 'package:languagelearner/features/play/widgets/question_card.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The exact-match mode: a word is asked and the answer must be typed.
class TypingScreen extends ConsumerStatefulWidget {
  const TypingScreen({super.key});

  @override
  ConsumerState<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends ConsumerState<TypingScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  TypingGame? _game;
  late Deck _deck;
  var _finished = false;

  /// Whether the last check was wrong and the text has not been edited since.
  var _mismatch = false;

  TypingGame? _gameFor(Deck? deck) {
    if (_game == null && deck != null && deck.words.isNotEmpty) {
      _deck = deck;
      final session = RoundSession(
        words: deck.words,
        promptLanguage: ref.read(settingsProvider).promptLanguage,
        random: ref.read(roundRandomProvider),
        now: ref.read(clockProvider),
      );
      _game = TypingGame(session: session)..addListener(_onChanged);
    }
    return _game;
  }

  void _onChanged() {
    if (!mounted) {
      return;
    }
    final game = _game!;
    if (game.isFinished) {
      if (!_finished) {
        _finished = true;
        _openSummary(game);
      }
      return;
    }
    setState(() {});
  }

  void _openSummary(TypingGame game) {
    final i18n = context.i18n;
    final session = game.session;
    final result = game.result;
    // The words that were not right at the first attempt, in round order.
    final review = {...result.helpedWords, ...result.missedWords};
    final data = RoundSummaryData(
      modeName: PlayMode.typing.title(context),
      deckName: _deck.name,
      headline: i18n.firstTryHeadline(result.total, result.firstTry),
      stats: [
        SummaryStat(
          value: '${result.firstTry}',
          label: i18n.statCorrectFirst,
          tone: StatTone.success,
        ),
        SummaryStat(value: '${result.withHelp}', label: i18n.statWithHelp),
        SummaryStat(
          value: '${result.wrongFirst}',
          label: i18n.statWrongFirst,
          tone: StatTone.error,
        ),
      ],
      reviewWords: [
        for (final word in session.words)
          if (review.contains(word))
            ReviewWord(
              prompt: session.promptText(word),
              answer: session.answerText(word),
            ),
      ],
      restartLabel: i18n.restartTyping,
      restartLocation: AppRoutes.play(PlayMode.typing),
    );
    context.go(AppRoutes.summary(PlayMode.typing), extra: data);
  }

  /// "Check" and the send key of the keyboard: checks the answer, or moves on
  /// when it is already right.
  void _submit(TypingGame game) {
    if (game.isSolved) {
      _next(game);
      return;
    }
    final result = game.submit(_controller.text);
    switch (result) {
      case SubmitResult.correct:
        HapticFeedback.lightImpact().ignore();
        setState(() => _mismatch = false);
      case SubmitResult.wrong:
        HapticFeedback.heavyImpact().ignore();
        setState(() => _mismatch = true);
      case SubmitResult.ignored:
        break;
    }
  }

  void _next(TypingGame game) {
    _controller.clear();
    _mismatch = false;
    game.next();
    _focus.requestFocus();
  }

  void _readAloud(WordPair word) {
    ref.read(ttsServiceProvider).speak(word.english).ignore();
  }

  @override
  void dispose() {
    _game?.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(selectedDeckProvider).value;
    final game = _gameFor(deck);
    final title = PlayMode.typing.title(context);
    void goHome() => context.go(AppRoutes.home);

    final word = game?.current;
    if (game == null || word == null) {
      return GameScaffold(
        title: title,
        counter: '',
        progress: game == null ? 0 : 1,
        onBack: goHome,
        child: const SizedBox.shrink(),
      );
    }

    final i18n = context.i18n;
    final session = game.session;
    final solved = game.isSolved;
    final isLast = game.index == game.total - 1;
    final fieldState = solved
        ? _FieldState.correct
        : (_mismatch ? _FieldState.wrong : _FieldState.idle);

    return GameScaffold(
      title: title,
      counter: '${game.index + 1} / ${game.total}',
      progress: (game.index + 1) / game.total,
      onBack: goHome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Only this part scrolls, so the buttons stay above the keyboard.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuestionCard(
                    label: session.promptIsEnglish
                        ? i18n.typingWriteHungarian
                        : i18n.typingWriteEnglish,
                    text: session.promptText(word),
                    onReadAloud: session.promptIsEnglish
                        ? () => _readAloud(word)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _AnswerField(
                    controller: _controller,
                    focusNode: _focus,
                    state: fieldState,
                    onChanged: (_) {
                      if (_mismatch) {
                        setState(() => _mismatch = false);
                      }
                    },
                    onSubmit: () => _submit(game),
                  ),
                  const SizedBox(height: 12),
                  _MismatchHint(visible: fieldState == _FieldState.wrong),
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
                  onPressed: solved ? null : game.requestHelp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: solved
                      ? (isLast ? i18n.finish : i18n.next)
                      : i18n.typingCheck,
                  onPressed: () => _submit(game),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
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
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final _FieldState state;
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
        if (state == _FieldState.correct)
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
  const _MismatchHint({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 24,
      child: visible
          ? Semantics(
              liveRegion: true,
              child: Text(
                context.i18n.typingMismatch,
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
