import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Slim horizontal progress bar. [value] (0.0 to 1.0) is the source of truth;
/// the fill eases toward it to avoid jumps.
class AnalysisProgressBar extends StatelessWidget {
  const AnalysisProgressBar({super.key, required this.value});

  final double value;

  static const double _height = 8;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0).toDouble();

    return Semantics(
      label: 'Analysis progress',
      value: '${(clamped * 100).round()}%',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_height / 2),
          child: SizedBox(
            height: _height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.blush),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: clamped),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, animated, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animated,
                    child: const ColoredBox(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
