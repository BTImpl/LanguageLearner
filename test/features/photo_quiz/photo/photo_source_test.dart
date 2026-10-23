import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:languagelearner/features/photo_quiz/photo/photo_compressor.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_engine.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_source.dart';

import '../../../helpers/fake_photo_engine.dart';

late Directory _dir;

/// Runs on the same isolate: a test needs no extra isolate.
Future<Uint8List> _prepareHere(Uint8List bytes) async => prepareJpeg(bytes);

File _writeImage(String name, {int width = 100, int height = 60}) {
  final file = File('${_dir.path}/$name');
  file.writeAsBytesSync(img.encodePng(img.Image(width: width, height: height)));
  return file;
}

DevicePhotoSource _source(FakePhotoEngine engine, Directory out) =>
    DevicePhotoSource(engine, tempDirectory: out, prepare: _prepareHere);

void main() {
  late Directory out;

  setUp(() {
    _dir = Directory.systemTemp.createTempSync('photo_source_in_');
    out = Directory.systemTemp.createTempSync('photo_source_out_');
    addTearDown(() {
      _dir.deleteSync(recursive: true);
      out.deleteSync(recursive: true);
    });
  });

  test('a picked photo comes back as a prepared JPEG file', () async {
    final original = _writeImage('picked.png');
    final engine = FakePhotoEngine(path: original.path);

    final result = await _source(engine, out).pick(PhotoOrigin.gallery);

    expect(engine.asked, [PhotoOrigin.gallery]);
    expect(result, isA<PhotoPicked>());
    final file = (result as PhotoPicked).file;
    expect(file.parent.path, out.path);
    final bytes = file.readAsBytesSync();
    expect(bytes[0], 0xFF); // JPEG
    expect(bytes[1], 0xD8);
    expect(img.decodeImage(bytes)!.width, 100);
  });

  test('the file the engine made is deleted', () async {
    final original = _writeImage('picked.png');

    await _source(
      FakePhotoEngine(path: original.path),
      out,
    ).pick(PhotoOrigin.camera);

    expect(original.existsSync(), isFalse);
  });

  test('every pick makes a file of its own', () async {
    final first = await _source(
      FakePhotoEngine(path: _writeImage('a.png').path),
      out,
    ).pick(PhotoOrigin.camera);
    final second = await _source(
      FakePhotoEngine(path: _writeImage('b.png').path),
      out,
    ).pick(PhotoOrigin.camera);

    expect(
      (first as PhotoPicked).file.path,
      isNot((second as PhotoPicked).file.path),
    );
  });

  test('cancelling is a result, not an error', () async {
    final result = await _source(
      FakePhotoEngine(),
      out,
    ).pick(PhotoOrigin.camera);

    expect(result, isA<PhotoPickCancelled>());
    expect(out.listSync(), isEmpty);
  });

  test('a refused permission says which access was refused', () async {
    for (final origin in PhotoOrigin.values) {
      final result = await _source(
        FakePhotoEngine(error: const PhotoPermissionDeniedException()),
        out,
      ).pick(origin);

      expect(result, isA<PhotoPickPermissionDenied>());
      expect((result as PhotoPickPermissionDenied).origin, origin);
    }
  });

  test('a missing camera is a result, not an error', () async {
    final result = await _source(
      FakePhotoEngine(error: const CameraUnavailableException()),
      out,
    ).pick(PhotoOrigin.camera);

    expect(result, isA<PhotoPickCameraUnavailable>());
  });

  test('a file that is not an image is unusable and still deleted', () async {
    final broken = File('${_dir.path}/broken.jpg')
      ..writeAsBytesSync([1, 2, 3, 4]);

    final result = await _source(
      FakePhotoEngine(path: broken.path),
      out,
    ).pick(PhotoOrigin.gallery);

    expect(result, isA<PhotoPickUnusable>());
    expect(broken.existsSync(), isFalse);
    expect(out.listSync(), isEmpty);
  });

  test('an unexpected engine error is not hidden', () async {
    final source = _source(FakePhotoEngine(error: StateError('boom')), out);

    expect(() => source.pick(PhotoOrigin.camera), throwsStateError);
  });
}
