import 'package:flutter/material.dart';

import '../models/saved_look.dart';
import 'saved_looks_service.dart';

/// Backward-compatibility adapter for older GlowAI screens that still import
/// MockSavedLooksService. All operations now use Supabase; no demo data is seeded.
/// New code should import SavedLooksService directly.
@Deprecated('Use SavedLooksService instead.')
class MockSavedLooksService {
  static ValueNotifier<int> get changes => SavedLooksService.changes;

  static bool isSaved(String title, String occasion) =>
      SavedLooksService.isSaved(title, occasion);

  static Future<void> saveLook({
    required String title,
    required String occasion,
    required String description,
    required Color previewColor,
    required IconData previewIcon,
  }) => SavedLooksService.saveLook(
        title: title,
        occasion: occasion,
        description: description,
        previewColor: previewColor,
        previewIcon: previewIcon,
      );

  static Future<void> toggleSaveLook({
    required String title,
    required String occasion,
    required String description,
    required Color previewColor,
    required IconData previewIcon,
  }) => SavedLooksService.toggleSaveLook(
        title: title,
        occasion: occasion,
        description: description,
        previewColor: previewColor,
        previewIcon: previewIcon,
      );

  Future<List<SavedLook>> fetchSavedLooks() =>
      SavedLooksService().fetchSavedLooks();

  static Future<void> removeLook(SavedLook look) =>
      SavedLooksService.removeLook(look);

  static Future<void> restoreLook(SavedLook look, int index) =>
      SavedLooksService.restoreLook(look, index);
}
