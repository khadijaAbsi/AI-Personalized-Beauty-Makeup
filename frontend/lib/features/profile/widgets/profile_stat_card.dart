import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Tappable blush card with a count and a label ("12 Saved looks").
/// A null [count] (unavailable) shows an en dash.
class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({
    super.key,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.blush,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count?.toString() ?? '\u2013',
                  style: textTheme.headlineMedium?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(label, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
