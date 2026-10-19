import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_state.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The sign-in screen: always on the dark background of the design, whatever
/// theme the app uses elsewhere.
///
/// Signing in successfully needs no navigation here: the router sends the
/// student to the home screen when the sign-in state changes.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  var _busy = false;
  var _failed = false;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await ref.read(authControllerProvider.notifier).signIn();
    } on Exception {
      // Cancelled or failed: the same message, the student just tries again.
      if (mounted) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentNotFound = switch (ref.watch(authControllerProvider)) {
      SignedOut(:final studentNotFound) => studentNotFound,
      SignedIn() => false,
    };
    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) => _body(context, studentNotFound: studentNotFound),
      ),
    );
  }

  Widget _body(BuildContext context, {required bool studentNotFound}) {
    final c = context.colors;
    final i18n = context.i18n;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenMargin,
                  24,
                  AppSizes.screenMargin,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: 112,
                              height: 112,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: c.line),
                              ),
                              child: Image.asset(
                                'assets/branding/icon-512.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            i18n.appTitle,
                            style: TextStyle(
                              fontFamily: headingFontFamily,
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              studentNotFound
                                  ? i18n.signInStudentNotFound
                                  : i18n.signInPrompt,
                              style: TextStyle(
                                fontFamily: bodyFontFamily,
                                fontSize: 17,
                                height: 1.45,
                                color: c.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PrimaryButton(
                      label: studentNotFound
                          ? i18n.signInOtherAccount
                          : i18n.signInButton,
                      loading: _busy,
                      onPressed: _busy ? null : () => unawaited(_signIn()),
                    ),
                    if (_failed) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Center(
                          child: Text(
                            i18n.signInFailed,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: bodyFontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.errorNumber,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'btimpl.eu',
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 14,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
