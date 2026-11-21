import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// The large rounded area on Add Your Portrait.
/// - No photo: dashed border, upload icon and instructions (tap to pick).
///   Keeps the design proportions but grows taller if text needs the room.
/// - Photo: shows it whole (never cropped) inside the rounded container.
/// - [isLoading]: dims the area and shows a spinner while validating.
class PhotoUploadArea extends StatelessWidget {
  const PhotoUploadArea({
    super.key,
    this.photoPath,
    this.isLoading = false,
    this.onTap,
  });

  final String? photoPath;
  final bool isLoading;

  /// Only used while there is no photo. Null disables the tap.
  final VoidCallback? onTap;

  static const double _radius = 28;
  static const double _aspectRatio = 342 / 262;
  static const Color _loadingScrim = Color(0xB3FFFFFF);

  @override
  Widget build(BuildContext context) {
    final path = photoPath;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // The design height at this width. It is a minimum for the empty
        // state, which grows if larger text needs more room, and the exact
        // height for a photo.
        final designHeight = width / _aspectRatio;

        return Stack(
          children: [
            if (path == null)
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: width,
                  minHeight: designHeight,
                ),
                child: _EmptyState(onTap: isLoading ? null : onTap),
              )
            else
              SizedBox(
                width: width,
                height: designHeight,
                child: _PhotoPreview(path: path),
              ),
            if (isLoading)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _loadingScrim,
                    borderRadius: BorderRadius.all(Radius.circular(_radius)),
                  ),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: onTap != null,
      child: CustomPaint(
        painter: const _DashedBorderPainter(
          color: AppColors.accent,
          radius: PhotoUploadArea._radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(PhotoUploadArea._radius),
            onTap: onTap,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.file_upload_outlined,
                      size: 48,
                      color: AppColors.accentDark,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Upload a front-facing photo',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'JPG, PNG or HEIC, one face only',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Selected photo preview',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(PhotoUploadArea._radius),
          border: Border.all(color: AppColors.border),
        ),
        // BoxFit.contain keeps the photo's proportions: nothing is cropped
        // or stretched. cacheWidth only limits memory used for display; the
        // file itself is untouched.
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          cacheWidth: 1200,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.textHint),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _strokeWidth = 1.5;
  static const double _dashLength = 6;
  static const double _gapLength = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(_strokeWidth / 2);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path()..addRRect(rrect);
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
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
