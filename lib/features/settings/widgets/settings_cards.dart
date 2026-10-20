import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/core/widgets/segmented_toggle.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
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
