
import 'package:flutter/material.dart';

import '../models/saved_look.dart';

class MockSavedLooksService {
  static final List<SavedLook> _userSavedLooks = [
    const SavedLook(
      id: 'look-1',
      title: 'Soft Glam',
      occasion: 'Party',
      description: 'A soft glam look with warm tones and a subtle glow.',
      savedLabel: 'Saved 2 days ago',
      previewColor: Color(0xFFF3DDE2),
      previewIcon: Icons.auto_awesome,
    ),
    const SavedLook(
      id: 'look-2',
      title: 'Everyday Glow',
      occasion: 'Everyday',
      description: 'A fresh, natural look for your everyday routine.',
      savedLabel: 'Saved 3 days ago',
      previewColor: Color(0xFFEBD8C8),
      previewIcon: Icons.wb_sunny_outlined,
    ),
    const SavedLook(
      id: 'look-3',
      title: 'Natural Rose',
      occasion: 'Natural',
      description: 'A delicate rose-inspired look with soft pink tones.',
      savedLabel: 'Saved 1 week ago',
      previewColor: Color(0xFFF0C9D1),
      previewIcon: Icons.spa_outlined,
    ),
    const SavedLook(
      id: 'look-4',
      title: 'Bridal Elegance',
      occasion: 'Bridal',
      description: 'An elegant makeup inspiration for a special occasion.',
      savedLabel: 'Saved 2 weeks ago',
      previewColor: Color(0xFFE5D5E9),
      previewIcon: Icons.favorite_border,
    ),
  ];

  // Notifies all pages whenever saved looks change.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void _notifyChanges() {
    changes.value++;
  }

  static bool isSaved(String title, String occasion) {
    return _userSavedLooks.any(
      (look) => look.title == title && look.occasion == occasion,
    );
  }

  static Future<void> saveLook({
    required String title,
    required String occasion,
    required String description,
    required Color previewColor,
    required IconData previewIcon,
  }) async {
    if (isSaved(title, occasion)) return;

    _userSavedLooks.insert(
      0,
      SavedLook(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        occasion: occasion,
        description: description,
        savedLabel: 'Saved just now',
        previewColor: previewColor,
        previewIcon: previewIcon,
      ),
    );

    _notifyChanges();
  }

  static Future<void> toggleSaveLook({
    required String title,
    required String occasion,
    required String description,
    required Color previewColor,
    required IconData previewIcon,
  }) async {
    final existingIndex = _userSavedLooks.indexWhere(
      (look) => look.title == title && look.occasion == occasion,
    );

    if (existingIndex != -1) {
      _userSavedLooks.removeAt(existingIndex);
      _notifyChanges();
      return;
    }

    await saveLook(
      title: title,
      occasion: occasion,
      description: description,
      previewColor: previewColor,
      previewIcon: previewIcon,
    );
  }

  Future<List<SavedLook>> fetchSavedLooks() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List<SavedLook>.from(_userSavedLooks);
  }

  static void removeLook(SavedLook look) {
    _userSavedLooks.removeWhere((item) => item.id == look.id);
    _notifyChanges();
  }

  static void restoreLook(SavedLook look, int index) {
    final restoreIndex =
        index > _userSavedLooks.length ? _userSavedLooks.length : index;

    _userSavedLooks.insert(restoreIndex, look);
    _notifyChanges();
  }
}
