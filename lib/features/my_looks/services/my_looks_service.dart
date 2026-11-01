import 'package:flutter/material.dart';

import '../models/my_look.dart';

class MyLooksService {
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static final List<MyLook> _myLooks = [];

  static List<MyLook> get myLooks => List.unmodifiable(_myLooks);

  static bool isSaved(String title, String occasion) {
    return _myLooks.any(
      (look) => look.title == title && look.occasion == occasion,
    );
  }

  static void saveLook({
    required String title,
    required String description,
    required String tag,
    required String occasion,
    required List<Color> colors,
    required IconData icon,
  }) {
    if (isSaved(title, occasion)) return;

    _myLooks.insert(
      0,
      MyLook(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        description: description,
        tag: tag,
        occasion: occasion,
        colors: List<Color>.unmodifiable(colors),
        icon: icon,
        createdAt: DateTime.now(),
      ),
    );

    changes.value++;
  }

  static void removeLook(MyLook look) {
    _myLooks.removeWhere((item) => item.id == look.id);
    changes.value++;
  }

  static void restoreLook(MyLook look) {
    if (_myLooks.any((item) => item.id == look.id)) return;

    _myLooks.insert(0, look);
    changes.value++;
  }
}
