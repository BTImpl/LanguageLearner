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
    final c = context.colors;
    final pairs = ref.watch(settingsProvider.select((s) => s.pairsPerPage));
    final notifier = ref.read(settingsProvider.notifier);
    return SettingsSection(
      title: i18n.pairsPerPageTitle,
      hint: i18n.pairsPerPageHint(
        AppSettings.minPairsPerPage,
        AppSettings.maxPairsPerPage,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconSquareButton(
            icon: Icons.remove,
            semanticLabel: i18n.pairsFewer,
            backgroundColor: c.background,
            onPressed: pairs > AppSettings.minPairsPerPage
                ? () => unawaited(notifier.setPairsPerPage(pairs - 1))
                : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$pairs',
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
            semanticLabel: i18n.pairsMore,
            backgroundColor: c.background,
            onPressed: pairs < AppSettings.maxPairsPerPage
                ? () => unawaited(notifier.setPairsPerPage(pairs + 1))
                : null,
          ),
        ],
      ),
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
