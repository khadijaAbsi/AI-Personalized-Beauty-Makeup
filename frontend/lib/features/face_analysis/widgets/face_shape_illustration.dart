import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Simple outline of the estimated face shape. Draws an oval for "Oval" and
/// for any shape without its own drawing, so it never fails on new values.
class FaceShapeIllustration extends StatelessWidget {
  const FaceShapeIllustration({super.key, required this.faceShape});

  final String? faceShape;

  static const double _height = 62;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: _height,
        height: _height,
        child: CustomPaint(painter: _FaceShapePainter(faceShape)),
      ),
    );
  }
}

class _FaceShapePainter extends CustomPainter {
  const _FaceShapePainter(this.faceShape);

  final String? faceShape;

  static const double _strokeWidth = 2.5;

  // (width, height) as a fraction of the box, and whether corners are squared.
  static (double, double, bool) _proportions(String? shape) {
    switch (shape?.trim().toLowerCase()) {
      case 'round':
        return (0.88, 0.88, false);
      case 'square':
        return (0.84, 0.84, true);
      case 'oblong':
      case 'long':
        return (0.6, 1.0, false);
      default: // oval, and anything unknown
        return (0.74, 1.0, false);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (widthFactor, heightFactor, squared) = _proportions(faceShape);
    final width = size.width * widthFactor - _strokeWidth;
    final height = size.height * heightFactor - _strokeWidth;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: height,
    );

    final radius = squared
        ? Radius.circular(width * 0.28)
        : Radius.elliptical(width / 2, height / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..color = AppColors.accentDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_FaceShapePainter oldDelegate) =>
      oldDelegate.faceShape != faceShape;
}
