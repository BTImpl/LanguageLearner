import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Logo and app name on the left, refresh button and the account monogram
/// (opens the settings) on the right.
class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key});

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  var _refreshing = false;

  Future<void> _refresh() async {
    final messenger = ScaffoldMessenger.of(context);
    final failedText = context.i18n.refreshFailed;
    setState(() => _refreshing = true);
    try {
      await ref.read(refreshWordsProvider)();
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(failedText)));
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final account = ref.watch(accountProvider);
    return Row(
      children: [
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/branding/icon-512.png',
              width: 40,
              height: 40,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            i18n.appTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: headingFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
        ),
        IconSquareButton(
          icon: Icons.refresh,
          semanticLabel: i18n.refreshWordsTitle,
          loading: _refreshing,
          onPressed: () => unawaited(_refresh()),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: i18n.openSettings,
          excludeSemantics: true,
          child: Material(
            color: c.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go(AppRoutes.settings),
              child: SizedBox.square(
                dimension: AppSizes.touchTarget,
                child: Center(
                  child: Text(
                    account?.monogram ?? '?',
                    style: TextStyle(
                      fontFamily: headingFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
