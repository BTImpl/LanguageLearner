import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_engine.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_providers.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_source.dart';
import 'package:languagelearner/features/photo_quiz/photo/widgets/photo_permission_message.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_quiz_header.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Where the quiz from a photo starts: tips and the two ways to get a photo,
/// the camera and the gallery.
///
/// A chosen photo goes to the [PhotoQuizController] and the processing screen
/// takes over. Cancelling the camera or the gallery changes nothing. A refused
/// permission, a missing camera or a photo that cannot be read is explained on
/// this screen.
class PhotoCaptureScreen extends ConsumerStatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen> {
  var _picking = false;
  PhotoPickResult? _problem;

  Future<void> _pick(PhotoOrigin origin) async {
    if (_picking) {
      return;
    }
    setState(() {
      _picking = true;
      _problem = null;
    });
    final result = await ref.read(photoSourceProvider).pick(origin);
    if (!mounted) {
      if (result is PhotoPicked) {
        unawaited(_deleteQuietly(result.file));
      }
      return;
    }
    setState(() => _picking = false);
    switch (result) {
      case PhotoPicked(:final file):
        unawaited(ref.read(photoQuizControllerProvider.notifier).start(file));
        context.go(AppRoutes.photoQuizProcessing);
      case PhotoPickCancelled():
        break;
      case PhotoPickPermissionDenied() ||
          PhotoPickCameraUnavailable() ||
          PhotoPickUnusable():
        setState(() => _problem = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final c = context.colors;
    final problem = _problem;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              PhotoQuizHeader(
                title: i18n.photoQuizTitle,
                onBack: () => context.go(AppRoutes.home),
                action: IconSquareButton(
                  icon: Icons.history,
                  semanticLabel: i18n.photoQuizSavedTitle,
                  onPressed: () => context.go(AppRoutes.photoQuizSaved),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: switch (problem) {
                    PhotoPickPermissionDenied(:final origin) =>
                      PhotoPermissionMessage(origin: origin),
                    _ => const _Intro(),
                  },
                ),
              ),
              if (problem is PhotoPickCameraUnavailable)
                _ProblemText(i18n.photoQuizNoCamera),
              if (problem is PhotoPickUnusable)
                _ProblemText(i18n.photoQuizUnusablePhoto),
              const SizedBox(height: 12),
              PrimaryButton(
                label: i18n.photoQuizTakePhoto,
                icon: Icons.photo_camera_outlined,
                onPressed: _picking
                    ? null
                    : () => unawaited(_pick(PhotoOrigin.camera)),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: i18n.photoQuizChooseFromGallery,
                icon: Icons.photo_library_outlined,
                onPressed: _picking
                    ? null
                    : () => unawaited(_pick(PhotoOrigin.gallery)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _deleteQuietly(File file) async {
  try {
    if (file.existsSync()) {
      await file.delete();
    }
  } on FileSystemException {
    // A temporary file that stays is cleaned up by the system.
  }
}

class _ProblemText extends StatelessWidget {
  const _ProblemText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: bodyFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: context.colors.errorNumber,
        ),
      ),
    );
  }
}

/// The picture, the headline and the tips.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          borderRadius: AppRadii.highlighted,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.document_scanner_outlined,
                    size: 96,
                    color: c.highlight,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                i18n.photoQuizCaptureHeadline,
                style: TextStyle(
                  fontFamily: headingFontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                i18n.photoQuizCaptureSubtitle,
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
        const SizedBox(height: 20),
        _Tip(i18n.photoQuizTipStraight),
        _Tip(i18n.photoQuizTipOnePage),
        _Tip(i18n.photoQuizTipPrivacy),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(Icons.check, size: 22, color: c.highlight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: bodyFontFamily,
                fontSize: 16,
                height: 1.35,
                color: c.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
