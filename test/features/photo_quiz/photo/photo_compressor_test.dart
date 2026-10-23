import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:languagelearner/features/photo_quiz/photo/photo_compressor.dart';

/// An image of random pixels: it does not compress well, like a busy photo.
img.Image _noise(int width, int height) {
  final random = math.Random(7);
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  return image;
}

Uint8List _jpeg(img.Image image, {int quality = 90}) =>
    img.encodeJpg(image, quality: quality);

img.Image _decode(Uint8List bytes) => img.decodeImage(bytes)!;

bool _isJpeg(Uint8List bytes) => bytes[0] == 0xFF && bytes[1] == 0xD8;

void main() {
  test('a big photo is scaled to the longer side and keeps its shape', () {
    final source = _jpeg(_noise(900, 600));

    final result = prepareJpeg(source, maxSide: 300);

    final image = _decode(result);
    expect(_isJpeg(result), isTrue);
    expect(image.width, 300);
    expect(image.height, 200);
  });

  test('a portrait photo is scaled by its height', () {
    final result = prepareJpeg(_jpeg(_noise(600, 900)), maxSide: 300);

    final image = _decode(result);
    expect(image.width, 200);
    expect(image.height, 300);
  });

  test('a JPEG that already fits is returned as it is', () {
    final source = _jpeg(_noise(200, 100));

    final result = prepareJpeg(source);

    expect(result, same(source));
  });

  test('a PNG is turned into a JPEG', () {
    final png = img.encodePng(_noise(120, 80));

    final result = prepareJpeg(png);

    expect(_isJpeg(result), isTrue);
    expect(_decode(result).width, 120);
  });

  test('the EXIF rotation is applied', () {
    final image = _noise(40, 20);
    image.exif.imageIfd.orientation = 6; // rotated by 90 degrees
    final source = _jpeg(image);

    final result = prepareJpeg(source);

    final decoded = _decode(result);
    expect(decoded.width, 20);
    expect(decoded.height, 40);
    expect(decoded.exif.imageIfd.orientation ?? 1, 1);
  });

  test('a photo over the byte limit is compressed until it fits', () {
    final source = _jpeg(_noise(800, 600), quality: 100);
    const limit = 250 * 1024;
    expect(source.length, greaterThan(limit));

    final result = prepareJpeg(source, maxBytes: limit);

    expect(result.length, lessThanOrEqualTo(limit));
    expect(_decode(result).width, lessThanOrEqualTo(800));
  });

  test('a photo that cannot get small enough is refused', () {
    final source = _jpeg(_noise(400, 300));

    expect(
      () => prepareJpeg(source, maxBytes: 10),
      throwsA(isA<PhotoTooLargeException>()),
    );
  });

  test('bytes that are not an image are refused', () {
    expect(
      () => prepareJpeg(Uint8List.fromList([1, 2, 3, 4, 5])),
      throwsA(isA<UnreadablePhotoException>()),
    );
    expect(
      () => prepareJpeg(Uint8List(0)),
      throwsA(isA<UnreadablePhotoException>()),
    );
  });

  test('the default limits stay under the backend limit of 8 MB', () {
    expect(PhotoLimits.maxBytes, lessThan(8 * 1024 * 1024));
    expect(PhotoLimits.maxSide, 2000);
    expect(PhotoLimits.quality, 85);
  });
}
