import 'package:flutter/material.dart';
import 'package:languagelearner/core/widgets/state_message.dart';
import 'package:languagelearner/features/photo_quiz/data/photo_quiz_exception.dart';
import 'package:languagelearner/i18n/app_localizations.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The explanation of why no quiz was made, with the way on: a new photo.
///
/// A first version: the full error screens of the design come with card
/// LL-57.
class PhotoQuizFailureView extends StatelessWidget {
  const PhotoQuizFailureView({
    required this.failure,
    required this.onNewPhoto,
    super.key,
  });

  final PhotoQuizFailure failure;
  final VoidCallback onNewPhoto;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return StateMessage(
      icon: _icon(failure),
      title: i18n.photoQuizErrorTitle,
      message: photoQuizFailureMessage(i18n, failure),
      actionLabel: i18n.photoQuizNewPhoto,
      onAction: onNewPhoto,
    );
  }
}

IconData _icon(PhotoQuizFailure failure) => switch (failure) {
  PhotoQuizFailure.noNetwork => Icons.wifi_off_outlined,
  PhotoQuizFailure.noQuestions => Icons.search_off_outlined,
  PhotoQuizFailure.imageUnsupported => Icons.image_not_supported_outlined,
  PhotoQuizFailure.dailyLimit => Icons.hourglass_bottom_outlined,
  PhotoQuizFailure.timeout => Icons.timer_off_outlined,
  _ => Icons.error_outline,
};

/// What to tell the student about [failure].
///
/// A refused sign-in ends in the sign-in screen, so it only gets the general
/// text.
String photoQuizFailureMessage(
  AppLocalizations i18n,
  PhotoQuizFailure failure,
) => switch (failure) {
  PhotoQuizFailure.noQuestions => i18n.photoQuizErrorNoQuestions,
  PhotoQuizFailure.imageTooLarge => i18n.photoQuizErrorTooLarge,
  PhotoQuizFailure.imageUnsupported => i18n.photoQuizErrorUnsupported,
  PhotoQuizFailure.dailyLimit => i18n.photoQuizErrorDailyLimit,
  PhotoQuizFailure.serviceUnavailable => i18n.photoQuizErrorUnavailable,
  PhotoQuizFailure.noNetwork => i18n.photoQuizErrorNoNetwork,
  PhotoQuizFailure.timeout => i18n.photoQuizErrorTimeout,
  PhotoQuizFailure.unauthorized ||
  PhotoQuizFailure.studentNotFound ||
  PhotoQuizFailure.serverError => i18n.photoQuizErrorGeneral,
};
