import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Soft card for errors and notices, with an optional action
/// (e.g. "Open Settings"). Announced to screen readers when it appears.
class PortraitMessageCard extends StatelessWidget {
  const PortraitMessageCard({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = true,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.blush,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: isError ? theme.colorScheme.error : AppColors.accentDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            if (actionLabel != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ),
          ],
        ),
      ),
    );
  }
}
