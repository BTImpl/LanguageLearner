import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_quiz_header.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The place of the screen where the quiz is filled in (card LL-54): it only
/// says how many questions are left. Without a ready quiz it goes back to the
/// home screen.
class PhotoFillPlaceholderScreen extends ConsumerWidget {
  const PhotoFillPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final state = ref.watch(photoQuizControllerProvider);
    if (state is! PhotoQuizReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRoutes.home);
        }
      });
      return Scaffold(backgroundColor: context.colors.background);
    }
    final quiz = state.quiz;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenMargin,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              PhotoQuizHeader(
                title: quiz.title ?? i18n.photoQuizTitle,
                onBack: () => context.go(AppRoutes.photoQuizReview),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    i18n.photoQuizQuestionCount(quiz.questions.length),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: headingFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: context.colors.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
