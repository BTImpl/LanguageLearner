import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// The phone's own mail editor (`flutter_email_sender`).
class DeviceEmailSender implements EmailSender {
  const DeviceEmailSender();

  @override
  Future<EmailSendOutcome> send(OutgoingEmail email) async {
    try {
      final result = await FlutterEmailSender.send(
        Email(
          recipients: [email.recipient],
          subject: email.subject,
          body: email.body,
        ),
      );
      return result == EmailSendResult.cancelled
          ? EmailSendOutcome.cancelled
          : EmailSendOutcome.handedOver;
    } on FlutterEmailSenderNotAvailableException {
      throw const EmailSendException(EmailFailure.noMailApp);
    } on FlutterEmailSenderException {
      throw const EmailSendException(EmailFailure.failed);
    }
  }
}

/// Sends e-mails through the mail app. Override it in tests with a fake.
final emailSenderProvider = Provider<EmailSender>(
  (ref) => const DeviceEmailSender(),
);
