import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'avatar_illustration.dart';

/// Avatar illustration with a plum progress ring around it.
///
/// [progress] (0.0 to 1.0) is the source of truth. The ring eases toward it,
/// which only smooths the visuals between events.
class AnalysisAvatar extends StatelessWidget {
  const AnalysisAvatar({super.key, required this.progress, this.size = 200});

  final double progress;
  final double size;

  static const double _ringWidth = 8;
  static const Duration _easing = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.all(_ringWidth + size * 0.05),
              child: const AvatarIllustration(),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress.clamp(0.0, 1.0).toDouble()),
              duration: _easing,
              curve: Curves.easeOut,
              builder: (context, value, _) => CustomPaint(
                painter: _RingPainter(progress: value, strokeWidth: _ringWidth),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - strokeWidth) / 2,
    );

    final track = Paint()
      ..color = AppColors.blush
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    // Starts at 12 o'clock and runs clockwise.
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth;
}
