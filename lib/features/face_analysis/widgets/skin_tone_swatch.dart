import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Round swatch showing the estimated skin tone color.
class SkinToneSwatch extends StatelessWidget {
  const SkinToneSwatch({super.key, required this.color, this.size = 60});

  /// The inner circle carries this key so tests can read its color.
  static const Key colorKey = Key('skin-tone-swatch');

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Estimated skin tone color',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: DecoratedBox(
          key: colorKey,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
