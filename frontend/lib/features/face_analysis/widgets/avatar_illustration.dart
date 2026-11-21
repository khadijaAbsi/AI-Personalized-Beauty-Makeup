import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Round avatar illustration (soft gradient, simple head and shoulders),
/// drawn with a painter so no image asset is needed. It fills the space it is
/// given, so wrap it in a square `SizedBox`.
class AvatarIllustration extends StatelessWidget {
  const AvatarIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: ClipOval(
        child: CustomPaint(size: Size.infinite, painter: _AvatarPainter()),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter();

  // Illustration-only color (not used elsewhere in the app).
  static const Color _skin = Color(0xFFF2CFC0);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blush, AppColors.accent, AppColors.accentDark],
          stops: [0.0, 0.7, 1.0],
        ).createShader(rect),
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.36),
      size.width * 0.22,
      Paint()..color = _skin,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height),
        width: size.width * 0.78,
        height: size.height * 0.74,
      ),
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) => false;
}
