import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/features/settings/widgets/account_card.dart';
import 'package:languagelearner/features/settings/widgets/brand_footer.dart';
import 'package:languagelearner/features/settings/widgets/refresh_words_card.dart';
import 'package:languagelearner/features/settings/widgets/settings_cards.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The settings: account, languages, pairs per page, typing attempts,
/// appearance and the word list refresh.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenMargin,
            24,
            AppSizes.screenMargin,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.i18n.settingsTitle,
                style: TextStyle(
                  fontFamily: headingFontFamily,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: context.colors.text,
                ),
              ),
              const SizedBox(height: 20),
              const Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountCard(),
                  PromptLanguageCard(),
                  AppLanguageCard(),
                  PairsPerPageCard(),
                  TypingAttemptsCard(),
                  AppearanceCard(),
                  RefreshWordsCard(),
                ],
              ),
              const SizedBox(height: 32),
              const BrandFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
