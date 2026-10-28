import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/core/widgets/segmented_toggle.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/email_validator.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/features/settings/widgets/settings_section.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Which language the app asks in.
class PromptLanguageCard extends ConsumerWidget {
  const PromptLanguageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final selected = ref.watch(
      settingsProvider.select((s) => s.promptLanguage),
    );
    return SettingsSection(
      title: i18n.promptLanguageTitle,
      hint: selected == PromptLanguage.english
          ? i18n.promptLanguageHintEnglish
          : i18n.promptLanguageHintHungarian,
      child: SegmentedToggle<PromptLanguage>(
        selected: selected,
        onChanged: (value) => unawaited(
          ref.read(settingsProvider.notifier).setPromptLanguage(value),
        ),
        options: [
          SegmentOption(
            value: PromptLanguage.english,
            label: i18n.promptLanguageEnglish,
          ),
          SegmentOption(
            value: PromptLanguage.hungarian,
            label: i18n.promptLanguageHungarian,
          ),
        ],
      ),
    );
  }
}

/// The language of the app interface.
class AppLanguageCard extends ConsumerWidget {
  const AppLanguageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final selected = ref.watch(settingsProvider.select((s) => s.appLanguage));
    return SettingsSection(
      title: i18n.appLanguageTitle,
      hint: i18n.appLanguageHint,
      child: SegmentedToggle<AppLanguage>(
        selected: selected,
        onChanged: (value) => unawaited(
          ref.read(settingsProvider.notifier).setAppLanguage(value),
        ),
        options: [
          SegmentOption(
            value: AppLanguage.system,
            label: i18n.appLanguageSystem,
          ),
          // Language names stay in their own language, they are not
          // translated.
          const SegmentOption(value: AppLanguage.en, label: 'English'),
          const SegmentOption(value: AppLanguage.hu, label: 'Magyar'),
        ],
      ),
    );
  }
}

/// How many pairs a page of the matching game shows.
class PairsPerPageCard extends ConsumerWidget {
  const PairsPerPageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final pairs = ref.watch(settingsProvider.select((s) => s.pairsPerPage));
    final notifier = ref.read(settingsProvider.notifier);
    return SettingsSection(
      title: i18n.pairsPerPageTitle,
      hint: i18n.pairsPerPageHint(
        AppSettings.minPairsPerPage,
        AppSettings.maxPairsPerPage,
      ),
      trailing: _CountStepper(
        value: pairs,
        min: AppSettings.minPairsPerPage,
        max: AppSettings.maxPairsPerPage,
        fewerLabel: i18n.pairsFewer,
        moreLabel: i18n.pairsMore,
        onChanged: (value) => unawaited(notifier.setPairsPerPage(value)),
      ),
    );
  }
}

/// How many wrong answers a written question accepts before it moves on.
class TypingAttemptsCard extends ConsumerWidget {
  const TypingAttemptsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final attempts = ref.watch(
      settingsProvider.select((s) => s.typingAttempts),
    );
    final notifier = ref.read(settingsProvider.notifier);
    return SettingsSection(
      title: i18n.typingAttemptsTitle,
      hint: i18n.typingAttemptsHint,
      trailing: _CountStepper(
        value: attempts,
        min: AppSettings.minTypingAttempts,
        max: AppSettings.maxTypingAttempts,
        fewerLabel: i18n.typingAttemptsFewer,
        moreLabel: i18n.typingAttemptsMore,
        onChanged: (value) => unawaited(notifier.setTypingAttempts(value)),
      ),
    );
  }
}

/// A number with a minus and a plus button, stopping at [min] and [max].
class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.fewerLabel,
    required this.moreLabel,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final String fewerLabel;
  final String moreLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconSquareButton(
          icon: Icons.remove,
          semanticLabel: fewerLabel,
          backgroundColor: c.background,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: headingFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
        ),
        IconSquareButton(
          icon: Icons.add,
          semanticLabel: moreLabel,
          backgroundColor: c.background,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

/// Dark or light theme.
class AppearanceCard extends ConsumerWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final selected = ref.watch(settingsProvider.select((s) => s.themeChoice));
    return SettingsSection(
      title: i18n.appearanceTitle,
      child: SegmentedToggle<ThemeChoice>(
        selected: selected,
        onChanged: (value) => unawaited(
          ref.read(settingsProvider.notifier).setThemeChoice(value),
        ),
        options: [
          SegmentOption(
            value: ThemeChoice.dark,
            label: i18n.themeDark,
            icon: Icons.dark_mode_outlined,
          ),
          SegmentOption(
            value: ThemeChoice.light,
            label: i18n.themeLight,
            icon: Icons.light_mode_outlined,
          ),
        ],
      ),
    );
  }
}

