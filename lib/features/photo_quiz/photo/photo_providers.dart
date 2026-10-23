import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/features/photo_quiz/photo/image_picker_photo_engine.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_engine.dart';
import 'package:languagelearner/features/photo_quiz/photo/photo_source.dart';

/// The photo picker of the device. Override it in tests with a fake.
final photoEngineProvider = Provider<PhotoEngine>(
  (ref) => ImagePickerPhotoEngine(),
);

/// Takes or chooses a photo of a worksheet. Override it in tests with a fake.
final photoSourceProvider = Provider<PhotoSource>(
  (ref) => DevicePhotoSource(ref.watch(photoEngineProvider)),
);
