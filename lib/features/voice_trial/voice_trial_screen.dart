import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/services/system_settings_opener.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/core/widgets/state_message.dart';
import 'package:languagelearner/features/voice_trial/answer_matcher.dart';
import 'package:languagelearner/features/voice_trial/speech_engine.dart';
import 'package:languagelearner/i18n/app_localizations.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The key of the microphone button, for tests.
const Key voiceTrialMicKey = Key('voice-trial-mic');

/// The key of the switch that gives the word list to the recogniser.
const Key voiceTrialHintsKey = Key('voice-trial-hints');

/// The key of the "next word" button.
const Key voiceTrialNextKey = Key('voice-trial-next');

/// The key of the result card.
const Key voiceTrialResultKey = Key('voice-trial-result');

/// The random numbers that pick the words. Override it in tests.
final voiceTrialRandomProvider = Provider<Random>((ref) => Random());

/// One logged attempt of the trial.
class _Attempt {
  const _Attempt({
    required this.expected,
    required this.heard,
    required this.decision,
    required this.hints,
    required this.at,
  });

  final String expected;
  final String heard;
  final MatchDecision decision;
  final bool hints;
  final DateTime at;
}

/// The experimental speaking trial (card LL-71): shows a Hungarian word, the
/// student says the English one, and the screen tells what the phone
/// recognised and whether the rule accepts it. It is a measuring tool and not
/// a pronunciation test.
///
/// The log lives on the screen only; nothing is sent over the network by the
/// app.
class VoiceTrialScreen extends ConsumerStatefulWidget {
  const VoiceTrialScreen({super.key});

  @override
  ConsumerState<VoiceTrialScreen> createState() => _VoiceTrialScreenState();
}

class _VoiceTrialScreenState extends ConsumerState<VoiceTrialScreen> {
  var _useHints = true;
  var _listening = false;
  var _partial = '';
  var _denied = false;
  var _unavailable = false;
  var _failed = false;
  List<WordPair>? _order;
  var _index = 0;
  _Attempt? _result;
  List<String> _alternatives = const [];
  final _log = <_Attempt>[];

  List<WordPair> _words(List<WordPair> deckWords) {
    return _order ??= ([...deckWords]
      ..shuffle(ref.read(voiceTrialRandomProvider)));
  }

  Future<void> _listen(WordPair word, List<WordPair> deckWords) async {
    final engine = ref.read(speechEngineProvider);
    await ref.read(ttsServiceProvider).stop();
    final access = await engine.requestAccess();
    if (!mounted) {
      return;
    }
    if (access != SpeechAccess.granted) {
      setState(() {
        _denied = access == SpeechAccess.denied;
        _unavailable = access == SpeechAccess.unavailable;
      });
      return;
    }
    setState(() {
      _listening = true;
      _partial = '';
      _failed = false;
      _denied = false;
      _unavailable = false;
      _result = null;
    });
    final hints = _useHints
        ? [for (final w in deckWords) ...w.acceptedEnglish]
        : const <String>[];
    try {
      final hearing = await engine.listen(
        hints: hints,
        onPartial: (text) {
          if (mounted) {
            setState(() => _partial = text);
          }
        },
      );
      if (!mounted) {
        return;
      }
      final decision = decideSpokenAnswer(
        expected: word.acceptedEnglish,
        heard: hearing.alternatives,
      );
      final attempt = _Attempt(
        expected: word.english,
        heard: hearing.alternatives.firstOrNull ?? '',
        decision: decision,
        hints: _useHints,
        at: ref.read(clockProvider)(),
      );
      setState(() {
        _listening = false;
        _result = attempt;
        _alternatives = hearing.alternatives.skip(1).toList();
        _log.insert(0, attempt);
      });
    } on SpeechException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _listening = false;
        _unavailable = e.code == 'unavailable';
        _failed = e.code != 'unavailable';
      });
    }
  }

  void _next(int count) {
    setState(() {
      _index = (_index + 1) % count;
      _result = null;
      _partial = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final deck = ref.watch(selectedDeckProvider).value;
    final deckWords = deck?.words ?? const <WordPair>[];
    final words = deckWords.isEmpty ? const <WordPair>[] : _words(deckWords);
    final word = words.isEmpty ? null : words[_index % words.length];
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenMargin,
            12,
            AppSizes.screenMargin,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Row(
                spacing: 12,
                children: [
                  IconSquareButton(
                    icon: Icons.arrow_back,
                    semanticLabel: i18n.back,
                    onPressed: () => context.go(AppRoutes.settings),
                  ),
                  Expanded(
                    child: Text(
                      i18n.voiceTrialTitle,
                      style: TextStyle(
                        fontFamily: headingFontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ),
                  _Badge(text: i18n.voiceTrialBadge),
                ],
              ),
              if (word == null)
                StateMessage(
                  icon: Icons.mic_off_outlined,
                  title: i18n.voiceTrialTitle,
                  message: i18n.voiceTrialNoWords,
                )
              else if (_denied)
                StateMessage(
                  icon: Icons.mic_off_outlined,
                  title: i18n.voiceTrialDeniedTitle,
                  message: i18n.voiceTrialDeniedMessage,
                  actionLabel: i18n.photoPermissionOpenSettings,
                  onAction: () => unawaited(
                    ref.read(systemSettingsOpenerProvider).openAppSettings(),
                  ),
                )
              else ...[
                _PromptCard(word: word),
                _HintsSwitch(
                  value: _useHints,
                  onChanged: _listening
                      ? null
                      : (value) => setState(() => _useHints = value),
                ),
                if (_unavailable)
                  _Note(text: i18n.voiceTrialUnavailable, error: true),
                if (_failed) _Note(text: i18n.voiceTrialFailed, error: true),
                if (_listening)
                  _ListeningCard(
                    partial: _partial,
                    onStop: () =>
                        unawaited(ref.read(speechEngineProvider).stop()),
                  )
                else if (_result case final result?)
                  _ResultCard(
                    attempt: result,
                    alternatives: _alternatives,
                    onNext: () => _next(words.length),
                  )
                else
                  PrimaryButton(
                    key: voiceTrialMicKey,
                    label: i18n.voiceTrialStart,
                    icon: Icons.mic,
                    onPressed: () => unawaited(_listen(word, deckWords)),
                  ),
              ],
              if (_log.isNotEmpty) _LogCard(log: _log),
              _Note(text: i18n.voiceTrialPrivacy),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: c.textMuted,
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.word});

  final WordPair word;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      borderRadius: AppRadii.card,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            context.i18n.voiceTrialPrompt,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textMuted,
            ),
          ),
          Text(
            word.hungarian,
            style: TextStyle(
              fontFamily: headingFontFamily,
              fontSize: 40,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintsSwitch extends StatelessWidget {
  const _HintsSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    return AppCard(
      borderRadius: AppRadii.card,
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  i18n.voiceTrialHintsTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                Text(
                  i18n.voiceTrialHintsHint,
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
              ],
            ),
          ),
          Switch(key: voiceTrialHintsKey, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 1.4,
        color: error ? c.errorText : c.textMuted,
      ),
    );
  }
}

