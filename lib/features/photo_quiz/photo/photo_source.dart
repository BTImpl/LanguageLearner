import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:languagelearner/features/photo_quiz/photo/photo_compressor.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_engine.dart';
import 'package:uuid/uuid.dart';

/// What came of asking the student for a photo.
///
/// Every normal outcome is a value, not an exception: cancelling and a
/// refused permission are not errors.
sealed class PhotoPickResult {
  const PhotoPickResult();
}

/// A photo is ready to upload.
///
/// [file] is a temporary JPEG that the app made. Whoever gets it owns it and
/// deletes it when the photo is not needed any more.
final class PhotoPicked extends PhotoPickResult {
  const PhotoPicked(this.file);

  final File file;
}

/// The student closed the camera or the gallery without a photo.
final class PhotoPickCancelled extends PhotoPickResult {
  const PhotoPickCancelled();
}

/// The student (or the device) does not allow the access that [origin] needs.
/// The screen explains it and offers to open the system settings.
final class PhotoPickPermissionDenied extends PhotoPickResult {
  const PhotoPickPermissionDenied(this.origin);

  final PhotoOrigin origin;
}

/// There is no camera to use; the gallery still works.
final class PhotoPickCameraUnavailable extends PhotoPickResult {
  const PhotoPickCameraUnavailable();
}

/// The chosen file is not an image the app can read, or it cannot be made
/// small enough.
final class PhotoPickUnusable extends PhotoPickResult {
  const PhotoPickUnusable();
}

/// Takes or chooses a photo of a worksheet and makes it ready to upload.
abstract interface class PhotoSource {
  /// Opens the camera or the gallery. Does not throw for cancelling, a refused
  /// permission, a missing camera or an unreadable photo: see
  /// [PhotoPickResult].
  Future<PhotoPickResult> pick(PhotoOrigin origin);
}

/// Makes the picked photo ready to upload.
typedef PhotoPreparer = Future<Uint8List> Function(Uint8List bytes);

/// Resizes and compresses on another isolate, so the screen does not freeze.
Future<Uint8List> _prepareInBackground(Uint8List bytes) =>
    Isolate.run(() => prepareJpeg(bytes));

/// The [PhotoSource] of the app: asks the [PhotoEngine], then resizes and
/// compresses the photo (see [prepareJpeg]) into a new temporary file.
///
/// The file the engine made is deleted, whatever the outcome.
class DevicePhotoSource implements PhotoSource {
  DevicePhotoSource(
    this._engine, {
    Directory? tempDirectory,
    PhotoPreparer? prepare,
  }) : _tempDirectory = tempDirectory ?? Directory.systemTemp,
       _prepare = prepare ?? _prepareInBackground;

  final PhotoEngine _engine;
  final Directory _tempDirectory;
  final PhotoPreparer _prepare;
  final Uuid _uuid = const Uuid();

  @override
  Future<PhotoPickResult> pick(PhotoOrigin origin) async {
    final String? path;
    try {
      path = await _engine.pick(origin);
    } on PhotoPermissionDeniedException {
      return PhotoPickPermissionDenied(origin);
    } on CameraUnavailableException {
      return const PhotoPickCameraUnavailable();
    }
    if (path == null) {
      return const PhotoPickCancelled();
    }

    final original = File(path);
    try {
      final prepared = await _prepare(await original.readAsBytes());
      final result = File(
        '${_tempDirectory.path}/quiz-photo-${_uuid.v4()}.jpg',
      );
      await result.writeAsBytes(prepared, flush: true);
      return PhotoPicked(result);
    } on UnreadablePhotoException {
      return const PhotoPickUnusable();
    } on PhotoTooLargeException {
      return const PhotoPickUnusable();
    } finally {
      await _deleteQuietly(original);
    }
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
