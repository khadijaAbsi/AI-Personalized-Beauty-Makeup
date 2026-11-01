import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// White rounded card listing short instructions, each with a check mark.
class PhotoGuidelinesCard extends StatelessWidget {
  const PhotoGuidelinesCard({super.key, required this.guidelines});

  final List<String> guidelines;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < guidelines.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.check, size: 20, color: AppColors.accentDark),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(guidelines[i], style: textStyle)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
