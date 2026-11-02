// Runs the REAL Android/iOS HEIC decoder on REAL HEIC files, which
// `flutter test` can't do (it has no platform plugins). Run it on an Android
// emulator or device (Android 9 / API 28 or newer, which is when Android
// gained HEIC decoding):
//
//   flutter test integration_test/heic_conversion_test.dart -d <device-id>
//
// Needs `integration_test` (sdk: flutter) under dev_dependencies.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/features/face_analysis/models/selected_photo.dart';
import 'package:glowai/features/face_analysis/services/heic_converter.dart';
import 'package:glowai/features/face_analysis/services/image_validation_service.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fixtures/heic_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('glowai_heic_'));
  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  String write(String name, List<int> bytes) =>
      (File('${dir.path}/$name')..writeAsBytesSync(bytes)).path;

  /// RGBA of the decoded image, to check colours at known positions.
  Future<({int width, int height, ByteData rgba})> decode(String path) async {
    final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
    final image = (await codec.getNextFrame()).image;
    final rgba = (await image.toByteData())!;
    final result = (width: image.width, height: image.height, rgba: rgba);
    image.dispose();
    codec.dispose();
    return result;
  }

  (int, int, int) pixel(
    ({int width, int height, ByteData rgba}) image,
    int x,
    int y,
  ) {
    final i = (y * image.width + x) * 4;
    return (
      image.rgba.getUint8(i),
      image.rgba.getUint8(i + 1),
      image.rgba.getUint8(i + 2),
    );
  }

  testWidgets('a real HEIC becomes an upright, full-size JPEG', (tester) async {
    await tester.runAsync(() async {
      final source = write('IMG_0001.HEIC', landscapeHeicBytes());

      final jpegPath = await const PluginHeicConverter().convertToJpeg(source);

      expect(jpegPath, isNot(source));
      final bytes = File(jpegPath).readAsBytesSync();
      expect(bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF], reason: 'JPEG header');
      expect(bytes, isNot(landscapeHeicBytes()), reason: 'really re-encoded');

      final image = await decode(jpegPath);
      // Same size and aspect ratio (still landscape, not rotated or resized).
      expect(image.width, 800);
      expect(image.height, 600);

      // Orientation: red top-left, green top-right, blue bottom-left,
      // yellow bottom-right (sampled away from the block edges).
      final topLeft = pixel(image, 100, 100);
      final topRight = pixel(image, 700, 100);
      final bottomLeft = pixel(image, 100, 500);
      final bottomRight = pixel(image, 700, 500);
      expect(topLeft.$1, greaterThan(160));
      expect(topLeft.$2, lessThan(100));
      expect(topRight.$2, greaterThan(150));
      expect(topRight.$1, lessThan(100));
      expect(bottomLeft.$3, greaterThan(160));
      expect(bottomLeft.$1, lessThan(100));
      expect(bottomRight.$1, greaterThan(180));
      expect(bottomRight.$2, greaterThan(160));
      expect(bottomRight.$3, lessThan(110));

      // The source is untouched.
      expect(File(source).readAsBytesSync(), landscapeHeicBytes());
    });
  });

  testWidgets('validation accepts a real HEIC end to end', (tester) async {
    await tester.runAsync(() async {
      final source = write('photo.heif', landscapeHeicBytes());

      final result = await const ImageValidationService().validate(
        source,
        source: PhotoSource.gallery,
      );

      expect(result.error, isNull);
      final photo = result.photo!;
      expect(photo.convertedFromHeif, isTrue);
      expect(photo.format, PhotoFormat.jpeg);
      expect(photo.path, isNot(source));
      expect(photo.width, 800);
      expect(photo.height, 600);
      expect(photo.sizeInBytes, File(photo.path).lengthSync());
    });
  });

  testWidgets('a real but too-small HEIC is rejected after conversion',
      (tester) async {
    await tester.runAsync(() async {
      final result = await const ImageValidationService().validate(
        write('small.heic', smallHeicBytes()),
        source: PhotoSource.gallery,
      );
      expect(result.error, ImageValidationError.tooSmall);
    });
  });

  testWidgets('a corrupted HEIC fails with the friendly error', (tester) async {
    await tester.runAsync(() async {
      // Valid HEIC header, then garbage: the real decoder must refuse it.
      final bytes = [...landscapeHeicBytes().sublist(0, 32), ...List.filled(500, 7)];
      final result = await const ImageValidationService().validate(
        write('corrupt.heic', bytes),
        source: PhotoSource.gallery,
      );
      expect(result.error, ImageValidationError.conversionFailed);
      expect(result.error!.message, contains("couldn't convert"));
    });
  });

  testWidgets('the converter throws ImageConversionException on bad input',
      (tester) async {
    await tester.runAsync(() async {
      await expectLater(
        const PluginHeicConverter().convertToJpeg('${dir.path}/missing.heic'),
        throwsA(isA<ImageConversionException>()),
      );
    });
  });
}
