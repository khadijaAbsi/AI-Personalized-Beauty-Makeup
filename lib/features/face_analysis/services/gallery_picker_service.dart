import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class GalleryAccessException implements Exception {
  const GalleryAccessException();
}

/// Opens the system gallery and returns one image file path.
abstract interface class GalleryPicker {
  /// Returns null if the user cancels. Throws [GalleryAccessException] if the
  /// picker can't be opened.
  Future<String?> pickImagePath();
}

/// Uses `image_picker`, which on Android opens the system Photo Picker, so no
/// storage permission is needed. The image is not resized or compressed.
class SystemGalleryPicker implements GalleryPicker {
  SystemGalleryPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pickImagePath() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      return file?.path;
    } on PlatformException {
      throw const GalleryAccessException();
    }
  }
}
