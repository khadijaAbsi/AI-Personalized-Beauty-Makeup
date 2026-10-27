import 'package:flutter/material.dart';

import '../models/saved_look.dart';

class MockSavedLooksService {
  Future<List<SavedLook>> fetchSavedLooks() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const [
      SavedLook(
        id: 'look-1',
        title: 'Soft Glam',
        occasion: 'Party',
        description: 'A soft glam look with warm tones and a subtle glow.',
        savedLabel: 'Saved 2 days ago',
        previewColor: Color(0xFFF3DDE2),
        previewIcon: Icons.auto_awesome,
      ),
      SavedLook(
        id: 'look-2',
        title: 'Everyday Glow',
        occasion: 'Everyday',
        description: 'A fresh, natural look for your everyday routine.',
        savedLabel: 'Saved 3 days ago',
        previewColor: Color(0xFFEBD8C8),
        previewIcon: Icons.wb_sunny_outlined,
      ),
      SavedLook(
        id: 'look-3',
        title: 'Natural Rose',
        occasion: 'Natural',
        description: 'A delicate rose-inspired look with soft pink tones.',
        savedLabel: 'Saved 1 week ago',
        previewColor: Color(0xFFF0C9D1),
        previewIcon: Icons.spa_outlined,
      ),
      SavedLook(
        id: 'look-4',
        title: 'Bridal Elegance',
        occasion: 'Bridal',
        description: 'An elegant makeup inspiration for a special occasion.',
        savedLabel: 'Saved 2 weeks ago',
        previewColor: Color(0xFFE5D5E9),
        previewIcon: Icons.favorite_border,
      ),
    ];
  }
}
