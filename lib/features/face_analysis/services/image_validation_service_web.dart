import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';

import '../models/selected_photo.dart';
import 'heic_converter.dart';

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

/// Web adapter: uses browser-compatible XFile bytes; never uses dart:io File.
/// HEIC is rejected on Web; original mobile conversion remains unchanged.
class ImageValidationService {
  const ImageValidationService({
    this.maxFileSizeBytes = PhotoRules.maxFileSizeBytes,
    this.minDimension = PhotoRules.minDimension,
    this.heicConverter = const PluginHeicConverter(),
  });
  final int maxFileSizeBytes;
  final int minDimension;
  final HeicConverter heicConverter;

  Future<ImageValidationResult> validate(
    String path, {
    required PhotoSource source,
  }) async {
    final Uint8List bytes;
    try {
      bytes = await XFile(path).readAsBytes();
    } catch (_) {
      return const ImageValidationResult.invalid(
        ImageValidationError.fileAccess,
      );
    }
    if (bytes.isEmpty) {
      return const ImageValidationResult.invalid(
        ImageValidationError.unreadable,
      );
    }
    if (bytes.length > maxFileSizeBytes) {
      return const ImageValidationResult.invalid(ImageValidationError.tooLarge);
    }
    final PhotoFormat format;
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      format = PhotoFormat.jpeg;
    } else if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      format = PhotoFormat.png;
    } else {
      return const ImageValidationResult.invalid(
        ImageValidationError.unsupportedFormat,
      );
    }
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
      if (image.width < minDimension || image.height < minDimension) {
        return const ImageValidationResult.invalid(
          ImageValidationError.tooSmall,
        );
      }
      return ImageValidationResult.valid(
        SelectedPhoto(
          path: path,
          source: source,
          format: format,
          width: image.width,
          height: image.height,
          sizeInBytes: bytes.length,
        ),
      );
    } catch (_) {
      return const ImageValidationResult.invalid(
        ImageValidationError.unreadable,
      );
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
}
