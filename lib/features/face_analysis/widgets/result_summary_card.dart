import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// White card with a small label, a large value and an optional picture on
/// the right. If [value] is null the card says the value is unavailable.
class ResultSummaryCard extends StatelessWidget {
  const ResultSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  static const String unavailableText = 'Not available';

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = this.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  if (value != null)
                    Text(value, style: textTheme.headlineMedium)
                  else
                    Text(unavailableText, style: textTheme.titleMedium),
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
