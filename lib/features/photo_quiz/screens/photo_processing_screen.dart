import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_quiz_failure_view.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_quiz_header.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Shown while the photo is read: a spinner, a short text and a cancel
/// button. It follows the [PhotoQuizController]:
///
/// - when the quiz is ready it opens the review screen on its own;
/// - when it failed it explains why and offers a new photo;
/// - without a running request (opened directly, or cancelled) it goes back
///   to the home screen.
///
/// The back button and the back gesture cancel, like the cancel button.
class PhotoProcessingScreen extends ConsumerStatefulWidget {
  const PhotoProcessingScreen({super.key});

  @override
  ConsumerState<PhotoProcessingScreen> createState() =>
      _PhotoProcessingScreenState();
}

class _PhotoProcessingScreenState extends ConsumerState<PhotoProcessingScreen> {
  var _leaving = false;

  void _goTo(String location) {
    if (_leaving) {
      return;
    }
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(location);
      }
    });
  }

  void _cancel() {
    ref.read(photoQuizControllerProvider.notifier).reset();
    _goTo(AppRoutes.home);
  }

  void _newPhoto() {
    ref.read(photoQuizControllerProvider.notifier).reset();
    _goTo(AppRoutes.photoQuiz);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final state = ref.watch(photoQuizControllerProvider);
    switch (state) {
      case PhotoQuizIdle():
        _goTo(AppRoutes.home);
      case PhotoQuizReady():
        _goTo(AppRoutes.photoQuizReview);
      case PhotoQuizLoading() || PhotoQuizFailed():
        break;
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _cancel();
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                PhotoQuizHeader(title: i18n.photoQuizTitle, onBack: _cancel),
                Expanded(
                  child: switch (state) {
                    PhotoQuizFailed(:final failure) => Center(
                      child: SingleChildScrollView(
                        child: PhotoQuizFailureView(
                          failure: failure,
                          onNewPhoto: _newPhoto,
                        ),
                      ),
                    ),
                    _ => const _Reading(),
                  },
                ),
                if (state is PhotoQuizLoading) ...[
                  SecondaryButton(
                    label: i18n.photoQuizCancel,
                    onPressed: _cancel,
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading();

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final c = context.colors;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: AppCard(
                borderRadius: AppRadii.highlighted,
                padding: const EdgeInsets.all(48),
                child: Icon(
                  Icons.description_outlined,
                  size: 96,
                  color: c.highlight,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: c.highlight,
                semanticsLabel: i18n.photoQuizProcessingTitle,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              i18n.photoQuizProcessingTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: headingFontFamily,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              i18n.photoQuizProcessingHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: bodyFontFamily,
                fontSize: 16,
                height: 1.4,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
