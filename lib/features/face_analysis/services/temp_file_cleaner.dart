import 'dart:io';

/// Best-effort delete of a temporary photo (camera capture or picker copy).
/// Only touches files inside the app's temp/cache directory, so a user's
/// original gallery photo is never deleted.
Future<void> deleteTempFileQuietly(String path) async {
  try {
    if (!path.startsWith(Directory.systemTemp.path)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {
    return;
  }
}
