import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_progress_bar.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_exception.dart';
import 'package:languagelearner/i18n/app_localizations.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The key of the main button of the failure screen, for tests.
const Key photoFailurePrimaryKey = Key('photo-failure-primary');

/// The key of the quiet second button of the failure screen, for tests.
const Key photoFailureSecondaryKey = Key('photo-failure-secondary');

/// The explanation of why no quiz was made, with the way on, as in the
/// designs: a big icon, a title, the explanation and the buttons at the
/// bottom.
///
/// - an unreadable photo, or one that is too large or of a wrong type: a new
///   photo;
/// - a failure that may pass (no network, no answer in time, a service that
///   is not available): the same photo again ([canRetry]), or give up;
/// - the daily limit: back to the home screen, with how many quizzes were
///   used.
class PhotoQuizFailureView extends StatelessWidget {
  const PhotoQuizFailureView({
    required this.failure,
    required this.onNewPhoto,
    required this.onHome,
    this.onRetry,
    this.canRetry = false,
    this.resetsAt,
    this.limit,
    super.key,
  });

  final PhotoQuizFailure failure;

  /// Starts again with another photo.
  final VoidCallback onNewPhoto;

  /// Gives up and goes to the home screen.
  final VoidCallback onHome;

  /// Sends the same photo again; used when [canRetry].
  final VoidCallback? onRetry;

  /// Whether the photo is still there to be sent again.
  final bool canRetry;

  /// For the daily limit: when the count starts again (UTC), if known.
  final DateTime? resetsAt;

  /// For the daily limit: how many quizzes a day are allowed, if known.
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final retry = onRetry;
    final retryable = canRetry && retry != null;
    final (primary, secondary) = switch (failure) {
      PhotoQuizFailure.noQuestions => (
        _Action(i18n.photoQuizNewPhoto, onNewPhoto),
        _Action(i18n.back, onHome),
      ),
      PhotoQuizFailure.noNetwork ||
      PhotoQuizFailure.timeout ||
      PhotoQuizFailure.serviceUnavailable when retryable => (
        _Action(i18n.photoQuizRetry, retry),
        _Action(i18n.photoQuizCancel, onHome),
      ),
      PhotoQuizFailure.noNetwork ||
      PhotoQuizFailure.timeout ||
      PhotoQuizFailure.serviceUnavailable => (
        _Action(i18n.photoQuizNewPhoto, onNewPhoto),
        _Action(i18n.photoQuizCancel, onHome),
      ),
      PhotoQuizFailure.dailyLimit => (_Action(i18n.backToHome, onHome), null),
      _ => (_Action(i18n.photoQuizNewPhoto, onNewPhoto), null),
    };
    final resets = resetsAt;
    final allowed = limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: AppCard(
                      borderRadius: BorderRadius.circular(32),
                      color: c.surfaceRaised,
                      padding: const EdgeInsets.all(28),
                      child: Icon(_icon(failure), size: 44, color: c.highlight),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    photoQuizFailureTitle(i18n, failure),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: headingFontFamily,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    photoQuizFailureMessage(i18n, failure, limit: allowed),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: bodyFontFamily,
                      fontSize: 17,
                      height: 1.45,
                      color: c.textMuted,
                    ),
                  ),
                  if (failure == PhotoQuizFailure.dailyLimit) ...[
                    if (resets != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        i18n.photoQuizErrorDailyLimitResets(
                          formatLocalTime(resets),
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                    if (allowed != null) ...[
                      const SizedBox(height: 20),
                      _UsageCard(limit: allowed),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
        PrimaryButton(
          key: photoFailurePrimaryKey,
          label: primary.label,
          onPressed: primary.onPressed,
        ),
        if (secondary != null) ...[
          const SizedBox(height: 12),
          SecondaryButton(
            key: photoFailureSecondaryKey,
            label: secondary.label,
            onPressed: secondary.onPressed,
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

class _Action {
  const _Action(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}

/// "20 / 20 used today" with a full bar: every quiz of the day is used.
class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.i18n.photoQuizDailyUsage(limit, limit),
            style: TextStyle(
              fontFamily: bodyFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
          const SizedBox(height: 10),
          const AppProgressBar(value: 1),
        ],
      ),
    );
  }
}

IconData _icon(PhotoQuizFailure failure) => switch (failure) {
  PhotoQuizFailure.noNetwork => Icons.wifi_off_outlined,
  PhotoQuizFailure.noQuestions => Icons.find_in_page_outlined,
  PhotoQuizFailure.imageTooLarge ||
  PhotoQuizFailure.imageUnsupported => Icons.image_not_supported_outlined,
  PhotoQuizFailure.dailyLimit => Icons.schedule_outlined,
  PhotoQuizFailure.timeout => Icons.timer_off_outlined,
  _ => Icons.error_outline,
};

/// The heading for [failure].
String photoQuizFailureTitle(AppLocalizations i18n, PhotoQuizFailure failure) =>
    switch (failure) {
      PhotoQuizFailure.noQuestions => i18n.photoQuizErrorNoQuestionsTitle,
      PhotoQuizFailure.imageTooLarge ||
      PhotoQuizFailure.imageUnsupported => i18n.photoQuizErrorImageTitle,
      PhotoQuizFailure.noNetwork => i18n.photoQuizErrorNoNetworkTitle,
      PhotoQuizFailure.timeout => i18n.photoQuizErrorTimeoutTitle,
      PhotoQuizFailure.dailyLimit => i18n.photoQuizErrorDailyLimitTitle,
      PhotoQuizFailure.serviceUnavailable ||
      PhotoQuizFailure.unauthorized ||
      PhotoQuizFailure.studentNotFound ||
      PhotoQuizFailure.serverError => i18n.photoQuizErrorTitle,
    };

/// What to tell the student about [failure]. With the daily [limit] known the
/// limit error names it.
///
/// A refused sign-in ends in the sign-in screen, so it only gets the general
/// text.
String photoQuizFailureMessage(
  AppLocalizations i18n,
  PhotoQuizFailure failure, {
  int? limit,
}) => switch (failure) {
  PhotoQuizFailure.noQuestions => i18n.photoQuizErrorNoQuestions,
  PhotoQuizFailure.imageTooLarge => i18n.photoQuizErrorTooLarge,
  PhotoQuizFailure.imageUnsupported => i18n.photoQuizErrorUnsupported,
  PhotoQuizFailure.dailyLimit =>
    limit == null
        ? i18n.photoQuizErrorDailyLimit
        : i18n.photoQuizErrorDailyLimitMessage(limit),
  PhotoQuizFailure.serviceUnavailable => i18n.photoQuizErrorUnavailable,
  PhotoQuizFailure.noNetwork => i18n.photoQuizErrorNoNetwork,
  PhotoQuizFailure.timeout => i18n.photoQuizErrorTimeout,
  PhotoQuizFailure.unauthorized ||
  PhotoQuizFailure.studentNotFound ||
  PhotoQuizFailure.serverError => i18n.photoQuizErrorGeneral,
};

/// `2026-10-25 02:00`, the local time of [utc].
String formatLocalTime(DateTime utc) {
  final local = utc.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
