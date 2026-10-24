import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// An e-mail the student reviews and sends from the mail app.
class OutgoingEmail {
  const OutgoingEmail({
    required this.recipient,
    required this.subject,
    required this.body,
  });

  final String recipient;
  final String subject;

  /// Plain text.
  final String body;
}

/// What happened to an e-mail that was handed to the mail app. The app cannot
/// know whether the student really sent it.
enum EmailSendOutcome {
  /// The mail app took it (the student sent it, saved it, or the phone did
  /// not tell).
  handedOver,

  /// The student closed the mail editor without sending or saving.
  cancelled,
}

/// Why an e-mail could not be handed to the mail app.
enum EmailFailure {
  /// The phone has no mail app that can write the e-mail.
  noMailApp,

  /// Anything else.
  failed,
}

class EmailSendException implements Exception {
  const EmailSendException(this.failure);

  final EmailFailure failure;

  @override
  String toString() => 'EmailSendException($failure)';
}

/// Hands an e-mail to the mail app of the phone, behind an interface so a
/// test can fake it and the sending can later move to the backend.
abstract interface class EmailSender {
  /// Opens the mail editor with [email] and completes when it is closed.
  /// Throws an [EmailSendException] when the mail app cannot be opened.
  Future<EmailSendOutcome> send(OutgoingEmail email);
}

/// The `mailto:` link of [email]: the subject and the body are percent-encoded
/// as they are (a space is `%20`, a line break `%0A`), because many mail apps
/// show a `+` or glue the lines together when they get anything else.
Uri buildMailtoUri(OutgoingEmail email) {
  final subject = Uri.encodeComponent(email.subject);
  final body = Uri.encodeComponent(email.body);
  // The address is checked in the settings, so it is left as it is.
  return Uri.parse('mailto:${email.recipient}?subject=$subject&body=$body');
}

/// Opens the default mail app with the e-mail written, through a `mailto:`
/// link. The mail app does not tell whether the student sent it, so the
/// outcome is always "handed over".
class MailtoEmailSender implements EmailSender {
  const MailtoEmailSender();

  @override
  Future<EmailSendOutcome> send(OutgoingEmail email) async {
    final bool opened;
    try {
      opened = await launchUrl(buildMailtoUri(email));
    } on PlatformException {
      throw const EmailSendException(EmailFailure.failed);
    }
    if (!opened) {
      throw const EmailSendException(EmailFailure.noMailApp);
    }
    return EmailSendOutcome.handedOver;
  }
}

/// Sends e-mails through the mail app. Override it in tests with a fake.
final emailSenderProvider = Provider<EmailSender>(
  (ref) => const MailtoEmailSender(),
);
