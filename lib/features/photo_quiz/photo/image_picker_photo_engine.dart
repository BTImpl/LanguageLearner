import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_compressor.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_engine.dart';

/// The [PhotoEngine] of the app, on the `image_picker` plugin.
///
/// The plugin already scales the photo down and writes it as an upright JPEG,
/// so the photo that arrives in Dart is usually small. The gallery is opened
/// with the system photo picker, which needs no permission when the full
/// photo metadata is not requested.
class ImagePickerPhotoEngine implements PhotoEngine {
  ImagePickerPhotoEngine([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick(PhotoOrigin origin) async {
    try {
      final file = await _picker.pickImage(
        source: switch (origin) {
          PhotoOrigin.camera => ImageSource.camera,
          PhotoOrigin.gallery => ImageSource.gallery,
        },
        maxWidth: PhotoLimits.maxSide.toDouble(),
        maxHeight: PhotoLimits.maxSide.toDouble(),
        imageQuality: PhotoLimits.quality,
        requestFullMetadata: false,
      );
      return file?.path;
    } on PlatformException catch (e) {
      throw switch (e.code) {
        'camera_access_denied' ||
        'photo_access_denied' ||
        'camera_access_restricted' ||
        'photo_access_restricted' => const PhotoPermissionDeniedException(),
        'camera_unavailable' ||
        'invalid_source' => const CameraUnavailableException(),
        _ => e,
      };
    }
  }
}
