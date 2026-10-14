import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/auth/account.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The signed-in student: round monogram, name, e-mail address (cut off when
/// too long) and a sign-out button.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final account = ref.watch(accountProvider);
    return AppCard(
      borderRadius: AppRadii.card,
      child: Row(
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 22,
              backgroundColor: c.primary,
              child: Text(
                account.monogram,
                style: TextStyle(
                  fontFamily: headingFontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: bodyFontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: bodyFontFamily,
                    fontSize: 14,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SecondaryButton(
            label: context.i18n.signOut,
            compact: true,
            color: c.background,
            // Signing out comes with the Google sign-in (card LL-27).
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
