import 'dart:io';

import 'package:flutter/material.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/features/face_analysis/models/selected_photo.dart';
import 'package:glowai/features/face_analysis/services/camera_service.dart';
import 'package:glowai/features/face_analysis/services/face_validation_service.dart';
import 'package:glowai/features/face_analysis/services/gallery_picker_service.dart';
import 'package:glowai/features/face_analysis/services/heic_converter.dart';
import 'package:image/image.dart' as img;

import '../fixtures/heic_fixtures.dart';

/// Writes real image files into a temp folder, so validation tests exercise
/// the actual file contents (not mocks).
class TestImages {
  TestImages() : dir = Directory.systemTemp.createTempSync('glowai_test_');

  final Directory dir;

  String _write(String name, List<int> bytes) {
    final file = File('${dir.path}/$name')..writeAsBytesSync(bytes);
    return file.path;
  }

  String png(String name, {int width = 600, int height = 600}) =>
      _write(name, img.encodePng(img.Image(width: width, height: height)));

  String jpg(String name, {int width = 600, int height = 600}) => _write(
    name,
    img.encodeJpg(img.Image(width: width, height: height), quality: 85),
  );

  /// Plain text pretending to be an image (named .jpg on purpose).
  String notAnImage(String name) =>
      _write(name, 'this is not a photo'.codeUnits);

  /// Starts like a PNG/JPEG but the rest is garbage.
  String corruptedPng(String name) => _write(name, [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    ...List.filled(300, 7),
  ]);

  String corruptedJpg(String name) =>
      _write(name, [0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(300, 7)]);

  /// A REAL 800 x 600 HEIC file (HEVC in a HEIF container), not a renamed
  /// JPEG. See test/fixtures/heic_fixtures.dart.
  String heic(String name) => _write(name, landscapeHeicBytes());

  /// A real HEIC that decodes but is only 300 x 300.
  String smallHeic(String name) => _write(name, smallHeicBytes());

  /// A valid HEIF header (so it is recognised as HEIC) followed by garbage:
  /// no decoder can open it.
  String corruptedHeic(String name) =>
      _write(name, [..._ftyp('heic', ['mif1', 'heic']), ...List.filled(300, 7)]);

  /// Only an `ftyp` box with the given brands, to test format detection.
  String ftypOnly(String name, String major, [List<String> compatible = const []]) =>
      _write(name, [..._ftyp(major, compatible), ...List.filled(64, 0)]);

  static List<int> _ftyp(String major, List<String> compatible) {
    final size = 16 + compatible.length * 4;
    return [
      0, 0, 0, size,
      ...'ftyp'.codeUnits,
      ...major.codeUnits,
      0, 0, 0, 0,
      for (final brand in compatible) ...brand.codeUnits,
    ];
  }

  String empty(String name) => _write(name, const []);

  String missing(String name) => '${dir.path}/$name';

  void dispose() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {
      return;
    }
  }
}

// -------------------------------------------------------------------- fakes

/// Stands in for the platform decoder, which doesn't exist in `flutter test`.
/// By default it "converts" by writing a valid JPEG of [width] x [height] to
/// the temp folder. The real conversion is covered by the integration test.
class FakeHeicConverter implements HeicConverter {
  FakeHeicConverter({
    this.width = 800,
    this.height = 600,
    this.error,
    this.outputBytes,
  });

  final int width;
  final int height;

  /// Thrown instead of converting.
  final Object? error;

  /// Written as the "converted" file instead of a generated JPEG.
  final List<int>? outputBytes;

  final List<String> sources = [];
  final List<String> outputs = [];

  @override
  Future<String> convertToJpeg(String sourcePath) async {
    sources.add(sourcePath);
    if (error != null) throw error!;
    final file = File(
      '${Directory.systemTemp.path}/fake_converted_'
      '${sources.length}_${DateTime.now().microsecondsSinceEpoch}.jpg',
    )..writeAsBytesSync(
        outputBytes ??
            img.encodeJpg(img.Image(width: width, height: height), quality: 85),
      );
    outputs.add(file.path);
    return file.path;
  }
}

class FakeGalleryPicker implements GalleryPicker {
  FakeGalleryPicker(List<String?> results, {this.error})
    : _results = List.of(results);

  final List<String?> _results;
  final Object? error;
  int calls = 0;

  @override
  Future<String?> pickImagePath() async {
    calls++;
    if (error != null) throw error!;
    if (_results.isEmpty) return null;
    return _results.removeAt(0);
  }
}

class FakeCameraPermissionService implements CameraPermissionService {
  FakeCameraPermissionService(this.status);

  CameraPermissionStatus status;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<CameraPermissionStatus> requestCameraPermission() async {
    requests++;
    return status;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

class FakeCameraSession implements CameraSession {
  FakeCameraSession(this.capturePath);

  final String capturePath;
  int pictures = 0;
  bool disposed = false;

  @override
  Widget buildPreview({Widget? overlay}) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(
            key: Key('fake-camera-preview'),
            color: Colors.black,
          ),
          ?overlay,
        ],
      ),
    );
  }

  @override
  Future<String> takePicture() async {
    pictures++;
    return capturePath;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeCameraService implements CameraService {
  FakeCameraService({this.capturePath, this.error});

  final String? capturePath;
  final Object? error;
  int opens = 0;

  @override
  Future<CameraSession> openFrontCamera() async {
    opens++;
    if (error != null) throw error!;
    return FakeCameraSession(capturePath!);
  }
}

class FakeFaceValidationService implements FaceValidationService {
  FakeFaceValidationService(this.result);

  final FaceValidationResult result;
  int calls = 0;

  @override
  Future<FaceValidationResult> validate(SelectedPhoto photo) async {
    calls++;
    return result;
  }
}