/// The e-mail address the filled-in photo quizzes are sent to.
///
/// An address (or no address) is saved as it is typed. While the text is not a
/// valid address nothing is saved, so the earlier address stays. The error is
/// shown once the student has left the field, so it does not appear in the
/// middle of typing; from then on it follows every change.
class TeacherEmailCard extends ConsumerStatefulWidget {
  const TeacherEmailCard({super.key});

  @override
  ConsumerState<TeacherEmailCard> createState() => _TeacherEmailCardState();
}

class _TeacherEmailCardState extends ConsumerState<TeacherEmailCard> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasLeftField = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(settingsProvider).teacherEmail,
    );
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Empty is allowed: the quiz is then not sent (card LL-56).
  bool get _isAcceptable {
    final text = _controller.text.trim();
    return text.isEmpty || isValidEmail(text);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && !_hasLeftField) {
      setState(() => _hasLeftField = true);
    }
  }

  void _onChanged(String text) {
    // The error depends on the text.
    setState(() {});
    if (_isAcceptable) {
      unawaited(ref.read(settingsProvider.notifier).setTeacherEmail(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final c = context.colors;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: AppRadii.choice,
      borderSide: BorderSide(color: color, width: width),
    );
    return SettingsSection(
      title: i18n.teacherEmailTitle,
      hint: i18n.teacherEmailHint,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
        onChanged: _onChanged,
        style: TextStyle(
          fontFamily: bodyFontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: c.text,
        ),
        cursorColor: c.highlight,
        decoration: InputDecoration(
          // Shown inside the empty field and read out by screen readers.
          labelText: i18n.teacherEmailLabel,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: TextStyle(
            fontFamily: bodyFontFamily,
            fontSize: 17,
            color: c.textMuted,
          ),
          errorText: _hasLeftField && !_isAcceptable
              ? i18n.teacherEmailError
              : null,
          errorMaxLines: 2,
          errorStyle: TextStyle(
            fontFamily: bodyFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: c.errorNumber,
          ),
          prefixIcon: Icon(Icons.mail_outline, color: c.textMuted),
          filled: true,
          fillColor: c.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: border(c.line, 1),
          enabledBorder: border(c.line, 1),
          focusedBorder: border(c.highlight, 2),
          errorBorder: border(c.errorBorder, 2),
          focusedErrorBorder: border(c.errorBorder, 2),
        ),
      ),
    );
  }
}

/// Whether the speaking game gives the words of the deck to the recogniser.
class SpeakingHintsCard extends ConsumerWidget {
  const SpeakingHintsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final on = ref.watch(settingsProvider.select((s) => s.speakingHints));
    return SettingsSection(
      title: i18n.speakingHintsTitle,
      hint: i18n.speakingHintsHint,
      trailing: Semantics(
        label: i18n.speakingHintsTitle,
        child: Switch(
          value: on,
          onChanged: (value) => unawaited(
            ref.read(settingsProvider.notifier).setSpeakingHints(value: value),
          ),
        ),
      ),
    );
  }
}

/// Whether the Mix mode may draw speaking tasks.
class MixSpeakingCard extends ConsumerWidget {
  const MixSpeakingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final on = ref.watch(settingsProvider.select((s) => s.mixSpeaking));
    return SettingsSection(
      title: i18n.mixSpeakingTitle,
      hint: i18n.mixSpeakingHint,
      trailing: Semantics(
        label: i18n.mixSpeakingTitle,
        child: Switch(
          value: on,
          onChanged: (value) => unawaited(
            ref.read(settingsProvider.notifier).setMixSpeaking(value: value),
          ),
        ),
      ),
    );
  }
}
