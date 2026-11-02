import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';

/// Centered view for the Profile screen's loading, empty and error states.
class ProfileStateView extends StatelessWidget {
  const ProfileStateView.loading({super.key})
      : icon = null,
        title = 'Loading your profile',
        message = null,
        actionLabel = null,
        onAction = null,
        isLoading = true;

  const ProfileStateView({
    super.key,
    required IconData this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : isLoading = false;

  final IconData? icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = this.message;
    final actionLabel = this.actionLabel;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const CircularProgressIndicator()
              else
                Icon(icon, size: 48, color: AppColors.accentDark),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: isLoading ? textTheme.titleMedium : textTheme.headlineMedium,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(message, textAlign: TextAlign.center, style: textTheme.bodyMedium),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(label: actionLabel, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
