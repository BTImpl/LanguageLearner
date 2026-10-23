import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The limits of a photo sent to the backend.
abstract final class PhotoLimits {
  /// The longer side, in pixels. Printed text stays readable at this size.
  static const int maxSide = 2000;

  /// The JPEG quality of the first try, 1 to 100.
  static const int quality = 85;

  /// The backend accepts up to 8 MB; this leaves room for the request.
  static const int maxBytes = 7 * 1024 * 1024;
}

/// The bytes are not an image the app can read.
class UnreadablePhotoException implements Exception {
  const UnreadablePhotoException();

  @override
  String toString() => 'UnreadablePhotoException: not a readable image';
}

/// The photo cannot be made small enough, however much it is compressed.
class PhotoTooLargeException implements Exception {
  const PhotoTooLargeException();

  @override
  String toString() => 'PhotoTooLargeException: cannot fit the size limit';
}

/// The smallest longer side the shrinking goes down to.
const int _minSide = 300;

/// Makes the photo ready to upload: a JPEG, upright, whose longer side is at
/// most [maxSide] pixels and that is at most [maxBytes] big.
///
/// - The EXIF rotation is applied, so the photo is upright without any tag.
/// - A JPEG that already fits and is upright is returned as it is, so it is
///   not compressed twice.
/// - Otherwise it is encoded with [quality]. If that is still over [maxBytes]
///   the quality is lowered in steps, then the size is cut by a quarter, until
///   it fits.
///
/// It decodes the whole image, so call it off the UI thread for real photos.
///
/// Throws an [UnreadablePhotoException] when [bytes] is not a readable image
/// and a [PhotoTooLargeException] when it cannot fit [maxBytes].
Uint8List prepareJpeg(
  Uint8List bytes, {
  int maxSide = PhotoLimits.maxSide,
  int quality = PhotoLimits.quality,
  int maxBytes = PhotoLimits.maxBytes,
}) {
  final img.Image decoded;
  try {
    final result = img.decodeImage(bytes);
    if (result == null) {
      throw const UnreadablePhotoException();
    }
    decoded = result;
  } on UnreadablePhotoException {
    rethrow;
  } on Object {
    // Truncated or damaged files make the decoders throw.
    throw const UnreadablePhotoException();
  }

  final needsRotation = (decoded.exif.imageIfd.orientation ?? 1) != 1;
  var image = needsRotation ? img.bakeOrientation(decoded) : decoded;
  final fits = math.max(image.width, image.height) <= maxSide;
  if (fits &&
      !needsRotation &&
      bytes.length <= maxBytes &&
      img.findDecoderForData(bytes) is img.JpegDecoder) {
    return bytes;
  }
  if (!fits) {
    image = _resizeLongerSide(image, maxSide);
  }

  var currentQuality = quality;
  while (true) {
    final encoded = img.encodeJpg(image, quality: currentQuality);
    if (encoded.length <= maxBytes) {
      return encoded;
    }
    if (currentQuality > 40) {
      currentQuality = math.max(40, currentQuality - 15);
      continue;
    }
    final longer = math.max(image.width, image.height);
    if (longer <= _minSide) {
      throw const PhotoTooLargeException();
    }
    image = _resizeLongerSide(
      image,
      math.max(_minSide, (longer * 0.75).round()),
    );
  }
}

img.Image _resizeLongerSide(img.Image image, int side) => img.copyResize(
  image,
  width: image.width >= image.height ? side : null,
  height: image.height > image.width ? side : null,
);
