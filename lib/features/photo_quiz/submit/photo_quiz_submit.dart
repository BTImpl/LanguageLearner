import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/services/email_sender.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_answers.dart';
import 'package:languagelearner/features/photo_quiz/submit/quiz_email.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/i18n/app_localizations.dart';

/// Why the quiz could not be handed to the mail app.
enum SubmitFailure {
  /// The teacher's address is not set in the settings.
  noRecipient,

  /// The phone has no mail app.
  noMailApp,

  /// Anything else.
  failed,
}

/// Where the sending of the filled-in quiz stands.
sealed class PhotoQuizSubmitState {
  const PhotoQuizSubmitState();
}

/// Nothing is sent, or the student closed the mail editor without sending.
final class SubmitIdle extends PhotoQuizSubmitState {
  const SubmitIdle();
}

/// The mail editor is being opened or is open.
final class SubmitSending extends PhotoQuizSubmitState {
  const SubmitSending();
}

/// The e-mail was handed to the mail app. Not "arrived": the app cannot know
/// whether the student sent it.
final class SubmitSent extends PhotoQuizSubmitState {
  const SubmitSent();
}

/// The e-mail could not be handed over. The answers are kept.
final class SubmitFailed extends PhotoQuizSubmitState {
  const SubmitFailed(this.failure);

  final SubmitFailure failure;
}

/// The sending of the quiz to the teacher. It lives while the fill-in screen
/// is open.
final photoQuizSubmitProvider =
    NotifierProvider.autoDispose<PhotoQuizSubmit, PhotoQuizSubmitState>(
      PhotoQuizSubmit.new,
    );

class PhotoQuizSubmit extends Notifier<PhotoQuizSubmitState> {
  @override
  PhotoQuizSubmitState build() => const SubmitIdle();

  /// Writes the e-mail from [answers] in the language of [l10n] and hands it
  /// to the mail app, addressed to the teacher of the settings. Does nothing
  /// while a sending is going on.
  Future<void> submit({
    required PhotoQuizAnswers answers,
    required AppLocalizations l10n,
  }) async {
    if (state is SubmitSending) {
      return;
    }
    final recipient = ref.read(settingsProvider).teacherEmail;
    if (recipient.isEmpty) {
      state = const SubmitFailed(SubmitFailure.noRecipient);
      return;
    }
    final account = ref.read(accountProvider);
    final email = buildQuizEmail(
      l10n: l10n,
      quiz: answers.quiz,
      answers: answers,
      studentName: account?.name ?? '',
      studentEmail: account?.email ?? '',
      date: ref.read(clockProvider)(),
    );
    state = const SubmitSending();
    try {
      final outcome = await ref
          .read(emailSenderProvider)
          .send(
            OutgoingEmail(
              recipient: recipient,
              subject: email.subject,
              body: email.body,
            ),
          );
      if (!ref.mounted) {
        return;
      }
      state = outcome == EmailSendOutcome.cancelled
          ? const SubmitIdle()
          : const SubmitSent();
    } on EmailSendException catch (error) {
      if (ref.mounted) {
        state = SubmitFailed(switch (error.failure) {
          EmailFailure.noMailApp => SubmitFailure.noMailApp,
          EmailFailure.failed => SubmitFailure.failed,
        });
      }
    }
  }
}
