import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/features/face_analysis/models/selected_photo.dart';
import 'package:glowai/features/face_analysis/services/face_validation_service.dart';
import 'package:glowai/features/face_analysis/services/heic_converter.dart';
import 'package:glowai/features/face_analysis/services/image_validation_service.dart';

import 'fixtures/heic_fixtures.dart';
import 'helpers/face_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestImages images;
  const service = ImageValidationService();

  setUp(() => images = TestImages());
  tearDown(() => images.dispose());

  Future<ImageValidationResult> validate(String path,
      {PhotoSource source = PhotoSource.gallery}) {
    return service.validate(path, source: source);
  }

  group('accepted images', () {
    test('PNG', () async {
      final result = await validate(images.png('a.png'));
      expect(result.isValid, isTrue);
      expect(result.photo!.format, PhotoFormat.png);
      expect(result.photo!.width, 600);
      expect(result.photo!.height, 600);
      expect(result.photo!.sizeInBytes, greaterThan(0));
    });

    test('JPEG, and the photo source is preserved', () async {
      final result =
          await validate(images.jpg('a.jpg'), source: PhotoSource.camera);
      expect(result.isValid, isTrue);
      expect(result.photo!.format, PhotoFormat.jpeg);
      expect(result.photo!.source, PhotoSource.camera);
    });

    test('exactly the minimum size (512 x 512)', () async {
      final result = await validate(images.png('min.png', width: 512, height: 512));
      expect(result.isValid, isTrue);
    });

    test('the file name does not matter, only the contents', () async {
      final result = await validate(images.png('photo.txt'));
      expect(result.isValid, isTrue);
      expect(result.photo!.format, PhotoFormat.png);
    });

    test('the original path is kept (file is never copied or modified)', () async {
      final path = images.png('keep.png');
      final result = await validate(path);
      expect(result.photo!.path, path);
    });
  });

  group('HEIC / HEIF', () {
    ImageValidationService withConverter(
      FakeHeicConverter converter, {
      int maxFileSizeBytes = PhotoRules.maxFileSizeBytes,
    }) => ImageValidationService(
      heicConverter: converter,
      maxFileSizeBytes: maxFileSizeBytes,
    );

    Future<ImageValidationResult> run(
      FakeHeicConverter converter,
      String path, {
      int maxFileSizeBytes = PhotoRules.maxFileSizeBytes,
    }) => withConverter(converter, maxFileSizeBytes: maxFileSizeBytes)
        .validate(path, source: PhotoSource.gallery);

    test('the fixtures are real HEIC files, not renamed JPEGs', () {
      for (final bytes in [landscapeHeicBytes(), smallHeicBytes()]) {
        expect(String.fromCharCodes(bytes, 4, 12), 'ftypheic');
        expect(bytes.sublist(0, 3), isNot([0xFF, 0xD8, 0xFF]));
      }
    });

    test('a real HEIC is converted: the result is a new, checked JPEG', () async {
      final converter = FakeHeicConverter(width: 800, height: 600);
      final source = images.heic('IMG_0001.HEIC');
      final before = File(source).readAsBytesSync();

      final result = await run(converter, source);

      expect(result.isValid, isTrue);
      expect(converter.sources, [source]);
      final photo = result.photo!;
      expect(photo.convertedFromHeif, isTrue);
      expect(photo.format, PhotoFormat.jpeg);
      expect(photo.path, converter.outputs.single);
      expect(photo.path, isNot(source));
      expect(photo.width, 800);
      expect(photo.height, 600);
      expect(photo.sizeInBytes, File(photo.path).lengthSync());
      expect(File(photo.path).readAsBytesSync().sublist(0, 3),
          [0xFF, 0xD8, 0xFF]);
      // The source copy is not modified by the service.
      expect(File(source).readAsBytesSync(), before);
    });

    test('portrait output keeps its aspect ratio', () async {
      final converter = FakeHeicConverter(width: 600, height: 900);
      final result = await run(converter, images.heic('portrait.heic'));
      expect(result.photo!.width, 600);
      expect(result.photo!.height, 900);
    });

    test('.heif, upper-case and misnamed files are all detected by content',
        () async {
      for (final name in ['a.heif', 'B.HEIF', 'c.HEIC', 'photo.jpg', 'noext']) {
        final converter = FakeHeicConverter();
        final result = await run(converter, images.heic(name));
        expect(result.isValid, isTrue, reason: name);
        expect(converter.sources, hasLength(1), reason: name);
        expect(result.photo!.convertedFromHeif, isTrue, reason: name);
      }
    });

    test('brands: heic/heix/hevc and generic mif1/msf1 are HEIF', () async {
      for (final brands in <List<Object>>[
        ['heix'],
        ['hevc'],
        ['mif1', 'heic'],
        ['mif1', 'mif1'],
        ['msf1', 'hevc'],
      ]) {
        final converter = FakeHeicConverter();
        final path = images.ftypOnly(
          '${brands.join('_')}.heif',
          brands.first as String,
          [brands.last as String],
        );
        final result = await run(converter, path);
        expect(result.isValid, isTrue, reason: '$brands');
        expect(converter.sources, hasLength(1), reason: '$brands');
      }
    });

    test('AVIF and other ISO files (e.g. MP4) are not HEIC', () async {
      final converter = FakeHeicConverter();
      for (final path in [
        images.ftypOnly('a.avif', 'avif', ['mif1', 'miaf']),
        images.ftypOnly('b.avif', 'mif1', ['avif']),
        images.ftypOnly('v.heic', 'mp42', ['isom']),
      ]) {
        final result = await run(converter, path);
        expect(result.error, ImageValidationError.unsupportedFormat);
      }
      expect(converter.sources, isEmpty);
    });

    test('a JPEG or PNG named .heic is validated as what it really is',
        () async {
      final converter = FakeHeicConverter();
      final jpg = images.jpg('really_a_jpeg.heic');
      final png = images.png('really_a_png.HEIF');

      final jpgResult = await run(converter, jpg);
      final pngResult = await run(converter, png);

      expect(jpgResult.photo!.path, jpg);
      expect(jpgResult.photo!.format, PhotoFormat.jpeg);
      expect(jpgResult.photo!.convertedFromHeif, isFalse);
      expect(pngResult.photo!.path, png);
      expect(pngResult.photo!.format, PhotoFormat.png);
      expect(converter.sources, isEmpty);
    });

    test('JPEG and PNG are never sent through the converter', () async {
      final converter = FakeHeicConverter();
      await run(converter, images.jpg('a.jpg'));
      await run(converter, images.png('a.png'));
      expect(converter.sources, isEmpty);
    });

    test('rules run on the converted image: exactly 512 x 512 passes',
        () async {
      final result = await run(
        FakeHeicConverter(width: 512, height: 512),
        images.heic('min.heic'),
      );
      expect(result.isValid, isTrue);
    });

    test('too small after conversion; the converted file is removed',
        () async {
      final converter = FakeHeicConverter(width: 300, height: 300);
      final result = await run(converter, images.heic('small.heic'));

      expect(result.error, ImageValidationError.tooSmall);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(File(converter.outputs.single).existsSync(), isFalse);
    });

    test('size limit applies to the converted JPEG', () async {
      final converter = FakeHeicConverter();
      final result = await run(
        converter,
        images.heic('big_after.heic'),
        maxFileSizeBytes: 100,
      );
      expect(result.error, ImageValidationError.tooLarge);
      expect(converter.sources, hasLength(1));
    });

    test('conversion error: friendly message, nothing returned', () async {
      final result = await run(
        FakeHeicConverter(error: const ImageConversionException('boom')),
        images.heic('bad.heic'),
      );
      expect(result.isValid, isFalse);
      expect(result.error, ImageValidationError.conversionFailed);
      expect(result.error!.message, contains("couldn't convert"));
    });

    test('any converter failure (even an unexpected one) is handled', () async {
      final result = await run(
        FakeHeicConverter(error: StateError('platform exploded')),
        images.heic('bad2.heic'),
      );
      expect(result.error, ImageValidationError.conversionFailed);
    });

    test('converter output that is not decodable counts as a failure',
        () async {
      final converter = FakeHeicConverter(
        outputBytes: [0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(300, 7)],
      );
      final result = await run(converter, images.heic('garbage_out.heic'));
      expect(result.error, ImageValidationError.conversionFailed);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(File(converter.outputs.single).existsSync(), isFalse);
    });

    test('converter output that is not a JPEG is not trusted', () async {
      // A valid PNG: it decodes, but "converted to JPEG" must really be one.
      final png = File(images.png('out.png')).readAsBytesSync();
      final result = await run(
        FakeHeicConverter(outputBytes: png),
        images.heic('wrong_out.heic'),
      );
      expect(result.error, ImageValidationError.conversionFailed);
    });

    test('empty converter output is a failure', () async {
      final result = await run(
        FakeHeicConverter(outputBytes: const []),
        images.heic('empty_out.heic'),
      );
      expect(result.error, ImageValidationError.conversionFailed);
    });

    test('a corrupted HEIC (valid header, garbage body) is rejected', () async {
      // Here the converter, like the real decoder, refuses the data.
      final result = await run(
        FakeHeicConverter(error: const ImageConversionException('decode')),
        images.corruptedHeic('corrupt.heic'),
      );
      expect(result.error, ImageValidationError.conversionFailed);
    });

    test('an empty .heic file is unreadable and never converted', () async {
      final converter = FakeHeicConverter();
      final result = await run(converter, images.empty('empty.heic'));
      expect(result.error, ImageValidationError.unreadable);
      expect(converter.sources, isEmpty);
    });

    test('a missing .heic file is a file access error', () async {
      final result = await run(FakeHeicConverter(), images.missing('x.heic'));
      expect(result.error, ImageValidationError.fileAccess);
    });

    test('without the platform decoder, conversion fails cleanly', () async {
      // `flutter test` has no Android/iOS plugin: the default converter must
      // fail with the friendly error instead of crashing.
      final result = await validate(images.heic('no_plugin.heic'));
      expect(result.error, ImageValidationError.conversionFailed);
    });
  });

  group('rejected images', () {
    test('unsupported format: text file named .jpg', () async {
      final result = await validate(images.notAnImage('fake.jpg'));
      expect(result.error, ImageValidationError.unsupportedFormat);
      expect(result.error!.message, 'Please choose a JPG, PNG or HEIC image.');
    });

    test('too large (limit is configurable)', () async {
      const smallLimit = ImageValidationService(maxFileSizeBytes: 100);
      final result =
          await smallLimit.validate(images.png('big.png'), source: PhotoSource.gallery);
      expect(result.error, ImageValidationError.tooLarge);
      expect(result.error!.message, contains('too large'));
      expect(result.error!.message, contains('${PhotoRules.maxFileSizeMb} MB'));
    });

    test('default size limit is 10 MB', () {
      expect(PhotoRules.maxFileSizeBytes, 10 * 1024 * 1024);
    });

    test('too small: below 512 px in either direction', () async {
      final small = await validate(images.png('small.png', width: 300, height: 300));
      expect(small.error, ImageValidationError.tooSmall);
      expect(small.error!.message, contains('too small'));

      final narrow = await validate(images.jpg('narrow.jpg', width: 511, height: 800));
      expect(narrow.error, ImageValidationError.tooSmall);
    });

    test('corrupted PNG and JPEG', () async {
      final png = await validate(images.corruptedPng('bad.png'));
      expect(png.error, ImageValidationError.unreadable);
      expect(png.error!.message, contains("couldn't open"));

      final jpg = await validate(images.corruptedJpg('bad.jpg'));
      expect(jpg.error, ImageValidationError.unreadable);
    });

    test('empty file is unreadable', () async {
      final result = await validate(images.empty('empty.png'));
      expect(result.error, ImageValidationError.unreadable);
    });

    test('missing file is a file access error', () async {
      final result = await validate(images.missing('nope.png'));
      expect(result.error, ImageValidationError.fileAccess);
    });
  });

  group('face validation service', () {
    test('the placeholder performs no checks and never blocks', () async {
      const photo = SelectedPhoto(
        path: 'x',
        source: PhotoSource.gallery,
        format: PhotoFormat.png,
        width: 600,
        height: 600,
        sizeInBytes: 1,
      );
      final result = await const NotIntegratedFaceValidationService().validate(photo);
      expect(result.status, FaceCheckStatus.notPerformed);
      expect(result.blocksContinue, isFalse);
    });

    test('only a real failure blocks', () {
      expect(const FaceValidationResult.passed().blocksContinue, isFalse);
      expect(
        const FaceValidationResult.failed([FaceIssue.multipleFaces]).blocksContinue,
        isTrue,
      );
    });
  });
}
