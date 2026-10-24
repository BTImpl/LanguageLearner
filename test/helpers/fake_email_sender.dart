import 'dart:async';

import 'package:languagelearner/core/services/email_sender.dart';

/// An [EmailSender] for tests: it keeps what was sent and can fail, be
/// cancelled or wait on demand.
class FakeEmailSender implements EmailSender {
  /// The e-mails handed over, oldest first.
  final List<OutgoingEmail> sent = [];

  /// When set, [send] throws it.
  EmailSendException? error;

  /// What [send] gives when it succeeds.
  EmailSendOutcome outcome = EmailSendOutcome.handedOver;

  /// When set, [send] waits for it (to look at the screen while sending).
  Completer<void>? gate;

  @override
  Future<EmailSendOutcome> send(OutgoingEmail email) async {
    sent.add(email);
    final wait = gate;
    if (wait != null) {
      await wait.future;
    }
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return outcome;
  }
}
