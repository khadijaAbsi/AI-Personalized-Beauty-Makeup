import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Soft blush card with a short privacy note. Informational only.
class PrivacyInfoCard extends StatelessWidget {
  const PrivacyInfoCard({
    super.key,
    this.title = 'Your privacy',
    this.message =
        'Your photo is used only for this analysis. You can delete it anytime in Settings and Privacy.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textLabel),
          ),
        ],
      ),
    );
  }
}
