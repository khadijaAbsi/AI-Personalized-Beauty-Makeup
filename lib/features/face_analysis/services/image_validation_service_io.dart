import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../models/selected_photo.dart';
import 'heic_converter.dart';
import 'temp_file_cleaner.dart';

/// Photo rules. Change them here.
abstract final class PhotoRules {
  static const int maxFileSizeMb = 10;
  static const int maxFileSizeBytes = maxFileSizeMb * 1024 * 1024;
  static const int minDimension = 512;

  /// Upper limit for a HEIC/HEIF file BEFORE conversion, only so we never try
  /// to decode something enormous. The real size rule ([maxFileSizeBytes])
  /// is applied to the converted JPEG.
  static const int maxHeifSourceBytes = 50 * 1024 * 1024;
}

enum ImageValidationError {
  unsupportedFormat,
  tooLarge,
  tooSmall,
  unreadable,
  conversionFailed,
  fileAccess,
}

extension ImageValidationErrorMessage on ImageValidationError {
  /// User-friendly text for each failure.
  String get message {
    switch (this) {
      case ImageValidationError.unsupportedFormat:
        return 'Please choose a JPG, PNG or HEIC image.';
      case ImageValidationError.tooLarge:
        return 'Your photo is too large. Please choose an image under '
            '${PhotoRules.maxFileSizeMb} MB.';
      case ImageValidationError.tooSmall:
        return 'This image is too small for accurate analysis. Please choose '
            'one that is at least ${PhotoRules.minDimension} \u00d7 '
            '${PhotoRules.minDimension} pixels.';
      case ImageValidationError.unreadable:
        return "We couldn't open this photo. Please try another image.";
      case ImageValidationError.conversionFailed:
        return "We couldn't convert this photo. Please try a different photo "
            'or take a new one.';
      case ImageValidationError.fileAccess:
        return "We couldn't access this photo. Please try again or choose "
            'another image.';
    }
  }
}

class ImageValidationResult {
  const ImageValidationResult.valid(this.photo) : error = null;
  const ImageValidationResult.invalid(this.error) : photo = null;

  final SelectedPhoto? photo;
  final ImageValidationError? error;

  bool get isValid => photo != null;
}

/// What the file's first bytes say it is (never the file name).
enum _Signature { jpeg, png, heif }

/// Validates a photo file using its real contents, not its file name:
/// size, then format (file signature), then a full decode (which also catches
/// corrupted files), then resolution.
///
/// HEIC/HEIF files are converted to JPEG first (never just renamed), and the
/// rules then run on the converted JPEG, so the file handed on is always a
/// decoded, checked JPEG or PNG.
class ImageValidationService {
  const ImageValidationService({
    this.maxFileSizeBytes = PhotoRules.maxFileSizeBytes,
    this.minDimension = PhotoRules.minDimension,
    this.heicConverter = const PluginHeicConverter(),
  });

  final int maxFileSizeBytes;
  final int minDimension;
  final HeicConverter heicConverter;

  /// On success for a HEIC/HEIF file, [SelectedPhoto.path] is the NEW JPEG
  /// (in the temp directory) and the source file is left untouched.
  Future<ImageValidationResult> validate(
    String path, {
    required PhotoSource source,
  }) async {
    final Uint8List header;
    try {
      header = await _readHeader(File(path));
    } on FileSystemException {
      return const ImageValidationResult.invalid(ImageValidationError.fileAccess);
    }

    if (_sniff(header) == _Signature.heif) {
      return _convertAndValidate(path, source: source);
    }
    return _validateFile(path, source: source, converted: false);
  }

  Future<ImageValidationResult> _convertAndValidate(
    String path, {
    required PhotoSource source,
  }) async {
    final int sourceLength;
    try {
      sourceLength = await File(path).length();
    } on FileSystemException {
      return const ImageValidationResult.invalid(ImageValidationError.fileAccess);
    }
    if (sourceLength > PhotoRules.maxHeifSourceBytes) {
      return const ImageValidationResult.invalid(ImageValidationError.tooLarge);
    }

    final String jpegPath;
    try {
      jpegPath = await heicConverter.convertToJpeg(path);
    } catch (_) {
      // Includes ImageConversionException and a missing platform plugin.
      return const ImageValidationResult.invalid(
        ImageValidationError.conversionFailed,
      );
    }

    final result = await _validateFile(jpegPath, source: source, converted: true);
    if (!result.isValid) {
      // Don't leave a rejected conversion behind.
      unawaited(deleteTempFileQuietly(jpegPath));
    }
    return result;
  }

