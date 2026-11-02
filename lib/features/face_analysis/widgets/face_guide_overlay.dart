import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Oval face-positioning guide drawn ON TOP of the camera preview.
///
/// It is only a visual aid: it is a separate widget layered over the preview,
/// so it is never part of the captured photo, and it does NOT detect faces.
class FaceGuideOverlay extends StatelessWidget {
  const FaceGuideOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          painter: _FaceGuidePainter(),
        ),
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  const _FaceGuidePainter();

  static const Color _scrim = Color(0x6630272B);
  static const Color _outline = Color(0xE6FFFFFF);
  static const double _dashLength = 8;
  static const double _gapLength = 6;
  static const double _heightToWidth = 1.3;

  @override
  void paint(Canvas canvas, Size size) {
    final ovalWidth = math.min(
      size.width * 0.66,
      size.height * 0.60 / _heightToWidth,
    );
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.46),
      width: ovalWidth,
      height: ovalWidth * _heightToWidth,
    );

    // Dim everything outside the oval.
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(oval),
    );
    canvas.drawPath(scrim, Paint()..color = _scrim);

    // Dashed oval outline.
    final outline = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final metric in (Path()..addOval(oval)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + _dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), outline);
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_FaceGuidePainter oldDelegate) => false;
}
