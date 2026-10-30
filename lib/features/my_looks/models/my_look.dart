import 'package:flutter/material.dart';

class MyLook {
  final String id;
  final String title;
  final String description;
  final String tag;
  final String occasion;
  final List<Color> colors;
  final IconData icon;
  final DateTime createdAt;

  const MyLook({
    required this.id,
    required this.title,
    required this.description,
    required this.tag,
    required this.occasion,
    required this.colors,
    required this.icon,
    required this.createdAt,
  });
}
