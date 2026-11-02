enum PhotoSource { camera, gallery }

enum PhotoFormat { jpeg, png }

/// A photo that passed file validation. The file at [path] is always a JPEG
/// or PNG that decoded successfully, never cropped or resized, so it can be
/// sent to the backend later. JPEG/PNG picks are the original file untouched;
/// a HEIC/HEIF pick is a converted JPEG ([convertedFromHeif]).
class SelectedPhoto {
  const SelectedPhoto({
    required this.path,
    required this.source,
    required this.format,
    required this.width,
    required this.height,
    required this.sizeInBytes,
    this.convertedFromHeif = false,
  });

  final String path;
  final PhotoSource source;
  final PhotoFormat format;
  final int width;
  final int height;
  final int sizeInBytes;

  /// True when [path] is a JPEG converted from a HEIC/HEIF original.
  final bool convertedFromHeif;

  double get sizeInMegabytes => sizeInBytes / (1024 * 1024);
}
