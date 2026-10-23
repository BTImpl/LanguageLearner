/// Where a photo comes from.
enum PhotoOrigin { camera, gallery }

/// The student did not allow the app to use the camera or the photos (or the
/// device does not allow it, e.g. a restriction by a parent).
class PhotoPermissionDeniedException implements Exception {
  const PhotoPermissionDeniedException();

  @override
  String toString() => 'PhotoPermissionDeniedException';
}

/// The device has no camera that can be used (e.g. the iOS simulator).
class CameraUnavailableException implements Exception {
  const CameraUnavailableException();

  @override
  String toString() => 'CameraUnavailableException';
}

/// The photo picker behind the photo source: a thin interface over the
/// `image_picker` plugin, so the logic around it can be tested without a
/// device.
abstract interface class PhotoEngine {
  /// Opens the camera or the gallery and returns the path of the chosen
  /// image, or `null` when the student cancelled. The file is a temporary
  /// copy that the caller may delete.
  ///
  /// Throws a [PhotoPermissionDeniedException] or a
  /// [CameraUnavailableException]; nothing else for the normal cases.
  Future<String?> pick(PhotoOrigin origin);
}
