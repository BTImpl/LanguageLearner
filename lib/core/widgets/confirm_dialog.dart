import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';

/// Asks the student to confirm something and returns the answer: `true` for
/// the [confirmLabel] button, `false` for the [cancelLabel] button, for a tap
/// outside the dialog and for the system back gesture.
///
/// The [cancelLabel] button is the main (filled) one, so the safe choice is
/// the easy one; the [confirmLabel] button is the quiet one.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return confirmed ?? false;
}

/// The dialog of [showConfirmDialog]: a card in the colors of the app with a
/// large title and message and two full-width, 56 high buttons one under the
/// other (so long labels and large system text still fit). The content
/// scrolls when it does not fit the screen.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    super.key,
  });

  final String title;
  final String message;

  /// The quiet button; pops `true`.
  final String confirmLabel;

  /// The main button; pops `false`.
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenMargin,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: BorderSide(color: c.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: headingFontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: c.text,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontFamily: bodyFontFamily,
                  fontSize: 17,
                  height: 1.4,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: cancelLabel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