class _ListeningCard extends StatelessWidget {
  const _ListeningCard({required this.partial, required this.onStop});

  final String partial;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    return AppCard(
      borderRadius: AppRadii.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 12,
        children: [
          Icon(Icons.mic, size: 40, color: c.primary),
          Text(
            i18n.voiceTrialListening,
            style: TextStyle(
              fontFamily: headingFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
          if (partial.isNotEmpty)
            Text(
              partial,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: c.text),
            ),
          OutlinedButton(onPressed: onStop, child: Text(i18n.voiceTrialStop)),
        ],
      ),
    );
  }
}

String _kindText(AppLocalizations i18n, MatchKind kind) {
  return switch (kind) {
    MatchKind.exact => i18n.voiceTrialKindExact,
    MatchKind.close => i18n.voiceTrialKindClose,
    MatchKind.homophone => i18n.voiceTrialKindHomophone,
    MatchKind.alternative => i18n.voiceTrialKindAlternative,
    MatchKind.none || MatchKind.nothing => '',
  };
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.attempt,
    required this.alternatives,
    required this.onNext,
  });

  final _Attempt attempt;
  final List<String> alternatives;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final ok = attempt.decision.accepted;
    final heard = attempt.heard.isEmpty
        ? i18n.voiceTrialNothing
        : attempt.heard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        AppCard(
          key: voiceTrialResultKey,
          borderRadius: AppRadii.card,
          color: ok ? c.successBackground : c.errorBackground,
          borderColor: ok ? c.successBorder : c.errorBorder,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(
                ok ? i18n.voiceTrialAccepted : i18n.voiceTrialRejected,
                style: TextStyle(
                  fontFamily: headingFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ok ? c.successText : c.errorText,
                ),
              ),
              if (ok)
                Text(
                  _kindText(i18n, attempt.decision.kind),
                  style: TextStyle(fontSize: 14, color: c.textMuted),
                ),
              const SizedBox(height: 4),
              Text(
                i18n.voiceTrialHeard,
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              Text(
                heard,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              if (alternatives.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  i18n.voiceTrialAlternatives,
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
                Text(
                  alternatives.join(' · '),
                  style: TextStyle(fontSize: 15, color: c.text),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                i18n.voiceTrialExpected(attempt.expected),
                style: TextStyle(fontSize: 14, color: c.textMuted),
              ),
            ],
          ),
        ),
        PrimaryButton(
          key: voiceTrialNextKey,
          label: i18n.voiceTrialNext,
          icon: Icons.arrow_forward,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});

  final List<_Attempt> log;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final accepted = log.where((a) => a.decision.accepted).length;
    return AppCard(
      borderRadius: AppRadii.card,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            i18n.voiceTrialLogTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
          Text(
            i18n.voiceTrialScore(accepted, log.length),
            style: TextStyle(fontSize: 14, color: c.textMuted),
          ),
          for (final attempt in log.take(30))
            Row(
              spacing: 8,
              children: [
                Icon(
                  attempt.decision.accepted ? Icons.check : Icons.close,
                  size: 18,
                  color: attempt.decision.accepted
                      ? c.successText
                      : c.errorText,
                ),
                Expanded(
                  child: Text(
                    '${attempt.expected} → '
                    '${attempt.heard.isEmpty ? '–' : attempt.heard} · '
                    '${attempt.hints ? i18n.voiceTrialLogWithHints : i18n.voiceTrialLogWithoutHints}',
                    style: TextStyle(fontSize: 13, color: c.text),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
