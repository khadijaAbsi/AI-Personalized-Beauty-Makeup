import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Decorative "demo guide": a soft gradient panel with a dashed oval showing
/// where the face should sit. It is not a camera preview.
class FacePositionGuide extends StatelessWidget {
  const FacePositionGuide({super.key});

  // Semi-transparent white used for the dashed oval and the label pill.
  static const Color _overlayWhite = Color(0xE6FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Demo guide. Position your face inside the dashed oval.',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: AspectRatio(
            aspectRatio: 340 / 150,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.blush,
                    AppColors.accent,
                    AppColors.accentDark,
                  ],
                  stops: [0.0, 0.7, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(
                      painter: DashedOvalPainter(color: _overlayWhite),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md - AppSpacing.xs,
                    bottom: AppSpacing.md - AppSpacing.xs,
                    child: const _DemoLabel(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoLabel extends StatelessWidget {
  const _DemoLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: FacePositionGuide._overlayWhite,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Demo guide',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }
}

/// Draws a dashed oval centered in the available space.
/// The oval is 80% of the height and about 77% as wide as it is tall.
class DashedOvalPainter extends CustomPainter {
  const DashedOvalPainter({required this.color});

  final Color color;

  static const double _dashLength = 6;
  static const double _gapLength = 5;
  static const double _strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final ovalHeight = size.height * 0.8;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: ovalHeight * 0.77,
      height: ovalHeight,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path()..addOval(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + _dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(DashedOvalPainter oldDelegate) =>
      oldDelegate.color != color;
}
