import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../face_analysis/models/face_analysis_result.dart';
import '../../face_analysis/widgets/skin_tone_swatch.dart';

/// "My face analysis": the user's latest analysis (the existing
/// [FaceAnalysisResult] model), or an invitation to analyse if there is none.
/// Sample data is clearly labelled.
class ProfileAnalysisCard extends StatelessWidget {
  const ProfileAnalysisCard({
    super.key,
    required this.analysis,
    required this.onAnalyze,
  });

  final FaceAnalysisResult? analysis;
  final VoidCallback onAnalyze;

  static const String unavailableText = 'Not available';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final analysis = this.analysis;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My face analysis',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (analysis == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              "You haven't analyzed your face yet.",
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: onAnalyze, child: const Text('Analyze my face')),
          ] else ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              analysis.isMock
                  ? 'Sample data, estimates only'
                  : 'Latest analysis, estimates only',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _Row(label: 'Face shape', value: analysis.faceShape),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _Row(
              label: 'Skin tone',
              value: analysis.skinTone,
              swatchArgb: analysis.skinToneArgb,
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _Row(label: 'Undertone', value: analysis.skinUndertone),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.swatchArgb});

  final String label;
  final String? value;
  final int? swatchArgb;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = this.value;
    final swatchArgb = this.swatchArgb;

    return Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
        if (swatchArgb != null) ...[
          SkinToneSwatch(color: Color(swatchArgb), size: 26),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            value ?? ProfileAnalysisCard.unavailableText,
            textAlign: TextAlign.end,
            style: value != null
                ? textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)
                : textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
