import 'package:flutter/material.dart';

class SavedLook {
  final String id;
  final String title;
  final String occasion;
  final String description;
  final String savedLabel;
  final Color previewColor;
  final IconData previewIcon;

  const SavedLook({
    required this.id,
    required this.title,
    required this.occasion,
    required this.description,
    required this.savedLabel,
    required this.previewColor,
    required this.previewIcon,
  });
}