  /// The checks shared by every photo. With [converted] set, the file is a
  /// conversion result, so it must really be a JPEG, and a decode failure
  /// counts as a failed conversion.
  Future<ImageValidationResult> _validateFile(
    String path, {
    required PhotoSource source,
    required bool converted,
  }) async {
    final file = File(path);
    final unreadable = converted
        ? ImageValidationError.conversionFailed
        : ImageValidationError.unreadable;

    final int length;
    try {
      length = await file.length();
    } on FileSystemException {
      return const ImageValidationResult.invalid(ImageValidationError.fileAccess);
    }
    if (length == 0) return ImageValidationResult.invalid(unreadable);
    if (length > maxFileSizeBytes) {
      return const ImageValidationResult.invalid(ImageValidationError.tooLarge);
    }

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on FileSystemException {
      return const ImageValidationResult.invalid(ImageValidationError.fileAccess);
    }

    final signature = _sniff(bytes);
    final PhotoFormat format;
    if (converted) {
      if (signature != _Signature.jpeg) {
        return const ImageValidationResult.invalid(
          ImageValidationError.conversionFailed,
        );
      }
      format = PhotoFormat.jpeg;
    } else {
      switch (signature) {
        case _Signature.jpeg:
          format = PhotoFormat.jpeg;
        case _Signature.png:
          format = PhotoFormat.png;
        case _Signature.heif:
        case null:
          return const ImageValidationResult.invalid(
            ImageValidationError.unsupportedFormat,
          );
      }
    }

    final size = await _decodeSize(bytes);
    if (size == null) return ImageValidationResult.invalid(unreadable);

    final width = size.width.toInt();
    final height = size.height.toInt();
    if (width < minDimension || height < minDimension) {
      return const ImageValidationResult.invalid(ImageValidationError.tooSmall);
    }

    return ImageValidationResult.valid(
      SelectedPhoto(
        path: path,
        source: source,
        format: format,
        width: width,
        height: height,
        sizeInBytes: length,
        convertedFromHeif: converted,
      ),
    );
  }

  /// The first bytes are enough to recognise every supported format.
  static Future<Uint8List> _readHeader(File file) async {
    final raf = await file.open();
    try {
      return await raf.read(512);
    } finally {
      await raf.close();
    }
  }

  static const _heicBrands = {'heic', 'heix', 'heim', 'heis', 'hevc', 'hevx'};
  static const _genericHeifBrands = {'mif1', 'msf1'};
  static const _avifBrands = {'avif', 'avis'};

  /// JPEG starts with FF D8 FF. PNG starts with 89 'PNG' 0D 0A 1A 0A.
  /// HEIC/HEIF is an ISO base media file: a size, then 'ftyp', a major brand
  /// and compatible brands. AVIF uses the same container, so it is excluded.
  static _Signature? _sniff(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return _Signature.jpeg;
    }
    const pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (bytes.length >= pngSignature.length) {
      var matches = true;
      for (var i = 0; i < pngSignature.length; i++) {
        if (bytes[i] != pngSignature[i]) {
          matches = false;
          break;
        }
      }
      if (matches) return _Signature.png;
    }
    return _isHeif(bytes) ? _Signature.heif : null;
  }

  static bool _isHeif(Uint8List bytes) {
    if (bytes.length < 16) return false;
    if (String.fromCharCodes(bytes, 4, 8) != 'ftyp') return false;

    final boxSize =
        (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    final end = (boxSize >= 16 && boxSize <= bytes.length)
        ? boxSize
        : bytes.length;

    final brands = <String>{String.fromCharCodes(bytes, 8, 12)};
    // Bytes 12-16 are the minor version; compatible brands follow.
    for (var i = 16; i + 4 <= end; i += 4) {
      brands.add(String.fromCharCodes(bytes, i, i + 4));
    }

    if (brands.any(_avifBrands.contains)) return false;
    return brands.any(_heicBrands.contains) ||
        brands.any(_genericHeifBrands.contains);
  }

  /// Fully decodes the image (so corrupted data fails here) and returns its
  /// pixel size, or null if it can't be decoded.
  static Future<ui.Size?> _decodeSize(Uint8List bytes) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
      return ui.Size(image.width.toDouble(), image.height.toDouble());
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
}
