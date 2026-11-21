import 'dart:async';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'temp_file_cleaner.dart';

/// Thrown when a HEIC/HEIF file can't be turned into a JPEG.
class ImageConversionException implements Exception {
  const ImageConversionException([this.cause]);

  final Object? cause;

  @override
  String toString() => 'ImageConversionException($cause)';
}

/// Turns a HEIC/HEIF file into a JPEG file.
///
/// Implementations must return the path of a NEW file in the app's temp
/// directory (the source is never modified), with the photo's orientation
/// already applied to the pixels and no resizing. Throw
/// [ImageConversionException] on failure.
abstract interface class HeicConverter {
  Future<String> convertToJpeg(String sourcePath);
}

/// Converts with the platform's own image decoder through
/// `flutter_image_compress`:
/// - Android: `BitmapFactory`/`ImageDecoder` decode HEIC/HEIF natively
///   (Android 9 / API 28 and newer), then the bitmap is re-encoded as JPEG.
/// - iOS: ImageIO decodes HEIC natively.
///
/// No storage permission is needed: the file is already in the app's cache
/// (the system Photo Picker copied it there).
class PluginHeicConverter implements HeicConverter {
  const PluginHeicConverter({this.quality = 95});

  /// JPEG quality, 0-100. 95 keeps the result visually identical to the
  /// source while staying well under the size limit for normal phone photos.
  final int quality;

  /// The plugin only scales an image DOWN when it is larger than
  /// minWidth/minHeight (its defaults are 1920 x 1080). A huge value turns
  /// that off, so the JPEG keeps the original resolution.
  static const int _noDownscale = 100000;

  @override
  Future<String> convertToJpeg(String sourcePath) async {
    final targetPath =
        '${Directory.systemTemp.path}/glowai_portrait_'
        '${DateTime.now().microsecondsSinceEpoch}.jpg';

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        format: CompressFormat.jpeg,
        quality: quality,
        minWidth: _noDownscale,
        minHeight: _noDownscale,
        // Rotate the pixels to match the photo's orientation, and don't copy
        // the orientation tag over, so it can't be applied twice later.
        autoCorrectionAngle: true,
        keepExif: false,
      );
      if (result == null) {
        throw const ImageConversionException('The decoder returned no file.');
      }
      return result.path;
    } on ImageConversionException {
      unawaited(deleteTempFileQuietly(targetPath));
      rethrow;
    } catch (error) {
      unawaited(deleteTempFileQuietly(targetPath));
      throw ImageConversionException(error);
    }
  }
}
