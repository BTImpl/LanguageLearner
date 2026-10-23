import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/services/system_settings_opener.dart';
import 'package:languagelearner/core/widgets/state_message.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_engine.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Tells the student that the app may not use the camera or the photos, and
/// offers to open the system settings to change that.
class PhotoPermissionMessage extends ConsumerWidget {
  const PhotoPermissionMessage({required this.origin, super.key});

  /// What the app was refused: the camera or the photos.
  final PhotoOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final camera = origin == PhotoOrigin.camera;
    return StateMessage(
      icon: camera ? Icons.no_photography_outlined : Icons.hide_image_outlined,
      title: camera
          ? i18n.photoPermissionCameraTitle
          : i18n.photoPermissionPhotosTitle,
      message: i18n.photoPermissionMessage,
      actionLabel: i18n.photoPermissionOpenSettings,
      onAction: () =>
          unawaited(ref.read(systemSettingsOpenerProvider).openAppSettings()),
    );
  }
}
