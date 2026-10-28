import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/settings/widgets/settings_section.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The key of the button that opens the speaking trial, for tests.
const Key voiceTrialOpenKey = Key('voice-trial-open');

/// Opens the experimental speaking trial (card LL-71).
class VoiceTrialCard extends StatelessWidget {
  const VoiceTrialCard({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return SettingsSection(
      title: i18n.voiceTrialSettingsTitle,
      hint: i18n.voiceTrialSettingsHint,
      child: PrimaryButton(
        key: voiceTrialOpenKey,
        label: i18n.voiceTrialOpen,
        icon: Icons.mic_none,
        onPressed: () => context.go(AppRoutes.voiceTrial),
      ),
    );
  }
}
